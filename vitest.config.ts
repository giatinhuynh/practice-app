import { defineConfig } from "vitest/config";

export default defineConfig({ test: { include: ["demo/src/**/*.test.ts"], environment: "node" } });
