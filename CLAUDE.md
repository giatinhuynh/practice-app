# NetworkOps Lite practice app

A small Next.js dashboard with twelve synthetic network events, used to practise the agentic SDLC with Claude Code. No real systems, customers or credentials.

## Before you change anything

Read `docs/product/feature-spec.md` (what to build, criteria AC-01 to AC-07), `docs/product/GLOSSARY.md` and `docs/architecture/ADR-001.md` (why the view works the way it does).

## Commands

- `npm ci` once, then `npx playwright install chromium` for the browser tests.
- `npm run check`: lint, types and unit tests.
- `npm run build && npm run test:e2e`: the production build and browser tests on desktop and phone sizes. They use port 3100.
- `npm run dev`: the app on http://127.0.0.1:3000.

## Rules

- Work test-first: a failing test for the criterion, the smallest fix, then the same test passing.
- Rows and the visible count must come from one derived collection (`demo/src/lib/event-view.ts`).
- Keep the synthetic data and the v1 API unchanged.
- Don't weaken or delete tests, and don't edit `.github/` or `.claude/` unless the GitHub issue asks for it.
- Report the commands you actually ran and their results.

## Skills and subagents

Skills are in `.claude/skills/` (`spec-first`, `tdd`, `verify-ui`, `review-change`). Subagents are in `.claude/agents/` (`planner` and `reviewer` read only; `implementer` edits and tests).
