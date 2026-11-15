#!/usr/bin/env python3
"""Classify a factory card into qa | bug | feature from title/body/labels.

Used by factory-intake.sh and Factory Control Room so routing is automatic.
Explicit labels / [tags] win; otherwise heuristic keyword scoring.

Stdout: JSON { kind, lane, confidence, source, reasons, labels }
"""
from __future__ import annotations

import argparse
import json
import re
import sys

KIND_TO_LANE = {"qa": "qa", "bug": "build", "feature": "build"}

QA_WORDS = {
    "qa",
    "test",
    "tests",
    "testing",
    "verify",
    "verification",
    "regression",
    "coverage",
    "e2e",
    "smoke",
    "assert",
    "acceptance",
    "spec check",
}
BUG_WORDS = {
    "bug",
    "fix",
    "fixes",
    "fixed",
    "broken",
    "crash",
    "crashes",
    "error",
    "errors",
    "fail",
    "fails",
    "failing",
    "failure",
    "regression bug",
    "hotfix",
    "npe",
    "exception",
    "wrong",
    "incorrect",
    "does not",
    "doesn't",
    "cannot",
    "can't",
}
FEATURE_WORDS = {
    "feature",
    "add",
    "adds",
    "adding",
    "implement",
    "implementation",
    "new",
    "support",
    "enable",
    "introduce",
    "create",
    "enhance",
    "enhancement",
    "improve",
    "improvement",
    "ui",
    "ux",
    "endpoint",
    "api",
}


def parse_labels(raw: str) -> list[str]:
    if not raw:
        return []
    parts = re.split(r"[,|\s]+", raw.strip())
    return [p.strip().lower() for p in parts if p.strip()]


def title_tag(title: str) -> str | None:
    m = re.match(r"^\s*\[(qa|bug|feature)\]\s*", title or "", re.I)
    if m:
        return m.group(1).lower()
    m = re.match(r"^\s*(qa|bug|feature)\s*[:\-—]\s+", title or "", re.I)
    if m:
        return m.group(1).lower()
    return None


def score_text(text: str) -> dict[str, float]:
    t = (text or "").lower()
    scores = {"qa": 0.0, "bug": 0.0, "feature": 0.0}
    for w in QA_WORDS:
        if w in t:
            scores["qa"] += 1.5 if w in {"qa", "e2e", "regression", "verify"} else 1.0
    for w in BUG_WORDS:
        if w in t:
            scores["bug"] += 1.6 if w in {"bug", "fix", "crash", "hotfix"} else 1.0
    for w in FEATURE_WORDS:
        if w in t:
            scores["feature"] += 1.2 if w in {"feature", "implement", "add", "new"} else 0.8
    # Phrases
    if re.search(r"\b(unit|integration|e2e)\s+tests?\b", t):
        scores["qa"] += 2.0
    if re.search(r"\b(reproduce|stack\s*trace|throws?)\b", t):
        scores["bug"] += 2.0
    if re.search(r"\b(add(s|ing)?|implement)\b.+\b(button|page|api|endpoint|screen)\b", t):
        scores["feature"] += 2.0
    return scores


def classify(title: str, body: str = "", labels: list[str] | None = None) -> dict:
    labels = [l.lower() for l in (labels or []) if l and l.lower() != "auto"]
    reasons: list[str] = []

    # 1) Explicit route labels
    if "qa" in labels:
        return result("qa", 1.0, "explicit-label", ["label:qa"], labels)
    if "bug" in labels:
        return result("bug", 0.95, "explicit-label", ["label:bug"], labels)
    if "feature" in labels:
        return result("feature", 0.95, "explicit-label", ["label:feature"], labels)

    # 2) Title tag [qa] / bug: …
    tag = title_tag(title or "")
    if tag:
        return result(tag, 0.9, "title-tag", [f"title-tag:{tag}"], labels + [tag])

    # 3) Heuristic scoring
    scores = score_text(f"{title or ''}\n{body or ''}")
    ranked = sorted(scores.items(), key=lambda kv: kv[1], reverse=True)
    top_kind, top = ranked[0]
    second = ranked[1][1] if len(ranked) > 1 else 0.0
    if top <= 0:
        reasons.append("no strong signals; default feature")
        return result("feature", 0.35, "default", reasons, labels + ["feature"])

    margin = top - second
    confidence = min(0.88, 0.45 + top * 0.12 + margin * 0.08)
    for k, v in ranked:
        if v > 0:
            reasons.append(f"score:{k}={v:.1f}")
    return result(top_kind, round(confidence, 2), "heuristic", reasons, labels + [top_kind])


def result(kind: str, confidence: float, source: str, reasons: list[str], labels: list[str]) -> dict:
    kind = kind if kind in KIND_TO_LANE else "feature"
    uniq = []
    for l in labels:
        if l and l not in uniq:
            uniq.append(l)
    if kind not in uniq:
        uniq.insert(0, kind)
    return {
        "kind": kind,
        "lane": KIND_TO_LANE[kind],
        "skips_build": kind == "qa",
        "confidence": confidence,
        "source": source,
        "reasons": reasons,
        "labels": uniq,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--title", default="")
    ap.add_argument("--body", default="")
    ap.add_argument("--labels", default="", help="comma/space separated; 'auto' ignored")
    ap.add_argument("--file", help="optional ticket markdown path")
    args = ap.parse_args()

    title = args.title
    body = args.body
    if args.file:
        text = open(args.file, encoding="utf-8").read()
        if not title:
            m = re.search(r"^#\s+(.+)$", text, re.M)
            title = m.group(1).strip() if m else ""
        if not body:
            body = text

    out = classify(title, body, parse_labels(args.labels))
    json.dump(out, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
