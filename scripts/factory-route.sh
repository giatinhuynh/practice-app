#!/usr/bin/env bash
# factory-route.sh — diamond helper after intake.
# Exit 0 → QA path (skip Plan/Build). Exit 2 → Build path.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

FILE=.fabro-route.json
if [ ! -f "$FILE" ]; then
  echo "missing $FILE; defaulting to Build path" >&2
  exit 2
fi

python3 - "$FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
lane = (data.get("lane") or "build").lower()
labels = data.get("labels") or []
print(f"route: lane={lane} labels={labels} skips_build={data.get('skips_build')}")
sys.exit(0 if lane == "qa" else 2)
PY
