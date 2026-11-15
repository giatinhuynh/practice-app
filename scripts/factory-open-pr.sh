#!/usr/bin/env bash
# factory-open-pr.sh — open (or reuse) a draft PR for the factory run.
#
# Writes .fabro-pr.json with number, url, head sha, and issue reference.
# If push/auth is unavailable, writes a local-only receipt so the human merge
# gate can still run (demo / offline path).
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

ISSUE="${1:-}"
RECEIPT=.fabro-pr.json
BASE="$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
if [ -z "$BASE" ]; then
  BASE=main
fi

HEAD_SHA="$(git rev-parse HEAD)"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

TITLE="factory: resolve ${ISSUE:-ticket}"
if [ -f issue.md ]; then
  FIRST="$(sed -n 's/^# //p' issue.md | head -1)"
  if [ -n "$FIRST" ]; then
    TITLE="factory: $FIRST"
  fi
fi

BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT
{
  echo "## Factory run"
  echo
  echo "Automated draft from the Fabro factory workflow."
  if [ -n "$ISSUE" ] && [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
    echo
    echo "Closes #$ISSUE"
  elif [ -n "$ISSUE" ]; then
    echo
    echo "Ticket: \`$ISSUE\`"
  fi
  echo
  echo "### Plan"
  if [ -f plan.md ]; then
    cat plan.md
  else
    echo "(no plan.md)"
  fi
  echo
  echo "### Checks"
  if [ -f .fabro-check.log ]; then
    echo '```'
    tail -40 .fabro-check.log
    echo '```'
  else
    echo "(no .fabro-check.log)"
  fi
} >"$BODY_FILE"

write_receipt() {
  local mode="$1" number="$2" url="$3" note="$4"
  python3 - "$RECEIPT" "$mode" "$number" "$url" "$HEAD_SHA" "$BRANCH" "$BASE" "$ISSUE" "$note" <<'PY'
import json, sys
path, mode, number, url, head, branch, base, issue, note = sys.argv[1:]
payload = {
    "mode": mode,
    "number": int(number) if number.isdigit() else None,
    "url": url or None,
    "head_sha": head,
    "branch": branch,
    "base": base,
    "issue": issue or None,
    "note": note or None,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
PY
}

if ! command -v gh >/dev/null 2>&1; then
  write_receipt "local-only" "" "" "gh not available; human merge gate is documentation-only"
  echo "Wrote $RECEIPT (local-only: no gh)"
  exit 0
fi

# Already have a PR for this branch?
EXISTING="$(gh pr list --head "$BRANCH" --json number,url,state --jq '.[0] // empty' 2>/dev/null || true)"
if [ -n "$EXISTING" ]; then
  NUM="$(printf '%s' "$EXISTING" | python3 -c 'import json,sys; print(json.load(sys.stdin)["number"])')"
  URL="$(printf '%s' "$EXISTING" | python3 -c 'import json,sys; print(json.load(sys.stdin)["url"])')"
  write_receipt "reused" "$NUM" "$URL" "existing PR for branch"
  echo "Reused PR #$NUM — $URL"
  exit 0
fi

# Need a pushable remote branch.
if ! git remote get-url origin >/dev/null 2>&1; then
  write_receipt "local-only" "" "" "no origin remote"
  echo "Wrote $RECEIPT (local-only: no origin)"
  exit 0
fi

if [ "$BRANCH" = "HEAD" ] || [ "$BRANCH" = "$BASE" ]; then
  BRANCH="factory/${ISSUE:-run}-$(echo "$HEAD_SHA" | cut -c1-7)"
  git switch -c "$BRANCH"
fi

if ! git push -u origin "HEAD:refs/heads/$BRANCH" 2>push.err; then
  write_receipt "local-only" "" "" "push failed: $(tr '\n' ' ' <push.err | head -c 200)"
  echo "Wrote $RECEIPT (local-only: push failed)"
  cat push.err >&2 || true
  rm -f push.err
  exit 0
fi
rm -f push.err

CREATE_ARGS=(pr create --draft --base "$BASE" --head "$BRANCH" --title "$TITLE" --body-file "$BODY_FILE")
if URL="$(gh "${CREATE_ARGS[@]}" 2>pr.err)"; then
  NUM="$(gh pr view "$URL" --json number --jq .number)"
  write_receipt "created" "$NUM" "$URL" "draft PR opened"
  echo "Opened draft PR #$NUM — $URL"
  rm -f pr.err
  exit 0
fi

write_receipt "local-only" "" "" "pr create failed: $(tr '\n' ' ' <pr.err | head -c 200)"
echo "Wrote $RECEIPT (local-only: pr create failed)"
cat pr.err >&2 || true
rm -f pr.err
exit 0
