#!/usr/bin/env bash
# factory-intake.sh — resolve inputs.issue into issue.md + .fabro-route.json.
#
# Accepts a GitHub issue number, or a local ticket slug under
# docs/factory/tickets/<slug>.md (demo default: ac-02-visible-count).
#
# Routing is automatic via scripts/factory-classify.py:
#   explicit labels / [qa]|[bug]|[feature] title tags win;
#   otherwise title+body heuristics pick qa|bug|feature.
# Legacy label rules still apply when labels are present (qa wins).
set -euo pipefail
CLASSIFY="$(cd "$(dirname "$0")" && pwd)/factory-classify.py"

ISSUE="${1:-}"
if [ -z "$ISSUE" ]; then
  echo "usage: factory-intake.sh <issue-number-or-ticket-slug>" >&2
  exit 2
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

OUT=issue.md
RECEIPT=.fabro-intake.json
ROUTE=.fabro-route.json

write_route() {
  # args forwarded as JSON from classify (or minimal lane/labels)
  python3 - "$ROUTE" "$ISSUE" "$1" <<'PY'
import json, sys
path, issue, raw = sys.argv[1:]
data = json.loads(raw)
payload = {
    "issue": issue,
    "kind": data.get("kind") or ("qa" if data.get("lane") == "qa" else "feature"),
    "lane": data.get("lane") or "build",
    "labels": data.get("labels") or [],
    "skips_build": bool(data.get("skips_build", data.get("lane") == "qa")),
    "confidence": data.get("confidence"),
    "source": data.get("source") or "intake",
    "reasons": data.get("reasons") or [],
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
print(
    f"Wrote {path}: kind={payload['kind']} lane={payload['lane']} "
    f"source={payload['source']} conf={payload.get('confidence')}"
)
PY
}

classify_card() {
  local title="$1" body_file="$2" labels_csv="$3"
  python3 "$CLASSIFY" --title "$title" --file "$body_file" --labels "$labels_csv"
}

write_intake() {
  local source="$1" title="$2"
  python3 - "$RECEIPT" "$ISSUE" "$source" "$title" <<'PY'
import json, sys
from datetime import datetime, timezone
path, issue, source, title = sys.argv[1:]
payload = {
    "issue": issue,
    "source": source,
    "title": title,
    "written_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
PY
}

extract_local_labels() {
  # Pull fenced labels from a ## Labels section (`bug`, `qa`, etc.)
  python3 - "$1" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
# DOTALL: allow a blank line after the heading before the label list.
m = re.search(r"(?ims)^##\s*Labels\s*\n+(.*?)(?=\n##\s|\Z)", text)
if not m:
    sys.exit(0)
block = m.group(1)
for name in re.findall(r"`([^`]+)`", block):
    print(name.strip().lower())
for name in re.findall(r"(?im)^\s*[-*]\s+(\w+)\s*$", block):
    print(name.strip().lower())
PY
}

if [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh is required to fetch issue #$ISSUE" >&2
    exit 9
  fi
  BODY="$(gh issue view "$ISSUE" --json number,title,body,labels,url)"
  TITLE="$(printf '%s' "$BODY" | python3 -c 'import json,sys; print(json.load(sys.stdin)["title"])')"
  LABELS_CSV="$(printf '%s' "$BODY" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(",".join(l["name"] for l in d.get("labels") or []))')"
  {
    echo "# GitHub issue #$ISSUE"
    echo
    printf '%s' "$BODY" | python3 -c '
import json,sys
d=json.load(sys.stdin)
print("**Title:**", d["title"])
print("**URL:**", d.get("url",""))
labels=", ".join(l["name"] for l in d.get("labels") or [])
print("**Labels:**", labels or "(none)")
print()
print(d.get("body") or "")
'
  } >"$OUT"
  CLASSIFIED="$(classify_card "$TITLE" "$OUT" "$LABELS_CSV")"
  write_intake "github" "$TITLE"
  write_route "$CLASSIFIED"
  LANE="$(printf '%s' "$CLASSIFIED" | python3 -c 'import json,sys; print(json.load(sys.stdin)["lane"])')"
  KIND="$(printf '%s' "$CLASSIFIED" | python3 -c 'import json,sys; print(json.load(sys.stdin)["kind"])')"
  echo "Wrote $OUT from GitHub issue #$ISSUE ($TITLE) kind=$KIND lane=$LANE"
  exit 0
fi

TICKET="docs/factory/tickets/${ISSUE}.md"
if [ ! -f "$TICKET" ]; then
  echo "No GitHub issue number and no local ticket at $TICKET" >&2
  exit 9
fi

TITLE="$(sed -n 's/^# //p' "$TICKET" | head -1)"
{
  echo "# Local factory ticket: $ISSUE"
  echo
  echo "Source: $TICKET"
  echo
  cat "$TICKET"
} >"$OUT"
LABELS_LINES="$(extract_local_labels "$TICKET" || true)"
LABELS_CSV="$(printf '%s\n' "$LABELS_LINES" | paste -sd, - || true)"
CLASSIFIED="$(classify_card "$TITLE" "$TICKET" "$LABELS_CSV")"
write_intake "local-ticket" "$TITLE"
write_route "$CLASSIFIED"
LANE="$(printf '%s' "$CLASSIFIED" | python3 -c 'import json,sys; print(json.load(sys.stdin)["lane"])')"
KIND="$(printf '%s' "$CLASSIFIED" | python3 -c 'import json,sys; print(json.load(sys.stdin)["kind"])')"
echo "Wrote $OUT from $TICKET kind=$KIND lane=$LANE"
