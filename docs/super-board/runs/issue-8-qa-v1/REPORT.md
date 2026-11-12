# issue-8-qa-v1 — QA evidence

Card #8 · `✨ [feature] events: show the date in the Observed column` · PR #9 · head `bca172c`

## Acceptance criteria

| AC | Verdict | Proof |
|---|---|---|
| AC-01 | ✅ | `tests/events.spec.ts:12` — `Observed cell shows day, short month and 24-hour UTC time` → `21 Oct · 00:42` |
| AC-02 | ✅ | `tests/events.spec.ts:17` — `time element keeps the full ISO timestamp in dateTime` → `2026-10-21T00:42:00Z` |
| AC-03 | ✅ | `demo/src/lib/events.test.ts:38` — `observedAt formatting` unit tests, incl. `00:05` just after midnight |

## Commands run

- `npm run check` → lint ✅, typecheck ✅, unit **4 failed / 12 passed** (4 failures are the pre-existing `visibleCount` bug — `createEventView` returns `visibleCount: events.length`; unrelated to this card, tracked by #1/#3/#5).
- `npm run build` → ✅
- `npx playwright test tests/events.spec.ts -g "AC-0"` → 4 passed (AC-01 + AC-02 on desktop + mobile)
- `npm run test:e2e` → **10 passed / 6 failed** (6 failures are the same pre-existing `visibleCount` bug; the AC-01/AC-02 tests pass)

## Screenshots

- `desktop.png` / `tablet.png` / `mobile.png` — after (date shown)
- `before-desktop.png` / `before-tablet.png` / `before-mobile.png` — before (time only)

## Security pass

`pr-security-review: 0 findings` — display-only change; no new input, injection, auth, crypto or data-exposure surface.

## Pre-existing failures (out of scope)

`createEventView` still returns `visibleCount: events.length` on `main`, so the visible-count unit and e2e assertions fail on every filter except All. Fixes are open in PRs #2, #4, #6 (issues #1, #3, #5). This card does not touch that code path.
