import { events, filterEvents, isStatusFilter } from "../../../lib/events";

export function GET(request: Request) {
  const filter = new URL(request.url).searchParams.get("status") ?? "All";
  if (!isStatusFilter(filter)) {
    return Response.json({ error: "Invalid status. Use All, Healthy, Degraded or Offline." }, { status: 400 });
  }
  const rows = filterEvents(events, filter);
  return Response.json({ schemaVersion: 1, synthetic: true, events: rows, count: rows.length, total: events.length });
}
