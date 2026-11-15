# QA: Visible events counter (AC-02)

## Acceptance criteria

- After any status filter, the Visible events counter equals the number of rows listed.
- Fixtures and the v1 API stay unchanged.
- Prove with `npm run check` (unit tests covering filtered counts).

## Context

Hardening ticket for code that should already exist. The factory must **skip
Build** and run QA → Review only (Superboard `qa` label).

See `docs/product/feature-spec.md` (AC-02) and `docs/architecture/ADR-001.md`.

## Labels

`qa`
