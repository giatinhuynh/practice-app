#!/usr/bin/env bash
# factory-board-plan.sh — read-only: build the next wave of Ready cards.
#
# Writes .fabro-wave.json:
#   { "source": "local"|"github", "cards": [...], "flag": [], "planned_at": "..." }
#
# Local: docs/factory/ready/queue.json (or board.local_ready).
# GitHub: Ready column via super-board-card.sh when board.source=github.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

BOARD="${FACTORY_BOARD_CONFIG:-docs/factory/board.json}"
OUT=.fabro-wave.json

[ -f "$BOARD" ] || { echo "board config missing: $BOARD" >&2; exit 66; }

python3 - "$BOARD" "$OUT" "$ROOT" <<'PY'
import json, os, subprocess, sys
from datetime import datetime, timezone

board_path, out_path, root = sys.argv[1:]
board = json.load(open(board_path, encoding="utf-8"))
source = (board.get("source") or "local").lower()
max_cards = int(board.get("max_cards") or 5)
ready_col = board.get("ready_column") or "Ready"
cards = []
flag = []

def lane_for(labels):
    labels = {str(l).lower() for l in (labels or [])}
    return "qa" if "qa" in labels else "build"

if source == "local":
    ready_path = board.get("local_ready") or "docs/factory/ready/queue.json"
    ready = json.load(open(ready_path, encoding="utf-8"))
    for raw in ready.get("cards") or []:
        issue = str(raw.get("issue") or "").strip()
        if not issue:
            flag.append({"issue": None, "why": "card missing issue"})
            continue
        labels = list(raw.get("labels") or [])
        cards.append({
            "issue": issue,
            "title": raw.get("title") or issue,
            "labels": labels,
            "lane": raw.get("lane") or lane_for(labels),
            "status": "Ready",
            "number": raw.get("number"),
        })
elif source == "github":
    cfg = board.get("super_board_config") or ".claude/super-board/configs/practice-app.json"
    card_sh = os.path.join(root, ".agents/bin/super-board-card.sh")
    if not os.path.isfile(card_sh):
        card_sh = os.path.join(root, ".claude/bin/super-board-card.sh")
    if not os.path.isfile(card_sh):
        print("super-board-card.sh not found", file=sys.stderr)
        sys.exit(66)
    proc = subprocess.run(
        ["bash", card_sh, "--config", cfg, "items"],
        capture_output=True, text=True,
    )
    if proc.returncode != 0:
        print(proc.stderr or proc.stdout, file=sys.stderr)
        sys.exit(proc.returncode or 69)
    payload = json.loads(proc.stdout)
    for item in payload.get("items") or []:
        if (item.get("status") or "") != ready_col:
            continue
        content = item.get("content") or {}
        if content.get("type") != "Issue":
            continue
        number = content.get("number")
        if number is None:
            flag.append({"title": item.get("title"), "why": "Ready item has no issue number"})
            continue
        labels = []
        for lab in item.get("labels") or []:
            if isinstance(lab, dict):
                labels.append(lab.get("name") or "")
            else:
                labels.append(str(lab))
        labels = [l for l in labels if l]
        cards.append({
            "issue": str(number),
            "title": content.get("title") or item.get("title") or f"#{number}",
            "labels": labels,
            "lane": lane_for(labels),
            "status": ready_col,
            "number": int(number),
        })
else:
    print(f"unknown board.source: {source}", file=sys.stderr)
    sys.exit(66)

cards = cards[:max_cards]
wave = {
    "source": source,
    "board": board_path,
    "cards": cards,
    "flag": flag,
    "count": len(cards),
    "planned_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(wave, f, indent=2)
    f.write("\n")

print(f"Wrote {out_path}: {len(cards)} Ready card(s) from {source}")
for c in cards:
    print(f"  - {c['issue']}: {c['title']} [{c['lane']}] labels={c['labels']}")
if flag:
    print(f"flagged: {len(flag)}")
    for f in flag:
        print(f"  ! {f}")
PY
