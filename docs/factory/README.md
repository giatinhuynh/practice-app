# Fabro factory (Step 4)

Single-card factory plus a **board orchestrator** that drains Ready into
`fabro run factory` — Superboard’s “many tasks” layer on Fabro’s graph.

## Two entry points

| Command | What it does |
| --- | --- |
| `fabro run factory` | One ticket (`-I issue=…`) through Build/QA/Review |
| `fabro run factory-board` | Plan Ready → approve wave → drain each card via factory |
| `bash scripts/factory-board.sh …` | Same board verbs without Fabro (plan / status / run / dry-run) |

## Board drain

```
Ready → plan wave → human Approve wave → for each card:
          claim → fabro run factory -I issue=… → wait (human plan/merge gates)
        → Done (or Blocked)
```

### Local queue (default)

`docs/factory/board.json` has `"source": "local"`. Cards live in
`docs/factory/ready/queue.json`. Completed cards are removed and logged under
`docs/factory/runs/<board-run-id>/`.

```sh
cd ~/Documents/fabro-practice
bash scripts/factory-board.sh status
bash scripts/factory-board.sh dry-run
bash scripts/factory-board.sh run --detach   # enqueue only; approve each child
# or:
fabro run factory-board --environment local
```

### GitHub Project

Set `"source": "github"` in `docs/factory/board.json`. Uses
`.claude/super-board/configs/practice-app.json` and `super-board-card.sh` to
read the Ready column and move cards Building → Done/Blocked.

## Single-card factory (Steps 1–3)

**Intake → Route → (Plan → Approve → Build \| skip) → Check → Draft PR → QA → Review → Human merge → Calibrate**

### Labels

| Label | Path |
| --- | --- |
| `qa` | Skip Plan/Build → Check → QA → Review |
| `bug` / `feature` / (none) | Plan → Approve → Build → … |

```sh
fabro run factory --environment local
fabro run factory --environment local -I issue=qa-visible-count
fabro run factory --environment local -I issue=42
```

### Merge gate

`scripts/factory-merge-gate.sh` runs only after the human merge hexagon: mutex,
expect-head pin, verify inside the lock, squash-merge. See
`docs/factory/merge-policy.json` (`human_merges: true` for dsh).

## Layout

| Path | Role |
| --- | --- |
| `.fabro/workflows/factory/` | Single-card graph |
| `.fabro/workflows/factory-board/` | Wave plan → approve → drain |
| `scripts/factory-board*.sh` | Board plan / run / CLI |
| `docs/factory/board.json` | source=local\|github, max_cards, paths |
| `docs/factory/ready/queue.json` | Local Ready queue |
| `docs/factory/tickets/` | Local ticket bodies for slug issues |
| `docs/factory/runs/` | Board drain manifests |
