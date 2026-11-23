import { statuses, type EventStatus } from "../lib/events";
import type { RegionHealth } from "../lib/region-health";

function StatusIcon({ status }: { status: EventStatus }) {
  if (status === "Healthy") {
    return <svg aria-hidden="true" width="20" height="20" viewBox="0 0 20 20" fill="none"><circle cx="10" cy="10" r="8.5" stroke="currentColor" strokeWidth="1.6"/><path d="M6.5 10.5l2.4 2.4 4.6-5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>;
  }
  if (status === "Degraded") {
    return <svg aria-hidden="true" width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M10 3.5L17.5 17h-15L10 3.5Z" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round"/><path d="M10 8.5v3.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/><circle cx="10" cy="14.5" r="1.1" fill="currentColor"/></svg>;
  }
  return <svg aria-hidden="true" width="20" height="20" viewBox="0 0 20 20" fill="none"><circle cx="10" cy="10" r="8.5" stroke="currentColor" strokeWidth="1.6"/><path d="M7 7l6 6M13 7l-6 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/></svg>;
}

export function RegionHealthMap({ regions }: { regions: readonly RegionHealth[] }) {
  return (
    <section className="health-map" aria-labelledby="health-map-heading">
      <h2 id="health-map-heading">Network health</h2>
      <ul className="region-list">
        {regions.map((region) => (
          <li key={region.region} className={`region-card region-${region.overall.toLowerCase()}`}>
            <h3 className="region-name">{region.region}</h3>
            <p className="region-status">
              <StatusIcon status={region.overall} />
              <span className="region-status-word">{region.overall}</span>
            </p>
            <p className="region-counts">
              {statuses.map((status) => (
                <span key={status} className={`region-count-${status.toLowerCase()}`}>
                  {region.counts[status]} {status.toLowerCase()}
                </span>
              ))}
            </p>
          </li>
        ))}
      </ul>
    </section>
  );
}
