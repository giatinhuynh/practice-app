#!/usr/bin/env bash
# factory-board-run.sh — drain .fabro-wave.json through fabro run factory.
#
# For each Ready card (serial):
#   1. Claim (GitHub → Building, or local → in-flight)
#   2. fabro run factory -I issue=<id> --environment <env> -d
#   3. fabro wait <run>  (unless --detach)
#   4. On success → Done / remove from local Ready; on failure → Blocked
#
# Human gates inside factory still pause each child run — attach and approve.
# Pass --detach to only enqueue runs. Pass --dry-run to plan only.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

BOARD="${FACTORY_BOARD_CONFIG:-docs/factory/board.json}"
WAVE=.fabro-wave.json
DRY=0
DETACH=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --detach)  DETACH=1; shift ;;
    --board)   BOARD="$2"; shift 2 ;;
    --wave)    WAVE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,14p' "$0"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done

[ -f "$BOARD" ] || { echo "board config missing: $BOARD" >&2; exit 66; }
if [ ! -f "$WAVE" ]; then
  bash scripts/factory-board-plan.sh
fi

say() { echo "[factory-board] $*" >&2; }

SOURCE="$(python3 -c 'import json; print(json.load(open(".fabro-wave.json"))["source"])')"
ENV_ID="$(python3 -c 'import json; print(json.load(open("'"$BOARD"'")).get("environment") or "local")')"
WORKFLOW="$(python3 -c 'import json; print(json.load(open("'"$BOARD"'")).get("factory_workflow") or "factory")')"
RUNS_DIR="$(python3 -c 'import json; print(json.load(open("'"$BOARD"'")).get("runs_dir") or "docs/factory/runs")')"
SB_CFG="$(python3 -c 'import json; print(json.load(open("'"$BOARD"'")).get("super_board_config") or "")')"
READY_PATH="$(python3 -c 'import json; print(json.load(open("'"$BOARD"'")).get("local_ready") or "docs/factory/ready/queue.json")')"

COUNT="$(python3 -c 'import json; print(len(json.load(open(".fabro-wave.json")).get("cards") or []))')"
say "draining $COUNT card(s) via fabro run $WORKFLOW (env=$ENV_ID, source=$SOURCE)"

if [ "$COUNT" -eq 0 ]; then
  say "queue empty — nothing to dispatch"
  exit 0
fi

if [ "$DRY" -eq 1 ]; then
  say "dry-run: would dispatch:"
  python3 -c 'import json; [print(" ", c["issue"], c["lane"], c["title"]) for c in json.load(open(".fabro-wave.json")).get("cards") or []]'
  exit 0
fi

RUN_ID="board-$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$RUNS_DIR/$RUN_ID"
mkdir -p "$RUN_DIR"
cp "$WAVE" "$RUN_DIR/wave.json"
cp "$BOARD" "$RUN_DIR/board.json"
: >"$RUN_DIR/dispatched.jsonl"
: >"$RUN_DIR/results.txt"

CARD_SH=""
if [ "$SOURCE" = "github" ]; then
  if [ -x .agents/bin/super-board-card.sh ]; then
    CARD_SH=.agents/bin/super-board-card.sh
  elif [ -x .claude/bin/super-board-card.sh ]; then
    CARD_SH=.claude/bin/super-board-card.sh
  else
    echo "super-board-card.sh required for github source" >&2
    exit 66
  fi
fi

claim_card() {
  local issue="$1"
  if [ "$SOURCE" = "github" ]; then
    case "$issue" in
      *[!0-9]*) return 0 ;;
      *) bash "$CARD_SH" --config "$SB_CFG" move "$issue" Building || return $? ;;
    esac
  fi
  return 0
}

finish_card() {
  local issue="$1" outcome="$2"
  if [ "$SOURCE" = "github" ]; then
    case "$issue" in
      *[!0-9]*) ;;
      *)
        col=Done
        [ "$outcome" = "succeeded" ] || col=Blocked
        bash "$CARD_SH" --config "$SB_CFG" move "$issue" "$col" || true
        ;;
    esac
  fi
  if [ "$SOURCE" = "local" ]; then
    python3 - "$READY_PATH" "$issue" "$outcome" "$RUN_DIR" <<'PY'
