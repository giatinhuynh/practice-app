#!/usr/bin/env bash
# factory-review-bounce.sh — after a failed review receipt, choose QA vs Build.
# Exit 0 → route to QA. Exit 2 → route to Build.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

FILE=.fabro-review.json
if [ ! -f "$FILE" ]; then
  echo "missing $FILE; defaulting to Build bounce" >&2
  exit 2
fi

python3 - "$FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
bounce = (data.get("bounce") or "build").lower()
summary = data.get("summary") or ""
print(f"review bounce → {bounce}: {summary}")
sys.exit(0 if bounce == "qa" else 2)
PY
