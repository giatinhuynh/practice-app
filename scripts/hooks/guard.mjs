import { pathToFileURL } from "node:url";

// Deterministic preToolUse gate: the same tool call always gets the same answer, in milliseconds.
// Visual baselines may change only in a separate, human-reviewed change (see tests.instructions.md),
// so the agent is denied any attempt to rewrite them. Reading them stays allowed.
const READ_ONLY_TOOLS = new Set(["view", "read", "grep", "glob"]);
const SHELL_TOOLS = new Set(["bash", "powershell", "shell", "execute"]);
const BASELINES = "tests/__screenshots__";
const SHELL_WRITE = /(^|[\s;&|("'])(rm|mv|cp|tee|truncate|dd|git\s+(checkout|restore|rm|mv))\b|sed\s+-i|>/;

const deny = (reason) => ({ permissionDecision: "deny", permissionDecisionReason: reason });

export function check(payload) {
  const tool = String(payload?.toolName ?? payload?.tool_name ?? "").toLowerCase();
  if (READ_ONLY_TOOLS.has(tool)) return {};
  const raw = payload?.toolArgs ?? payload?.tool_input ?? {};
  const args = (typeof raw === "string" ? raw : JSON.stringify(raw)).replaceAll("\\\\", "/");
  if (/--update-snapshots|test:visual:update/.test(args)) {
    return deny("Updating visual baselines is reserved for a separate change that a person reviews. Fix the cause of the visual difference instead.");
  }
  if (args.includes(BASELINES) && (!SHELL_TOOLS.has(tool) || SHELL_WRITE.test(args))) {
    return deny(`Files under ${BASELINES} are reviewed visual baselines. They may only change in a separate change that a person reviews.`);
  }
  return {};
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  let input = "";
  let oversized = false;
  for await (const chunk of process.stdin) {
    if (oversized) continue;
    input += chunk;
    if (input.length > 1_048_576) oversized = true;
  }
  // Oversized payloads cannot be parsed in full; inspect the first MiB as text.
  const payload = oversized
    ? { toolName: input.match(/"toolName"\s*:\s*"([^"]+)"/)?.[1] ?? "", toolArgs: input.slice(0, 1_048_576) }
    : JSON.parse(input || "{}");
  const result = check(payload);
  // DeepSeek Harness's hooks bridge reads the decision from hookSpecificOutput.
  const answer = result.permissionDecision ? { hookSpecificOutput: { hookEventName: "PreToolUse", ...result } } : {};
  process.stdout.write(JSON.stringify(answer) + "\n");
}
