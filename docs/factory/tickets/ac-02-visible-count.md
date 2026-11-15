# Fix Visible events counter (AC-02)

## Acceptance criteria

- After any status filter, the Visible events counter equals the number of rows listed.
- Fixtures and the v1 API stay unchanged.
- Prove with `npm run check` (unit tests covering filtered counts).

## Context

See `docs/product/feature-spec.md` (AC-02) and `docs/architecture/ADR-001.md`.
The view must derive rows once and use `rows.length` for the visible count
(`demo/src/lib/event-view.ts`).

## Labels

`bug`
