# NetworkOps Lite: agentic SDLC practice app

A practice repository for a workshop on the agentic software lifecycle with Claude Code. The app is a small dashboard of twelve synthetic network events. **It has a known bug:** filter to *Degraded* and the list shows 3 events, but the counter says 12.

## Set up

1. Node 24 and npm, the GitHub CLI signed in (`gh auth login`), and an agent harness: Claude Code, or DeepSeek Harness (`npm install -g @deepseek-ai/dsh`).
2. Clone this repository, then `npm ci` and `npx playwright install chromium`.
3. Check it runs: `npm run check`. The unit tests fail on purpose until the bug is fixed.

## The exercise

1. **Plan:** in Claude Code, inside this folder, turn the bug report into a GitHub issue with the fields in `.github/ISSUE_TEMPLATE/agent-task.yml`.
2. **Build:** fix it test-first, on a branch, with the smallest change.
3. **Verify:** `npm run check`, `npm run build` and `npm run test:e2e` all pass.
4. **Review:** open a pull request; a person approves before merge.

`AGENTS.md` and `CLAUDE.md` hold the project rules. Skills are in `.agents/skills/` and `.claude/skills/`, roles for Claude Code in `.claude/agents/`. All data is fictional.
