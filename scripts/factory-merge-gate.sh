#!/usr/bin/env bash
# factory-merge-gate.sh — Superboard-style merge gate for the Fabro factory.
#
# Called only AFTER the human "Approve merge" hexagon (dsh never auto-merges).
#
# Inside a directory mutex:
#   1. Pin expect-head from .fabro-review.json (preferred) or .fabro-pr.json
#   2. If a PR exists, refuse when remote head ≠ reviewed head (exit 6)
#   3. Re-run verify_commands (default: npm run check) against THIS workspace
#   4. Squash-merge with --match-head-commit, or accept already-merged
#   5. Write .fabro-merge.json for calibrate
#
# Exit codes (aligned with super-board-merge-gate.sh where useful):
#   0  merged / already-merged / local-evidence OK
#   2  verification failed
#   3  PR closed without merge
#   4  could not take lock
#   6  head moved — review evidence void
#   7  merge refused / needs human
#   9  misconfiguration
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

RECEIPT=.fabro-merge.json
PR_FILE=.fabro-pr.json
REVIEW_FILE=.fabro-review.json
POLICY_FILE=docs/factory/merge-policy.json
LOCK_DIR=".fabro/merge.lock"
LOCK_TIMEOUT="${FACTORY_MERGE_LOCK_TIMEOUT:-1800}"
STALE_AFTER="${FACTORY_MERGE_STALE_AFTER:-5400}"

VERIFY_CMD="npm run check"
HUMAN_MERGES=true
if [ -f "$POLICY_FILE" ]; then
  VERIFY_CMD="$(python3 -c 'import json; d=json.load(open("docs/factory/merge-policy.json")); print((d.get("verify_commands") or ["npm run check"])[0])')"
  HUMAN_MERGES="$(python3 -c 'import json; d=json.load(open("docs/factory/merge-policy.json")); print(str(d.get("human_merges", True)).lower())')"
fi

say() { echo "[factory-merge-gate] $*" >&2; }

acquire() {
  local waited=0
  mkdir -p "$(dirname "$LOCK_DIR")"
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    if [ -f "$LOCK_DIR/at" ]; then
      local age=$(( $(date +%s) - $(cat "$LOCK_DIR/at" 2>/dev/null || echo 0) ))
      if [ "$age" -gt "$STALE_AFTER" ]; then
        say "reaping abandoned lock (${age}s old)"
        rm -rf "$LOCK_DIR"
        continue
      fi
    fi
    [ "$waited" -ge "$LOCK_TIMEOUT" ] && return 1
    sleep 2
    waited=$(( waited + 2 ))
  done
  date +%s >"$LOCK_DIR/at"
  echo "$$" >"$LOCK_DIR/pid"
  return 0
}

release() { rm -rf "$LOCK_DIR"; }

acquire || { say "could not take merge lock within ${LOCK_TIMEOUT}s"; exit 4; }
trap release EXIT

EXPECT_HEAD=""
if [ -f "$REVIEW_FILE" ]; then
  EXPECT_HEAD="$(python3 -c 'import json; d=json.load(open(".fabro-review.json")); print(d.get("head_sha") or "")')"
fi
if [ -z "$EXPECT_HEAD" ] && [ -f "$PR_FILE" ]; then
  EXPECT_HEAD="$(python3 -c 'import json; d=json.load(open(".fabro-pr.json")); print(d.get("head_sha") or "")')"
fi

LOCAL_HEAD="$(git rev-parse HEAD)"
if [ -n "$EXPECT_HEAD" ] && [ "$LOCAL_HEAD" != "$EXPECT_HEAD" ]; then
  # Local workspace moved after review — void unless review head empty.
  say "local HEAD ($LOCAL_HEAD) ≠ reviewed head ($EXPECT_HEAD)"
  exit 6
fi

PR_NUM=""
PR_URL=""
PR_MODE=""
if [ -f "$PR_FILE" ]; then
  PR_NUM="$(python3 -c 'import json; d=json.load(open(".fabro-pr.json")); print(d.get("number") or "")')"
  PR_URL="$(python3 -c 'import json; d=json.load(open(".fabro-pr.json")); print(d.get("url") or "")')"
  PR_MODE="$(python3 -c 'import json; d=json.load(open(".fabro-pr.json")); print(d.get("mode") or "")')"
fi

