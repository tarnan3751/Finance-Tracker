#!/usr/bin/env bash
# Lands a delivered patch series on the main tree: the coordinator's landing step
# (CLAUDE.md, **Agent workflow**). A developer delivers `git format-patch` files on a base
# commit, one commit each, and reports the tree they reproduce. This script applies them
# with `git am`, checks the result against that tree, runs the gate, and leaves the
# commits in place for the owner to push.
#
#   tools/land_series.sh <patch-dir> <base-commit> <tree-hash> [--dry-run]
#
# It refuses a working tree that is not clean, a HEAD that is not the base commit, a
# branch other than main, a patch directory with no NNNN-*.patch files, a patch that does
# not apply, a commit message that tools/check_commits.sh refuses (the gate's own lint: a
# Conventional Commit subject of at most 72 characters, no trailer), and a final tree that
# differs from the reported one. Each refusal after `git am` started resets
# the branch back to the base, so the tree is left as it was found. `--dry-run` applies and
# checks the chain, then resets to the base without running the gate. The gate's report is
# kept in app/build/landing/<tree>.log (gitignored); a gate failure leaves the commits in
# place, prints the tail of the failing step and the `git reset --hard <base>` that undoes
# the landing.
set -uo pipefail

usage() {
  echo "usage: tools/land_series.sh <patch-dir> <base-commit> <tree-hash> [--dry-run]" >&2
  exit 2
}

dry_run=0
positional=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    -*) echo "land_series: unknown option $arg" >&2; usage ;;
    *) positional+=("$arg") ;;
  esac
done
[ "${#positional[@]}" -eq 3 ] || usage
patch_dir="${positional[0]}"
base_arg="${positional[1]}"
expect_tree="${positional[2]}"

# The repository is the one the script is run in, never the script's own location, which
# would land a series meant for a clone on the main tree.
root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "land_series: not in a git repository" >&2; exit 1; }
cd "$root"
tools_dir="$root/tools"

refuse() {
  echo "land_series: $*" >&2
  exit 1
}

branch="$(git rev-parse --abbrev-ref HEAD)"
[ "$branch" = "main" ] || refuse "HEAD is on $branch, not main"
head="$(git rev-parse HEAD)"
base="$(git rev-parse --verify "${base_arg}^{commit}" 2>/dev/null)" || refuse "no such commit $base_arg"
[ "$head" = "$base" ] || refuse "HEAD is ${head:0:10}, not the base ${base:0:10}"
if [ -n "$(git status --porcelain)" ]; then
  git status --short >&2
  refuse "the working tree is not clean"
fi

[ -d "$patch_dir" ] || refuse "no patch directory $patch_dir"
patches=()
while IFS= read -r file; do
  patches+=("$file")
done < <(find "$patch_dir" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.patch' | sort)
[ "${#patches[@]}" -gt 0 ] || refuse "no NNNN-*.patch files in $patch_dir"

echo "repository $root, branch main at ${base:0:10}, ${#patches[@]} patch(es)"

rollback() {
  git am --abort >/dev/null 2>&1 || true
  git reset -q --hard "$base"
  echo "land_series: main reset to the base ${base:0:10}" >&2
}

if ! git am "${patches[@]}"; then
  rollback
  refuse "a patch does not apply (see above)"
fi

# The messages, checked by the same script as the gate's commits step.
if ! "$tools_dir/check_commits.sh" "$base"; then
  rollback
  refuse "the series' commit messages do not pass tools/check_commits.sh (above)"
fi

tree="$(git rev-parse 'HEAD^{tree}')"
case "$tree" in
  "$expect_tree"*) ;;
  *)
    case "$expect_tree" in
      "$tree"*) ;;
      *)
        rollback
        refuse "the chain's final tree $tree differs from the reported tree $expect_tree"
        ;;
    esac
    ;;
esac
echo "final tree ${tree:0:12} matches the reported tree"
git log --reverse --format='%h %s' "$base..HEAD" | nl -w2 -s' '

if [ "$dry_run" -eq 1 ]; then
  git reset -q --hard "$base"
  echo "dry run: main stays at ${base:0:10}"
  exit 0
fi

# The gate's report is kept under app/build/ (gitignored) by the tree it checked.
report_dir="$root/app/build/landing"
mkdir -p "$report_dir"
report="$report_dir/$tree.log"
echo "running the gate (report: ${report#"$root"/})"
if ! "$tools_dir/gates.sh" 2>&1 | tee "$report"; then
  {
    echo
    echo "land_series: the gate failed; the tail of its failing step(s):"
    awk '/^gate [a-z]+ +FAILED/ { failing = 1; print; next } /^gates?[: ]/ { failing = 0 } failing' "$report" | tail -60
    echo "land_series: the full report is $report"
    echo "land_series: the commits are in place, unpushed. To undo the landing:"
    echo "  git reset --hard $base"
  } >&2
  exit 1
fi
new_head="$(git rev-parse HEAD)"
echo "main: ${base:0:10} -> ${new_head:0:10} (${#patches[@]} commits), not pushed"
