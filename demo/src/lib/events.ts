import fixture from "../data/events.json";

export const statuses = ["Healthy", "Degraded", "Offline"] as const;
export type EventStatus = (typeof statuses)[number];
export type StatusFilter = "All" | EventStatus;
export type NetworkEvent = Readonly<{
  id: string;
  asset: string;
  region: string;
  status: EventStatus;
  signal: string;
  observedAt: string;
}>;

export function isStatusFilter(value: string): value is StatusFilter {
  return value === "All" || statuses.some((status) => status === value);
}

// Validate data once at the boundary; consumers receive immutable fixtures.
export const events: readonly NetworkEvent[] = Object.freeze(fixture.map((event) => {
  if (!statuses.some((status) => status === event.status)) throw new Error("Invalid synthetic status");
  return Object.freeze({ ...event, status: event.status as EventStatus });
}));

export function filterEvents(source: readonly NetworkEvent[], filter: StatusFilter): readonly NetworkEvent[] {
  return source.filter((event) => filter === "All" || event.status === filter);
}

export function statusTotals(source: readonly NetworkEvent[]) {
  return Object.fromEntries(statuses.map((status) => [status, filterEvents(source, status).length])) as Record<EventStatus, number>;
}
