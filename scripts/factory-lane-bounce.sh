#!/usr/bin/env bash
# factory-lane-bounce.sh — after a Fix edge, choose QA vs Build from the route.
# Exit 0 → QA. Exit 2 → Build.
#
# Usage: factory-lane-bounce.sh [prefer-build]
#   prefer-build: always Build (ignore qa route) — for check failures that need code.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if [ "${1:-}" = "prefer-build" ]; then
  echo "lane bounce → build (prefer-build)"
  exit 2
fi

FILE=.fabro-route.json
if [ ! -f "$FILE" ]; then
  echo "missing $FILE; bouncing to Build" >&2
  exit 2
fi

python3 - "$FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
lane = (data.get("lane") or "build").lower()
print(f"lane bounce → {'qa' if lane == 'qa' else 'build'} (route={lane})")
sys.exit(0 if lane == "qa" else 2)
PY
