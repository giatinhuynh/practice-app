#!/usr/bin/env bash
# factory-route.sh — diamond helper after intake / install.
# Always exits 0. Prints LANE_QA or LANE_BUILD for edge conditions:
#   condition="context.command.output contains LANE_QA"
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

FILE=.fabro-route.json
if [ ! -f "$FILE" ]; then
  echo "missing $FILE; defaulting to Build path" >&2
  echo "LANE_BUILD"
  exit 0
fi

python3 - "$FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
lane = (data.get("lane") or "build").lower()
if lane not in ("qa", "build"):
    lane = "build"
labels = data.get("labels") or []
print(f"route: lane={lane} labels={labels} skips_build={data.get('skips_build')}")
print("LANE_QA" if lane == "qa" else "LANE_BUILD")
PY
