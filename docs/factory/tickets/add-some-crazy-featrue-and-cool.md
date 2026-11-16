# ADD SOME CRAZY FEATRUE AND COOL

## Goal

Ship a **Neon Severity Aura** on the NetworkOps Lite dashboard — a visible, slightly over-the-top status glow driven by the events currently in view. Keep fixtures and the v1 API unchanged. Work test-first.

## Acceptance criteria

1. **Aura in the view model** — `createEventView` returns an `aura` field:
   - `"critical"` when any filtered row has status `Offline`
   - `"watch"` when there is no Offline row but at least one `Degraded` row
   - `"calm"` otherwise (including empty views)
2. **UI wires it** — the main dashboard surface exposes `data-aura="{aura}"` (e.g. on the primary content wrapper) so the glow is observable in the DOM (`data-testid="dashboard-aura"` is fine).
3. **Visible count stays honest** — `visibleCount` remains `rows.length` (AC-02 invariant). Prove with `npm run test:unit` (existing “keeps rows and count aligned” cases) plus new aura cases.
4. **Proof** — `npm run check` passes. Fixtures (`demo/src/data/events.json`), `demo/src/lib/events.ts`, and the v1 `/api/events` route stay untouched.

## Labels

`feature`

## Route (auto)

- kind: `feature`
- lane: `build`
- source: `human`
- confidence: `1.0`
