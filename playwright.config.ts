import { defineConfig, devices } from "@playwright/test";

// Never attach to a presenter's dev server. Each run owns its production server.
export default defineConfig({
  testDir: "./tests",
  testIgnore: "**/slides/**",
  fullyParallel: true,
  forbidOnly: true,
  retries: 0,
  updateSnapshots: "none",
  workers: process.env.CI ? 1 : 2,
  timeout: 90_000,
  expect: { timeout: 5_000, toHaveScreenshot: { animations: "disabled", maxDiffPixelRatio: 0.001 } },
  outputDir: `${process.env.PW_ARTIFACT_DIR ?? "artifacts"}/test-results`,
  reporter: [["list"], ["html", { outputFolder: `${process.env.PW_ARTIFACT_DIR ?? "artifacts"}/playwright-report`, open: "never" }], ["json", { outputFile: `${process.env.PW_ARTIFACT_DIR ?? "artifacts"}/playwright-results.json` }]],
  snapshotPathTemplate: "{testDir}/__screenshots__/{platform}/{projectName}/{arg}{ext}",
  use: {
    baseURL: "http://127.0.0.1:3100",
    locale: "en-AU",
    timezoneId: "UTC",
    colorScheme: "light",
    reducedMotion: "reduce",
    serviceWorkers: "block",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    { name: "desktop", use: { ...devices["Desktop Chrome"], viewport: { width: 1440, height: 1080 } } },
    { name: "mobile", use: { ...devices["Pixel 7"], viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 } },
  ],
  webServer: {
    command: "npm run start -- --port 3100",
    url: "http://127.0.0.1:3100",
    reuseExistingServer: false,
    timeout: 60_000,
    env: { NEXT_TELEMETRY_DISABLED: "1" },
  },
});
