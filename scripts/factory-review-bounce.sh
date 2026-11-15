#!/usr/bin/env bash
# factory-review-bounce.sh — after a failed review receipt, choose QA vs Build.
# Always exits 0. Prints BOUNCE_QA or BOUNCE_BUILD.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

FILE=.fabro-review.json
if [ ! -f "$FILE" ]; then
  echo "missing $FILE; defaulting to Build bounce" >&2
  echo "BOUNCE_BUILD"
  exit 0
fi

python3 - "$FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
bounce = (data.get("bounce") or "build").lower()
summary = data.get("summary") or ""
print(f"review bounce → {bounce}: {summary}")
print("BOUNCE_QA" if bounce == "qa" else "BOUNCE_BUILD")
PY