import json, sys, os
ready_path, issue, outcome, run_dir = sys.argv[1:]
ready = json.load(open(ready_path, encoding="utf-8"))
kept, done = [], None
for c in ready.get("cards") or []:
    if str(c.get("issue")) == issue:
        done = dict(c)
        done["outcome"] = outcome
    else:
        kept.append(c)
ready["cards"] = kept
with open(ready_path, "w", encoding="utf-8") as f:
    json.dump(ready, f, indent=2)
    f.write("\n")
if done is not None:
    with open(os.path.join(run_dir, "completed.jsonl"), "a", encoding="utf-8") as f:
        f.write(json.dumps(done) + "\n")
PY
  fi
}

ISSUE_LIST="$(mktemp)"
python3 -c 'import json; [print(c["issue"]) for c in json.load(open(".fabro-wave.json")).get("cards") or []]' >"$ISSUE_LIST"
while IFS= read -r issue; do
  [ -n "$issue" ] || continue
  TITLE="$(python3 -c 'import json,sys; cards=json.load(open(".fabro-wave.json"))["cards"]; print(next(c["title"] for c in cards if str(c["issue"])==sys.argv[1]))' "$issue")"
  say "claim $issue — $TITLE"
  if ! claim_card "$issue"; then
    say "claim failed for $issue"
    echo "$issue:claim-failed" >>"$RUN_DIR/results.txt"
    continue
  fi

  say "fabro run $WORKFLOW -I issue=$issue"
  set +e
  RUN_OUT="$(fabro run "$WORKFLOW" --environment "$ENV_ID" -I "issue=$issue" -d --label "factory-board=$RUN_ID" --label "issue=$issue" 2>&1)"
  RUN_RC=$?
  set -e
  echo "$RUN_OUT"
  if [ "$RUN_RC" -ne 0 ]; then
    say "fabro run failed for $issue"
    finish_card "$issue" "failed"
    echo "$issue:run-failed" >>"$RUN_DIR/results.txt"
    continue
  fi

  FABRO_ID="$(printf '%s\n' "$RUN_OUT" | python3 -c '
import sys,re
text=sys.stdin.read()
for line in text.splitlines():
    m=re.search(r"\b(01[0-9A-HJKMNP-TV-Z]{24})\b", line)
    if m:
        print(m.group(1)); break
')"

  python3 -c 'import json,sys; print(json.dumps({"issue":sys.argv[1],"fabro_run":sys.argv[2],"title":sys.argv[3]}))' \
    "$issue" "$FABRO_ID" "$TITLE" >>"$RUN_DIR/dispatched.jsonl"

  if [ "$DETACH" -eq 1 ]; then
    say "detached $issue → $FABRO_ID (approve gates with fabro attach/approve)"
    echo "$issue:detached:$FABRO_ID" >>"$RUN_DIR/results.txt"
    continue
  fi

  if [ -z "$FABRO_ID" ]; then
    say "could not parse fabro run id; not waiting"
    echo "$issue:unknown-id" >>"$RUN_DIR/results.txt"
    continue
  fi

  say "waiting on $FABRO_ID (human gates may pause — attach in Fabro UI/CLI)"
  set +e
  fabro wait "$FABRO_ID"
  WAIT_RC=$?
  set -e
  if [ "$WAIT_RC" -eq 0 ]; then
    finish_card "$issue" "succeeded"
    echo "$issue:succeeded:$FABRO_ID" >>"$RUN_DIR/results.txt"
  else
    finish_card "$issue" "failed"
    echo "$issue:failed:$FABRO_ID" >>"$RUN_DIR/results.txt"
  fi
done <"$ISSUE_LIST"
rm -f "$ISSUE_LIST"

python3 - "$RUN_DIR/manifest.json" "$RUN_ID" "$RUN_DIR/results.txt" <<'PY'
import json, sys
path, run_id, results_path = sys.argv[1:]
results = [ln.strip() for ln in open(results_path, encoding="utf-8") if ln.strip()]
payload = {"run_id": run_id, "count": len(results), "results": results}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
print(json.dumps(payload, indent=2))
PY

say "board drain complete → $RUN_DIR/manifest.json"
