import { describe, expect, it } from "vitest";
import { events, filterEvents, isStatusFilter, statusTotals } from "./events";
import { createEventView } from "./event-view";
import { GET } from "../app/api/events/route";

describe("synthetic fixture contract", () => {
  it("contains 12 distinct fictional assets and the specified distribution", () => {
    expect(events).toHaveLength(12);
    expect(new Set(events.map((event) => event.id)).size).toBe(12);
    expect(new Set(events.map((event) => event.asset)).size).toBe(12);
    expect(statusTotals(events)).toEqual({ Healthy: 6, Degraded: 3, Offline: 3 });
    for (const event of events) {
      expect(event.asset).toMatch(/^SYN-[A-Z]{3}-\d{2}$/);
      expect(Number.isFinite(Date.parse(event.observedAt))).toBe(true);
      expect(Object.keys(event).sort()).toEqual(["asset", "id", "observedAt", "region", "signal", "status"]);
    }
  });
  it.each([["All", 12], ["Healthy", 6], ["Degraded", 3], ["Offline", 3]] as const)("%s keeps rows and count aligned", (filter, count) => {
    const view = createEventView(events, filter);
    expect(view.rows).toHaveLength(count);
    expect(view.visibleCount).toBe(count);
    if (filter !== "All") expect(view.rows.every((row) => row.status === filter)).toBe(true);
    expect(events).toHaveLength(12);
  });
  it("handles empty and changed source collections without magic numbers", () => {
    expect(createEventView([], "Degraded")).toEqual({ rows: [], visibleCount: 0 });
    const source = events.slice(0, 2);
    expect(createEventView(source, "Offline")).toEqual({ rows: [], visibleCount: 0 });
    expect(createEventView(source, "All").visibleCount).toBe(2);
    expect(filterEvents(events, "All")).not.toBe(events);
  });
  it("derives the empty state when a filter matches no events", () => {
    const view = createEventView(events.slice(0, 6), "Offline");
    expect(view.rows).toEqual([]);
    expect(view.visibleCount).toBe(0);
  });
  it("rejects unrecognised filters at the boundary", () => {
    for (const value of ["", "degraded", "All ", "__proto__"]) expect(isStatusFilter(value)).toBe(false);
  });
});

describe("GET /api/events v1", () => {
  it.each([["All", 12], ["Healthy", 6], ["Degraded", 3], ["Offline", 3]] as const)("returns %s without changing the schema", async (status, count) => {
    const response = GET(new Request(`http://localhost/api/events?status=${status}`));
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(Object.keys(body).sort()).toEqual(["count", "events", "schemaVersion", "synthetic", "total"]);
    expect(body).toMatchObject({ count, total: 12, synthetic: true, schemaVersion: 1 });
    expect(body.events).toHaveLength(count);
  });
  it("defaults to all events", async () => {
    expect((await GET(new Request("http://localhost/api/events")).json()).count).toBe(12);
  });
  it("returns a clear 400 for an invalid status", async () => {
    const response = GET(new Request("http://localhost/api/events?status=unknown"));
    expect(response.status).toBe(400);
    expect(await response.json()).toHaveProperty("error");
  });
});
