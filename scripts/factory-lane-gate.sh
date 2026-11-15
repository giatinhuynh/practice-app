#!/usr/bin/env bash
# factory-lane-gate.sh — print GATE_PASS / GATE_FAIL from a lane receipt.
# Always exits 0 so Fabro diamonds can branch on context.command.output.
#
# Usage: factory-lane-gate.sh <build|qa|review>
set -euo pipefail

LANE="${1:-}"
case "$LANE" in
  build) FILE=.fabro-build.json ;;
  qa)    FILE=.fabro-qa.json ;;
  review) FILE=.fabro-review.json ;;
  *)
    echo "usage: factory-lane-gate.sh <build|qa|review>" >&2
    echo "GATE_FAIL"
    exit 0
    ;;
esac

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if [ ! -f "$FILE" ]; then
  echo "missing lane receipt: $FILE" >&2
  echo "GATE_FAIL"
  exit 0
fi

python3 - "$FILE" "$LANE" <<'PY'
import json, sys
path, lane = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
status = (data.get("status") or "").lower()
bounce = (data.get("bounce") or "build").lower()
summary = data.get("summary") or ""
print(f"{lane}: status={status} bounce={bounce} — {summary}")
print("GATE_PASS" if status == "pass" else "GATE_FAIL")
PY
