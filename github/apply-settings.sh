#!/usr/bin/env bash
# Applies the stored GitHub defaults (repo settings, default-branch ruleset, security features, labels), then verifies.
# Usage: apply-settings.sh <owner/repo> [--check] [--codeql] [--prune-labels]

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="" check_only=false codeql=false prune=false
for arg in "$@"; do
  case "$arg" in
    --check) check_only=true ;;
    --codeql) codeql=true ;;
    --prune-labels) prune=true ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) repo="$arg" ;;
  esac
done
[ -n "$repo" ] || { sed -n 3p "$0" | sed 's/^# //' >&2; exit 2; }

if $codeql; then
  ruleset="$(jq --slurpfile rule "$here/codeql-rule.json" '.rules += $rule' "$here/default-branch-ruleset.json")"
else
  ruleset="$(cat "$here/default-branch-ruleset.json")"
fi
ruleset_name="$(jq -r .name <<< "$ruleset")"
normalise_ruleset='{enforcement, conditions, bypass_actors, rules: (.rules | sort_by(.type))}'

ruleset_id() {
  gh api "repos/$repo/rulesets" --jq ".[] | select(.name == \"$ruleset_name\") | .id"
}

label_uri() { jq -rn --arg s "$1" '$s | @uri'; }

drift=0
report() {
  if [ "$2" = "$3" ]; then echo "ok      $1"; else echo "differs $1: $2 -> $3"; drift=1; fi
}

check() {
  local live id live_labels
  live="$(gh api "repos/$repo")"
  while IFS=$'\t' read -r path have want; do
    report "$path" "$have" "$want"
  done < <(jq -r --argjson live "$live" \
    '. as $d | paths(type != "object" and type != "array") as $p | [($p | map(tostring) | join(".")), ($live | getpath($p) | tostring), ($d | getpath($p) | tostring)] | @tsv' \
    "$here/repo-settings.json")

  if gh api "repos/$repo/vulnerability-alerts" --silent 2>/dev/null; then have=true; else have=false; fi
  report vulnerability_alerts "$have" true
  report automated_security_fixes "$(gh api "repos/$repo/automated-security-fixes" --jq .enabled)" true
  if $codeql; then
    report code_scanning_default_setup "$(gh api "repos/$repo/code-scanning/default-setup" --jq .state)" configured
  fi

  id="$(ruleset_id)"
  if [ -z "$id" ]; then
    report "ruleset \"$ruleset_name\"" missing present
  else
    report "ruleset \"$ruleset_name\"" \
      "$(gh api "repos/$repo/rulesets/$id" | jq -cS "$normalise_ruleset")" \
      "$(jq -cS "$normalise_ruleset" <<< "$ruleset")"
  fi

  live_labels="$(gh api "repos/$repo/labels" --paginate | jq -s 'add | map({name, color, description: (.description // "")})')"
  while IFS=$'\t' read -r name have want; do
    report "label \"$name\"" "$have" "$want"
  done < <(jq -r --argjson live "$live_labels" \
    '.[] | . as $w | [.name, ($live | map(select(.name == $w.name)) | first | if . then "\(.color) \(.description)" else "missing" end), "\(.color) \(.description)"] | @tsv' \
    "$here/labels.json")
  if $prune; then
    while IFS= read -r extra; do
      report "label \"$extra\"" present absent
    done < <(jq -r --slurpfile want "$here/labels.json" '($want[0] | map(.name)) as $keep | .[] | select(.name as $n | $keep | index($n) | not) | .name' <<< "$live_labels")
  fi
}

apply() {
  local id
  gh api -X PATCH "repos/$repo" --input "$here/repo-settings.json" --silent
  gh api -X PUT "repos/$repo/vulnerability-alerts" --silent
  gh api -X PUT "repos/$repo/automated-security-fixes" --silent
  if $codeql; then
    gh api -X PATCH "repos/$repo/code-scanning/default-setup" -f state=configured --silent
  fi

  id="$(ruleset_id)"
  if [ -n "$id" ]; then
    gh api -X PUT "repos/$repo/rulesets/$id" --input - --silent <<< "$ruleset"
  else
    gh api -X POST "repos/$repo/rulesets" --input - --silent <<< "$ruleset"
  fi

  local live_names
  live_names="$(gh api "repos/$repo/labels" --paginate --jq '.[].name')"
  while IFS= read -r label; do
    name="$(jq -r .name <<< "$label")"
    if grep -qxF "$name" <<< "$live_names"; then
      gh api -X PATCH "repos/$repo/labels/$(label_uri "$name")" --input - --silent <<< "$label"
    else
      gh api -X POST "repos/$repo/labels" --input - --silent <<< "$label"
    fi
  done < <(jq -c '.[]' "$here/labels.json")
  if $prune; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      jq -e --arg n "$name" 'map(.name) | index($n)' "$here/labels.json" >/dev/null \
        || gh api -X DELETE "repos/$repo/labels/$(label_uri "$name")" --silent
    done <<< "$live_names"
  fi
}

$check_only || { apply; echo "applied to $repo; verifying"; }
check
exit "$drift"
