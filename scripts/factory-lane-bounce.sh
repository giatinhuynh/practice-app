#!/usr/bin/env bash
# factory-lane-bounce.sh — after a Fix edge, choose QA vs Build from the route.
# Always exits 0. Prints BOUNCE_QA or BOUNCE_BUILD.
#
# Usage: factory-lane-bounce.sh [prefer-build]
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if [ "${1:-}" = "prefer-build" ]; then
  echo "lane bounce → build (prefer-build)"
  echo "BOUNCE_BUILD"
  exit 0
fi

FILE=.fabro-route.json
if [ ! -f "$FILE" ]; then
  echo "missing $FILE; bouncing to Build" >&2
  echo "BOUNCE_BUILD"
  exit 0
fi

python3 - "$FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
lane = (data.get("lane") or "build").lower()
target = "qa" if lane == "qa" else "build"
print(f"lane bounce → {target} (route={lane})")
print("BOUNCE_QA" if target == "qa" else "BOUNCE_BUILD")
PY