if [ -n "$PR_NUM" ] && command -v gh >/dev/null 2>&1; then
  STATE="$(gh pr view "$PR_NUM" --json state,mergeCommit,headRefOid --jq '{state:.state,merge:(.mergeCommit.oid // ""),head:.headRefOid}' 2>/dev/null || true)"
  if [ -n "$STATE" ]; then
    PR_STATE="$(printf '%s' "$STATE" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state"])')"
    REMOTE_HEAD="$(printf '%s' "$STATE" | python3 -c 'import json,sys; print(json.load(sys.stdin)["head"])')"
    REMOTE_MERGE="$(printf '%s' "$STATE" | python3 -c 'import json,sys; print(json.load(sys.stdin)["merge"])')"

    if [ "$PR_STATE" = "MERGED" ]; then
      say "already merged; writing receipt without re-verify of merge"
      python3 - "$RECEIPT" "already-merged" "$PR_NUM" "$PR_URL" "${REMOTE_MERGE:-$LOCAL_HEAD}" "$EXPECT_HEAD" "PR already merged" "$VERIFY_CMD" <<'PY'
import json, sys
path, mode, number, url, merge_sha, reviewed, note, checks = sys.argv[1:]
payload = {
    "mode": mode,
    "pr": int(number) if number.isdigit() else None,
    "pr_url": url or None,
    "merge_sha": merge_sha or None,
    "reviewed_head_sha": reviewed or None,
    "note": note,
    "checks": checks,
    "lock": True,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
print(f"Wrote {path}: mode={mode}")
PY
      exit 0
    fi

    if [ "$PR_STATE" != "OPEN" ] && [ "$PR_STATE" != "open" ]; then
      say "PR #$PR_NUM state=$PR_STATE; refusing"
      exit 3
    fi

    if [ -n "$EXPECT_HEAD" ] && [ -n "$REMOTE_HEAD" ] && [ "$EXPECT_HEAD" != "$REMOTE_HEAD" ]; then
      say "head moved: reviewed $EXPECT_HEAD, PR head is $REMOTE_HEAD — review evidence void"
      exit 6
    fi
  fi
fi

# Verification INSIDE the lock (Superboard lesson: never prove against a base
# that another merger can replace while you wait).
say "lock held; verifying with: $VERIFY_CMD"
# shellcheck disable=SC2086
eval "$VERIFY_CMD" >.fabro-check.log 2>&1 || {
  tail -40 .fabro-check.log >&2 || true
  exit 2
}
tail -20 .fabro-check.log

MODE="local-evidence"
MERGE_SHA="$LOCAL_HEAD"
NOTE="human approved at Fabro merge gate; no remote PR (mode=${PR_MODE:-none})"

if [ -n "$PR_NUM" ] && command -v gh >/dev/null 2>&1; then
  if [ "$HUMAN_MERGES" != "true" ]; then
    say "human_merges=false is not supported for dsh factory; refusing auto path"
    exit 7
  fi
  # Human hexagon already approved — authorized squash merge, pinned to head.
  MERGE_ARGS=(pr merge "$PR_NUM" --squash)
  if [ -n "$EXPECT_HEAD" ]; then
    MERGE_ARGS+=(--match-head-commit "$EXPECT_HEAD")
  fi
  if gh "${MERGE_ARGS[@]}"; then
    MODE="merged"
    MERGE_SHA="$(gh pr view "$PR_NUM" --json mergeCommit --jq '.mergeCommit.oid // empty')"
    MERGE_SHA="${MERGE_SHA:-$LOCAL_HEAD}"
    NOTE="squash-merged PR #$PR_NUM after human gate (expect-head=${EXPECT_HEAD:-none})"
  else
    say "gh pr merge failed; human must finish the merge"
    exit 7
  fi
fi

python3 - "$RECEIPT" "$MODE" "$PR_NUM" "$PR_URL" "$MERGE_SHA" "${EXPECT_HEAD:-$LOCAL_HEAD}" "$NOTE" "$VERIFY_CMD" <<'PY'
import json, sys
path, mode, number, url, merge_sha, reviewed, note, checks = sys.argv[1:]
payload = {
    "mode": mode,
    "pr": int(number) if number.isdigit() else None,
    "pr_url": url or None,
    "merge_sha": merge_sha or None,
    "reviewed_head_sha": reviewed or None,
    "note": note or None,
    "checks": checks,
    "lock": True,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
print(f"Wrote {path}: mode={mode} merge_sha={merge_sha}")
PY
