#!/usr/bin/env bash
# factory-lane-gate.sh — exit status from a lane receipt for Fabro diamonds.
#
# Usage: factory-lane-gate.sh <build|qa|review>
#
# Exit codes:
#   0  pass
#   2  fail → bounce to build (default)
#   3  fail → bounce to qa (review only)
#   9  receipt missing or invalid
set -euo pipefail

LANE="${1:-}"
case "$LANE" in
  build) FILE=.fabro-build.json ;;
  qa)    FILE=.fabro-qa.json ;;
  review) FILE=.fabro-review.json ;;
  *)
    echo "usage: factory-lane-gate.sh <build|qa|review>" >&2
    exit 9
    ;;
esac

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if [ ! -f "$FILE" ]; then
  echo "missing lane receipt: $FILE" >&2
  exit 9
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
if status == "pass":
    sys.exit(0)
if status == "fail":
    if lane == "review" and bounce == "qa":
        sys.exit(3)
    sys.exit(2)
print(f"invalid status in {path}: {status!r}", file=sys.stderr)
sys.exit(9)
PY
