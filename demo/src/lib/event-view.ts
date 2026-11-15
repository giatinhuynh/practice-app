import { filterEvents, type NetworkEvent, type StatusFilter } from "./events";

export function createEventView(events: readonly NetworkEvent[], filter: StatusFilter) {
  const rows = filterEvents(events, filter);
  return { rows, visibleCount: rows.length };
}
