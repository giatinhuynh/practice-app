---
name: tdd
description: Reproduce and correct a NetworkOps Lite behaviour defect with a red-green-refactor loop.
---
# Test the observable contract

1. Read the specification and inspect the responsible module.
2. Run the existing focused test. If none covers the defect, add a behaviour assertion at the appropriate seam.
3. Confirm the failing assertion describes the defect, not an installation, build or server-start problem.
4. Make the smallest correction. Keep fixtures, API shape and test expectations unchanged.
5. Rerun the test, then the related suite. Refactor only with green evidence.
6. Report the failing and passing commands and any unresolved checks.

The prepared exercise uses `npm run build` followed by `npm run test:regression`. Do not add `test.fail`, skip tests or accept any nonzero exit as proof of the intended regression.
