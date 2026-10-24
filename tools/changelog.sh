#!/usr/bin/env bash
# Prints a CHANGELOG.md section generated from the Conventional Commit log (CLAUDE.md,
# **Release notes**; PLAN.md section 10): every commit in <range>, grouped by type in a fixed
# order, each as "- scope: Summary (hash)"; commits whose subject is not a Conventional Commit
# go under "Other". The coordinator pastes the output under a "## <tag> — <date>" heading
# with a short paragraph above the groups.
#   tools/changelog.sh <range>        e.g. tools/changelog.sh v0.1.0-phase0..HEAD
# Reads git only; writes nothing.
set -uo pipefail
[ $# -eq 1 ] || { echo "usage: tools/changelog.sh <git-range>" >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)"
git log --reverse --format='%h%x09%s' "$1" | awk -F'\t' '
BEGIN {
  n = split("feat fix perf refactor build ci test docs style chore revert other", order, " ")
  titles["feat"]="Features"; titles["fix"]="Fixes"; titles["perf"]="Performance"
  titles["refactor"]="Refactoring"; titles["build"]="Build"; titles["ci"]="CI"
  titles["test"]="Tests"; titles["docs"]="Documentation"; titles["style"]="Style"
  titles["chore"]="Chores"; titles["revert"]="Reverts"; titles["other"]="Other"
}
{
  hash = $1; subject = $2
  if (match(subject, /^(feat|fix|perf|refactor|build|ci|test|docs|style|chore|revert)(\([^)]*\))?!?: /)) {
    type = subject; sub(/[(!:].*$/, "", type)
    scope = ""
    if (match(subject, /\([^)]*\)/)) { scope = substr(subject, RSTART + 1, RLENGTH - 2) }
    summary = subject; sub(/^[^:]*: /, "", summary)
    line = "- " (scope != "" ? scope ": " : "") summary " (" hash ")"
  } else { type = "other"; line = "- " subject " (" hash ")" }
  lines[type] = lines[type] line "\n"
}
END {
  for (i = 1; i <= n; i++) { t = order[i]; if (lines[t] != "") printf "### %s\n\n%s\n", titles[t], lines[t] }
}'
