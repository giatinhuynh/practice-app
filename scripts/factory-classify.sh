#!/usr/bin/env bash
# factory-classify.sh — auto-route a card (qa|bug|feature) from title/body/labels.
# Usage:
#   factory-classify.sh --title "…" [--body "…"] [--labels auto|qa|bug|feature]
#   factory-classify.sh --file docs/factory/tickets/foo.md
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$ROOT/scripts/factory-classify.py" "$@"
