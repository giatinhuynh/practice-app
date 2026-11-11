import { test as base, expect } from "@playwright/test";

export const test = base.extend<{ cleanBrowser: void }>({
  cleanBrowser: [async ({ page, context, baseURL }, use) => {
    const errors: string[] = [];
    const externalRequests: string[] = [];
    const failedRequests: string[] = [];
    page.on("pageerror", (error) => errors.push(error.message));
    page.on("console", (message) => { if (message.type() === "error") errors.push(message.text()); });
    page.on("requestfailed", (request) => failedRequests.push(`${request.url()}: ${request.failure()?.errorText}`));
    await context.route("**/*", async (route) => {
      const url = new URL(route.request().url());
      if (url.origin !== new URL(baseURL!).origin) {
        externalRequests.push(url.origin);
        await route.abort();
      } else await route.continue();
    });
    await use();
    expect(errors, "browser errors").toEqual([]);
    expect(externalRequests, "unexpected external traffic").toEqual([]);
    expect(failedRequests, "failed requests").toEqual([]);
  }, { auto: true }],
});
export { expect };
