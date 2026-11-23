import AxeBuilder from "@axe-core/playwright";
import { test, expect } from "./fixtures";

test.beforeEach(async ({ page }) => { await page.goto("/"); });

test("health map sits above the event list and names all four regions", async ({ page }) => {
  const order = await page.evaluate(() =>
    Array.from(document.querySelectorAll(".health-map, .events-panel")).map((el) => el.className),
  );
  expect(order).toEqual(["health-map", "events-panel"]);

  await expect(page.getByRole("listitem")).toHaveCount(4);
  for (const region of ["Melbourne", "Geelong", "Ballarat", "Bendigo"]) {
    await expect(page.getByRole("heading", { name: region })).toBeVisible();
  }
});

test("each region shows one overall status and healthy, degraded and offline counts", async ({ page }) => {
  const expected = [
    { region: "Melbourne", overall: "Offline", healthy: 2, degraded: 1, offline: 1 },
    { region: "Geelong", overall: "Offline", healthy: 2, degraded: 0, offline: 1 },
    { region: "Ballarat", overall: "Degraded", healthy: 1, degraded: 1, offline: 0 },
    { region: "Bendigo", overall: "Offline", healthy: 1, degraded: 1, offline: 1 },
  ];

  const cards = page.getByRole("listitem");
  await expect(cards).toHaveCount(expected.length);
  for (let i = 0; i < expected.length; i++) {
    const card = cards.nth(i);
    const { region, overall, healthy, degraded, offline } = expected[i];
    await expect(card).toContainText(region);
    await expect(card.locator(".region-status-word")).toHaveText(overall);
    await expect(card.locator(".region-count-healthy")).toHaveText(`${healthy} healthy`);
    await expect(card.locator(".region-count-degraded")).toHaveText(`${degraded} degraded`);
    await expect(card.locator(".region-count-offline")).toHaveText(`${offline} offline`);
  }
});

test("status is shown with a word and an icon, not colour alone", async ({ page }) => {
  const cards = page.getByRole("listitem");
  await expect(cards).toHaveCount(4);
  for (let i = 0; i < 4; i++) {
    await expect(cards.nth(i).locator(".region-status svg")).toHaveCount(1);
    await expect(cards.nth(i).locator(".region-status-word")).not.toBeEmpty();
  }
});

test("regions are reachable and announced with name, status and counts", async ({ page }) => {
  const melbourne = page.getByRole("listitem").filter({ hasText: "Melbourne" });
  // The name is a heading a keyboard-driven screen reader can jump to.
  await expect(melbourne.getByRole("heading", { name: "Melbourne" })).toBeVisible();
  // Status and counts follow the name in reading order.
  await expect(melbourne.locator(".region-status-word")).toHaveText("Offline");
  await expect(melbourne).toContainText("2 healthy");
  await expect(melbourne).toContainText("1 degraded");
  await expect(melbourne).toContainText("1 offline");

  await expect(page.getByRole("heading", { level: 3 })).toHaveCount(4);
});

test("health map does not change when the status filter changes", async ({ page }) => {
  await page.getByRole("button", { name: "Offline", exact: true }).click();
  await expect(page.getByTestId("visible-count")).toHaveText("3");

  // The map still shows all four regions with full counts, not the 3 filtered events.
  await expect(page.getByRole("listitem")).toHaveCount(4);
  const ballarat = page.getByRole("listitem").filter({ hasText: "Ballarat" });
  await expect(ballarat.locator(".region-status-word")).toHaveText("Degraded");
  await expect(ballarat.locator(".region-count-healthy")).toHaveText("1 healthy");
  await expect(ballarat.locator(".region-count-degraded")).toHaveText("1 degraded");
  await expect(ballarat.locator(".region-count-offline")).toHaveText("0 offline");
});

test("health map passes automated accessibility checks", async ({ page }) => {
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21aa"]).analyze();
  expect(results.violations).toEqual([]);
});
