import { filterEvents, type NetworkEvent, type StatusFilter } from "./events";

export type Aura = "critical" | "watch" | "calm";

function auraFor(rows: readonly NetworkEvent[]): Aura {
  if (rows.some((row) => row.status === "Offline")) return "critical";
  if (rows.some((row) => row.status === "Degraded")) return "watch";
  return "calm";
}

export function createEventView(events: readonly NetworkEvent[], filter: StatusFilter) {
  const rows = filterEvents(events, filter);
  return { rows, visibleCount: rows.length, aura: auraFor(rows) };
}
