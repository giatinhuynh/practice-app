import AxeBuilder from "@axe-core/playwright";
import { test, expect } from "./fixtures";

test.beforeEach(async ({ page }) => { await page.goto("/"); });

test("@count-regression Degraded rows and visible count agree", async ({ page }) => {
  await page.getByRole("button", { name: "Degraded", exact: true }).click();
  await expect(page.getByTestId("event-row")).toHaveCount(3);
  await expect(page.getByTestId("visible-count"), "Degraded summary must equal its three rendered rows").toHaveText("3");
});

test("all filter transitions preserve the event/count contract", async ({ page }) => {
  for (const [status, count] of [["All", 12], ["Offline", 3], ["Healthy", 6], ["Degraded", 3], ["All", 12]] as const) {
    const button = page.getByRole("button", { name: status, exact: true });
    await button.click();
    await expect(button).toHaveAttribute("aria-pressed", "true");
    await expect(page.getByRole("button", { pressed: true })).toHaveCount(1);
    const rows = page.getByTestId("event-row");
    await expect(rows).toHaveCount(count);
    await expect(page.getByTestId("visible-count")).toHaveText(String(count));
    if (status !== "All") {
      for (const row of await rows.all()) await expect(row.locator(".status-badge")).toHaveText(status);
    }
  }
});

test("keyboard users can skip navigation and change status", async ({ page }) => {
  await page.keyboard.press("Tab");
  await expect(page.getByRole("link", { name: "Skip to event overview" })).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(page.getByRole("main")).toBeFocused();
  await page.keyboard.press("Tab");
  await expect(page.getByRole("button", { name: "All", exact: true })).toBeFocused();
  await page.keyboard.press("Tab");
  await page.keyboard.press("Space");
  await expect(page.getByTestId("visible-count")).toHaveText("6");
  await page.keyboard.press("Tab");
  await page.keyboard.press("Enter");
  await expect(page.getByRole("status")).toHaveText("3 degraded events in view");
});

test("automated accessibility checks across every filter", async ({ page }) => {
  for (const status of ["All", "Healthy", "Degraded", "Offline"]) {
    await page.getByRole("button", { name: status, exact: true }).click();
    const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21aa"]).analyze();
    expect(results.violations, `axe findings for ${status}`).toEqual([]);
  }
});

test("layout fits its viewport and mobile controls remain usable", async ({ page }, testInfo) => {
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  for (const button of await page.getByRole("button").all()) {
    const bounds = await button.boundingBox();
    expect(bounds).not.toBeNull();
    if (testInfo.project.name === "mobile") expect(bounds!.height).toBeGreaterThanOrEqual(44);
  }
  await page.getByRole("button", { name: "Offline", exact: true }).click();
  await expect(page.getByTestId("event-row").last()).toContainText("SYN-BEN-12");
});

test("HTTP endpoint preserves the synthetic v1 contract", async ({ request }) => {
  const response = await request.get("/api/events?status=Degraded");
  expect(response.status()).toBe(200);
  const body = await response.json();
  expect(body).toMatchObject({ schemaVersion: 1, synthetic: true, count: 3, total: 12 });
  expect(body.events).toHaveLength(3);
  expect(body.events.every((event: { status: string }) => event.status === "Degraded")).toBe(true);
  expect((await request.get("/api/events?status=unknown")).status()).toBe(400);
});
