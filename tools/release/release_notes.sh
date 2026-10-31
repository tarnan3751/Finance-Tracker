#!/usr/bin/env bash
# Prints the body of a GitHub release (docs/reference/testing-tools.md, **Cutting a
# release**): the CHANGELOG.md section whose heading starts with "## <tag>" (its lines up to
# the next "## " heading, without the heading itself, which the release's title replaces),
# then an Install paragraph and a Verify paragraph naming the signing certificate's SHA-256
# from tools/release/expected_cert_sha256.txt. The changelog commit lands before the tag, so
# a tag with no section, or an empty one, is a mistake: it says which and exits 1.
#   tools/release/release_notes.sh <tag>      e.g. tools/release/release_notes.sh v1.0.0
# Reads files only; writes nothing.
set -uo pipefail
[ $# -eq 1 ] || { echo "usage: tools/release/release_notes.sh <tag>" >&2; exit 2; }
cd "$(dirname "$0")/../.."
tag="$1"

# The heading is "## <tag>" alone or followed by a space ("## v1.0.0 — 2026-11-02"), so
# v1.0.0 never matches the section of v1.0.0-rc.1. Leading and trailing blank lines go.
# The first line printed is "found" or "missing"; the section's lines follow.
section="$(awk -v tag="$tag" '
  /^## / { if (found) exit; if ($0 == "## " tag || index($0, "## " tag " ") == 1) { found = 1; next } }
  found { lines[++n] = $0 }
  END {
    print (found ? "found" : "missing")
    first = 1; while (first <= n && lines[first] ~ /^[[:space:]]*$/) first++
    last = n; while (last >= first && lines[last] ~ /^[[:space:]]*$/) last--
    for (i = first; i <= last; i++) print lines[i]
  }' CHANGELOG.md)"
state="${section%%$'\n'*}"
[ "$state" = "$section" ] && section="" || section="${section#*$'\n'}"
if [ "$state" = missing ]; then
  echo "release_notes: CHANGELOG.md has no section headed \"## $tag\"; generate it with" \
    "tools/changelog.sh, commit it, then tag that commit" >&2
  exit 1
fi
if [ -z "$section" ]; then
  echo "release_notes: the CHANGELOG.md section headed \"## $tag\" is empty; fill it with" \
    "tools/changelog.sh's output and commit it before tagging" >&2
  exit 1
fi
cert="$(tr -d '[:space:]' <tools/release/expected_cert_sha256.txt)"

cat <<NOTES
$section

### Install

The demo APK (\`finance-tracker-$tag-demo-debug.apk\`) runs on seeded data with no server and no
account: install it and open it. The prod APK (\`finance-tracker-$tag-prod-release.apk\`) expects
your own development server; the README says how to run one. Both need Android 8.0 or later.

### Verify

The prod APK is signed with the release key, whose certificate SHA-256 is

\`\`\`
$cert
\`\`\`

which \`apksigner verify --print-certs\` reports for it. Check the downloads against the sums file
with \`sha256sum -c SHA256SUMS.txt\`.
NOTES
