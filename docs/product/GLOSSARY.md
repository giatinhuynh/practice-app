# Workshop vocabulary

## Application

| Term | Meaning here |
| --- | --- |
| Event | A fixed fictional observation, not a live alert |
| Asset | A fabricated `SYN-` identifier with no infrastructure mapping |
| Visible count | Number of currently filtered event rows |
| Total | Number of all 12 fixture events, independent of the filter |
| Verified correction | The prepared source whose specified checks have actually passed |

## Agentic SDLC

| Term | Meaning here |
| --- | --- |
| Module | One of the four parts of the workshop (Foundations; Plan and build; Verify; Review and operate), each with numbered sub-modules |
| Agentic SDLC | A software lifecycle in which agents carry out bounded, delegated work at each stage while people own outcomes, boundaries and approval |
| Agent-ready issue | An issue with one observable outcome, testable criteria, constraints, verification commands and an out-of-scope list (`.github/ISSUE_TEMPLATE/agent-task.yml`) |
| Agentic workflow | An agent run from GitHub Actions on an event or schedule; read-only by default, writing only through declared safe outputs (public preview) |
| Session log | The cloud agent's record of the steps and commands it ran for a task |

## Harness

| Term | Meaning here |
| --- | --- |
| Agent harness | Context, roles, procedures, tools, environment and feedback around an agent |
| Subagent | A named role in `.claude/agents/*.md` with its own instructions and tool list |
| Skill | A reusable task procedure stored as `.claude/skills/<name>/SKILL.md`, loaded when relevant |
| MCP | A tool/context protocol. Access still needs explicit scoping |
| Hook | Code invoked at a supported agent lifecycle event. A `preToolUse` hook can deny a tool call; an `agentStop` hook can send the agent back to work |
| Automation | A cloud agent task that runs on a schedule or an event, such as nightly "fix failing tests" |
| Sandbox | An execution boundary configured by the operator, not an instruction file |

## Controls

| Term | Meaning here |
| --- | --- |
| Guidance | Anything the agent reads. It shapes quality but can be misread or edited in a pull request |
| Configured limit | A setting that bounds what an agent can reach: tool lists, MCP allowlists, firewall, environment |
| Deterministic gate | A check implemented as code, so the same change always gets the same answer: hooks, CI required checks, branch rules |
| Independent gate | A control outside the agent's reach: required checks, rulesets, human and code-owner review |
| Quality gate | A check independently executed and required by repository governance |
| Visual baseline | A reviewed reference image for a fixed rendering environment |
