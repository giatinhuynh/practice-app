#!/usr/bin/env bash
# factory-board.sh — board orchestrator verbs (Superboard-shaped, Fabro-backed).
#
#   plan     write .fabro-wave.json from Ready (local queue or GitHub)
#   status   show wave + local Ready counts (read-only)
#   run      plan (if needed) then drain through fabro run factory
#   dry-run  plan + print what would run
#
# Env: FACTORY_BOARD_CONFIG (default docs/factory/board.json)
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

VERB="${1:-}"
shift || true

case "$VERB" in
  plan)
    exec bash scripts/factory-board-plan.sh "$@"
    ;;
  status)
    bash scripts/factory-board-plan.sh >/dev/null
    python3 - <<'PY'
import json, os
wave = json.load(open(".fabro-wave.json", encoding="utf-8"))
board = json.load(open(os.environ.get("FACTORY_BOARD_CONFIG", "docs/factory/board.json"), encoding="utf-8"))
print(f"source={wave['source']}  ready={wave['count']}  max_cards={board.get('max_cards')}")
for c in wave.get("cards") or []:
    print(f"  Ready  {c['issue']:<24}  {c['lane']:<5}  {c['title']}")
for f in wave.get("flag") or []:
    print(f"  FLAG   {f}")
if wave["source"] == "local":
    ready = json.load(open(board.get("local_ready") or "docs/factory/ready/queue.json", encoding="utf-8"))
    print(f"local queue file cards: {len(ready.get('cards') or [])}")
PY
    ;;
  dry-run)
    bash scripts/factory-board-plan.sh
    exec bash scripts/factory-board-run.sh --dry-run "$@"
    ;;
  run)
    bash scripts/factory-board-plan.sh
    exec bash scripts/factory-board-run.sh "$@"
    ;;
  ""|-h|--help)
    sed -n '2,12p' "$0"
    echo "usage: factory-board.sh <plan|status|run|dry-run> [--detach]"
    exit 0
    ;;
  *)
    echo "unknown verb: $VERB (plan|status|run|dry-run)" >&2
    exit 64
    ;;
esac
