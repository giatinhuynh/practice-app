# NetworkOps Lite

Run all commands from the **repository root**, not this directory. One root package and lockfile own dependencies.

```sh
npm ci
npm run dev
```

Open http://127.0.0.1:3000. The counter has a known bug: see the open GitHub issue.

Architecture: `src/data/events.json` → `src/lib/events.ts` → `src/lib/event-view.ts` → `src/components/dashboard.tsx`. The server page passes immutable synthetic fixtures to the interactive dashboard. `src/app/api/events/route.ts` exposes the same fixture through the stable v1 contract.

Use `npm run build && npm run test:e2e` for the real production-browser checks.
