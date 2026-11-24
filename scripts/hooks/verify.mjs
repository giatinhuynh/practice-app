import { spawnSync } from "node:child_process";
import { mkdir, writeFile } from "node:fs/promises";
import { fileURLToPath, pathToFileURL } from "node:url";

// Deterministic agentStop gate: the agent may not finish while `npm run check` fails.
// Same source, same result. The harness fails open if a hook times out, so CI remains the required gate.
export function decide(exitCode, output = "") {
  if (exitCode === 0) return {};
  if (exitCode === null) return {}; // our own timeout: fail open like the platform, CI still runs
  const tail = output.trim().split("\n").slice(-12).join("\n");
  return {
    decision: "block",
    reason: `npm run check is failing. Fix the cause without weakening tests, re-run npm run check, then finish.\n\n${tail}`,
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  for await (const chunk of process.stdin) { void chunk; }
  const root = fileURLToPath(new URL("../../", import.meta.url));
  const result = spawnSync(process.platform === "win32" ? "npm.cmd" : "npm", ["run", "check"], {
    cwd: root, encoding: "utf8", timeout: 100_000, maxBuffer: 8 * 1024 * 1024,
  });
  await mkdir(`${root}artifacts/hooks`, { recursive: true });
  await writeFile(`${root}artifacts/hooks/verification.json`, JSON.stringify({
    at: new Date().toISOString(), gate: "agentStop", command: "npm run check", exitCode: result.status,
    passed: result.status === 0, note: "Local gate. CI re-runs every check independently.",
  }, null, 2) + "\n");
  if (result.status === null) process.stderr.write("npm run check timed out; allowing the stop. CI remains the required gate.\n");
  process.stdout.write(JSON.stringify(decide(result.status, `${result.stdout ?? ""}\n${result.stderr ?? ""}`)) + "\n");
}
