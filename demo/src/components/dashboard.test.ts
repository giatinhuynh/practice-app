import { describe, expect, it } from "vitest";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { Dashboard } from "./dashboard";
import { events } from "../lib/events";

describe("dashboard empty state", () => {
  it("renders the empty-state row and a zero visible count when no events match", () => {
    const html = renderToStaticMarkup(createElement(Dashboard, { events: [] }));
    expect(html).toContain("No events match this filter");
    expect(html).toContain('data-testid="empty-state"');
    expect(html).toMatch(/data-testid="visible-count"[^>]*>0</);
  });

  it("shows event rows and no empty-state row when events are present", () => {
    const html = renderToStaticMarkup(createElement(Dashboard, { events }));
    expect(html).toContain('data-testid="event-row"');
    expect(html).not.toContain("No events match this filter");
    expect(html).not.toContain('data-testid="empty-state"');
  });
});
