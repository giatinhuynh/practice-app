import { filterEvents, type NetworkEvent, type StatusFilter } from "./events";

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] as const;

export function createEventView(events: readonly NetworkEvent[], filter: StatusFilter) {
  const rows = filterEvents(events, filter);
  return { rows, visibleCount: events.length };
}

// Day, short month and 24-hour time in UTC, e.g. `21 Oct · 00:42`. The full
// ISO timestamp stays on the `<time>` element's `dateTime` attribute.
export function formatObservedAt(observedAt: string): string {
  const date = new Date(observedAt);
  const day = String(date.getUTCDate());
  const month = MONTHS[date.getUTCMonth()];
  const hours = String(date.getUTCHours()).padStart(2, "0");
  const minutes = String(date.getUTCMinutes()).padStart(2, "0");
  return `${day} ${month} · ${hours}:${minutes}`;
}
