# QA report — issue #10 (v1)

Card: ✨ [feature] events: show an empty-state row when no events match the filter
PR: #11 · branch `issue-10-events-empty-state-row` · head `0cabc9680664baff9147dca4272d38ffc9adadc4`

## Verdict

✅ Pass — 3/3 AC.

## Commands run (evidence before assertions)

| Command | Result |
|---|---|
| `npm run check` | lint ✓ · typecheck ✓ · `vitest run` 16 passed (14 lib + 2 new component) |
| `npm run build` | production build ✓ (Turbopack, static `/`) |
| `npm run test:e2e` | 12 passed (desktop + mobile) |
| `npx vitest run demo/src/components/dashboard.test.ts` | 2 passed · red-green verified (mutation "BROKEN TEXT" → 1 fail, restore → 2 pass) |

## Acceptance criteria ledger

- **AC-01** — empty-state row with text "No events match this filter"
  - `demo/src/components/dashboard.test.ts:10` — renders `data-testid="empty-state"` and the exact text.
  - Note: unreachable in the running app — the fixed 12-event fixture has a non-zero count for every status
    (All 12 / Healthy 6 / Degraded 3 / Offline 3), so no filter can match zero events. The render contract is
    proven at the component layer; `page.tsx` never passes an empty or filter-to-nothing source in production.
- **AC-02** — visible-events counter reads 0 in that state
  - `demo/src/lib/events.test.ts:35` — `createEventView(...).visibleCount === 0`
  - `demo/src/components/dashboard.test.ts:11` — `data-testid="visible-count"` renders `0`
- **AC-03** — a unit test covers the empty state
  - Builder: `demo/src/lib/events.test.ts:32` "derives the empty state when a filter matches no events"
  - Tester: `demo/src/components/dashboard.test.ts` (component render, added this pass)

## Test-gap check

- Builder's unit test covered only the data layer (`event-view.ts`), not the component render. A mutation of the
  empty-state row text or removal of the `<tr>` would have passed the Builder's tests (surviving mutant).
- Closed the High gap with `demo/src/components/dashboard.test.ts`, red-first (`renderToStaticMarkup` in the node
  vitest environment — no new dependencies). No app code changed.

## Security pass

`pr-security-review: 0 findings` — display-only diff (one CSS rule, static React text, a data derivation, a unit
test). No user input, no `dangerouslySetInnerHTML`, no auth, no data exposure.

## Screenshots

- `desktop.png` (1920×1080), `tablet.png` (1024×768), `mobile.png` (375×667) — running app, default "All" state.
- The empty state itself is not reachable in the running app (fixed fixture), so there is no screenshot of it; the
  render is proven by the component test above.
