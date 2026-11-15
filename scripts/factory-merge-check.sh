#!/usr/bin/env bash
# Compatibility wrapper — Step 3 hardened gate lives in factory-merge-gate.sh.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/factory-merge-gate.sh" "$@"
