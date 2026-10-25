#!/usr/bin/env bash
# The commit-message lint: checks every commit in <base>..<head> (head defaults to HEAD) for
# the shape the map requires (CLAUDE.md, **Delivery and landing**), so a lane meets a bad
# message at its own gate rather than at landing. tools/gates.sh runs it on the commits beyond
# origin/main and tools/land_series.sh on the series it lands, so the two agree.
#
#   tools/check_commits.sh <base> [<head>]
#
# A subject is `type(scope): Summary` or `type: Summary` (a `!` before the colon allowed):
#   - type: feat, fix, refactor, perf, test, docs, build, ci, chore, style or revert
#   - scope: app, server, models, api, persona, tools, docs, ci, build, a feature folder under
#     app/lib/features/ in <head>'s tree, or sync or map, which the history uses
#   - Summary: sentence case (a capital letter or a digit first), imperative (its first word
#     not a past tense, an -ing form or a third person: "Added", "Adding", "Adds"), and no
#     trailing period
#   - at most 72 characters in all
# and no message carries a trailer: none that `git interpret-trailers --parse` finds, and no
# line anywhere starting Co-Authored-By:, Signed-off-by:, Generated-with:, Reviewed-by:,
# Claude-Session: or Change-Id:. A message line over 100 characters is noted, not refused.
# Prints one line per problem and exits 1 when there is any, else prints a count on its last
# line and exits 0; exits 2 on a usage error. Reads the repository only.
set -uo pipefail

usage() {
  echo "usage: tools/check_commits.sh <base> [<head>]" >&2
  exit 2
}
[ $# -ge 1 ] && [ $# -le 2 ] || usage

base="$(git rev-parse -q --verify "$1^{commit}")" || { echo "check_commits: no such commit $1" >&2; exit 2; }
head="$(git rev-parse -q --verify "${2:-HEAD}^{commit}")" || { echo "check_commits: no such commit ${2:-HEAD}" >&2; exit 2; }

types='feat|fix|refactor|perf|test|docs|build|ci|chore|style|revert'
scopes="app server models api persona tools docs ci build sync map $(git ls-tree --name-only "$head:app/lib/features" 2>/dev/null | tr '\n' ' ')"
shape="^($types)(\\(([a-z0-9][a-z0-9/_-]*)\\))?!?: (.*)\$"
# Imperative verbs that look like a past tense, an -ing form or a third person.
not_tense=' Embed Shed Shred Wed Bring Cling Fling Ping Ring Sing Sling Spring Sting String Swing Wring Alias Bias Canvas '
trailer_keys='^(Co-Authored-By|Signed-off-by|Generated-with|Reviewed-by|Claude-Session|Change-Id):'

problems=0
problem() {
  echo "check_commits: $1 $2"
  problems=$((problems + 1))
}

count=0
for commit in $(git rev-list --reverse "$base..$head"); do
  count=$((count + 1))
  short="$(git rev-parse --short "$commit")"
  subject="$(git log -1 --format=%s "$commit")"
  message="$(git log -1 --format=%B "$commit")"
  if [[ ! "$subject" =~ $shape ]]; then
    problem "$short" "is not type(scope): Summary with a type of $types: $subject"
  else
    scope="${BASH_REMATCH[3]}"
    summary="${BASH_REMATCH[4]}"
    word="${summary%% *}"
    if [ -n "$scope" ] && [[ " $scopes " != *" $scope "* ]]; then
      problem "$short" "has the scope '$scope', not one of:$(printf ' %s' $scopes)"
    fi
    if [[ ! "$summary" =~ ^[A-Z0-9] ]]; then
      problem "$short" "does not start its summary in sentence case: $subject"
    fi
    if [[ "$summary" =~ [.[:space:]]$ ]] || [ -z "$summary" ]; then
      problem "$short" "ends its summary with a period or a space, or has none: $subject"
    fi
    if [[ "$word" =~ ^[A-Z][a-z]*([^e]ed|ing|[^su]s)$ ]] && [[ "$not_tense" != *" $word "* ]]; then
      problem "$short" "does not start its summary with an imperative ('$word'): $subject"
    fi
  fi
  if [ "${#subject}" -gt 72 ]; then
    problem "$short" "has a subject of ${#subject} characters, over 72: $subject"
  fi
  trailer="$(printf '%s\n' "$message" | git interpret-trailers --parse | head -1)"
  [ -n "$trailer" ] || trailer="$(printf '%s\n' "$message" | grep -iE "$trailer_keys" | head -1)"
  [ -z "$trailer" ] || problem "$short" "carries a trailer: $trailer"
  wide="$(printf '%s\n' "$message" | awk 'length > 100' | wc -l | tr -d ' ')"
  [ "$wide" -eq 0 ] || echo "check_commits: note: $short has $wide message line(s) over 100 characters"
done

if [ $problems -gt 0 ]; then
  echo "check_commits: $problems problem(s) in $count commit(s) since ${base:0:10}"
  exit 1
fi
echo "$count commit(s) since ${base:0:10} pass"
