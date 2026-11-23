import { describe, expect, it } from "vitest";
import { events } from "./events";
import { createRegionHealth } from "./region-health";

describe("region health map", () => {
  it("derives the four regions in the required order", () => {
    expect(createRegionHealth(events).map((r) => r.region)).toEqual(["Melbourne", "Geelong", "Ballarat", "Bendigo"]);
  });

  it("counts healthy, degraded and offline events per region", () => {
    const health = createRegionHealth(events);
    const byRegion = Object.fromEntries(health.map((r) => [r.region, r.counts]));
    expect(byRegion.Melbourne).toEqual({ Healthy: 2, Degraded: 1, Offline: 1 });
    expect(byRegion.Geelong).toEqual({ Healthy: 2, Degraded: 0, Offline: 1 });
    expect(byRegion.Ballarat).toEqual({ Healthy: 1, Degraded: 1, Offline: 0 });
    expect(byRegion.Bendigo).toEqual({ Healthy: 1, Degraded: 1, Offline: 1 });
  });

  it("sets a region's overall status to its worst event", () => {
    const health = createRegionHealth(events);
    const overall = Object.fromEntries(health.map((r) => [r.region, r.overall]));
    expect(overall.Melbourne).toBe("Offline"); // has Healthy + Degraded + Offline
    expect(overall.Geelong).toBe("Offline"); // Healthy + Offline
    expect(overall.Ballarat).toBe("Degraded"); // Healthy + Degraded, no Offline
    expect(overall.Bendigo).toBe("Offline"); // Healthy + Degraded + Offline
  });

  it("handles a source with no events without magic numbers", () => {
    expect(createRegionHealth([])).toEqual([]);
  });
});
