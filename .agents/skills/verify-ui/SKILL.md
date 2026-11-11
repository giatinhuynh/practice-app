---
name: verify-ui
description: Verify user-facing features with functional tests, browser screenshots, accessibility scans and regression evidence.
---
# UI verification skill
For this workshop, read `docs/product/feature-spec.md` and `docs/architecture/ADR-001.md`. Run from the repository root. Use `npm run build` before `npm run test:e2e`. Use `npm run verify:isolated -- browser` for the canonical Linux visual environment. Inspect `artifacts/isolated/browser/` for reports and traces. Do not confuse the optional demo with a requirement for the 25-minute presentation.

1. Read acceptance criteria and relevant ADRs.
2. Start the application in the approved isolated development environment with synthetic data.
3. Run relevant unit, integration and browser E2E tests.
4. Capture desktop and mobile screenshots; compare against approved baselines in a stable environment.
5. Run automated accessibility checks and consider keyboard navigation.
6. Review error logs and any failed requests.
7. On failures, diagnose, implement the smallest fix and rerun the affected tests.
8. Produce test evidence and summarise risks and checks not performed.
Never suppress failing assertions, change visual baselines to hide bugs, or treat automated checks as comprehensive UX certification.
