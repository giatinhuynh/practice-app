import { type EventStatus, type NetworkEvent } from "./events";

export type RegionHealth = Readonly<{
  region: string;
  overall: EventStatus;
  counts: Readonly<Record<EventStatus, number>>;
}>;

const severityRank: Record<EventStatus, number> = { Healthy: 0, Degraded: 1, Offline: 2 };

export function createRegionHealth(source: readonly NetworkEvent[]): readonly RegionHealth[] {
  const order: string[] = [];
  const byRegion = new Map<string, { overall: EventStatus; counts: Record<EventStatus, number> }>();

  for (const event of source) {
    let entry = byRegion.get(event.region);
    if (!entry) {
      entry = { overall: "Healthy", counts: { Healthy: 0, Degraded: 0, Offline: 0 } };
      byRegion.set(event.region, entry);
      order.push(event.region);
    }
    entry.counts[event.status] += 1;
    if (severityRank[event.status] > severityRank[entry.overall]) entry.overall = event.status;
  }

  return order.map((region) => {
    const entry = byRegion.get(region)!;
    return Object.freeze({ region, overall: entry.overall, counts: Object.freeze({ ...entry.counts }) });
  });
}
