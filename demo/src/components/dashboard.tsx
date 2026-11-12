"use client";

import { useState } from "react";
import { createEventView, formatObservedAt } from "../lib/event-view";
import { statuses, statusTotals, type NetworkEvent, type StatusFilter } from "../lib/events";

function NetworkMark() {
  return <svg aria-hidden="true" width="28" height="28" viewBox="0 0 28 28" fill="none"><path d="M7 7L21 14L7 21V7Z" stroke="currentColor" strokeWidth="1.6"/><circle cx="7" cy="7" r="3" fill="currentColor"/><circle cx="21" cy="14" r="3" fill="currentColor"/><circle cx="7" cy="21" r="3" fill="currentColor"/></svg>;
}

export function Dashboard({ events }: { events: readonly NetworkEvent[] }) {
  const [filter, setFilter] = useState<StatusFilter>("All");
  const view = createEventView(events, filter);
  const totals = statusTotals(events);

  return <>
    <a className="skip-link" href="#main">Skip to event overview</a>
    <aside className="sidebar" aria-label="Workshop identity">
      <div className="product-brand"><NetworkMark /><span>NetworkOps<span className="lite">LITE</span></span></div>
      <div className="sidebar-label">OPERATIONS WORKSPACE</div>
      <a className="nav-item" href="#main" aria-current="page"><span aria-hidden="true">▦</span> Event overview <span className="nav-dot" /></a>
      <div className="sidebar-caption">A clearer view.<br />A verifiable change.</div>
      <div className="sidebar-bottom"><div className="brand-lockup"><b className="rmit">RMIT</b><div><b>Agentic SDLC</b><small>WORKSHOP EDITION</small></div></div><p>Practice app<br />Synthetic data only</p><span className="sidebar-note">Typographic brand placeholders</span></div>
    </aside>
    <div className="workspace">
      <header className="topbar"><div className="breadcrumb">Operations <span>/</span> <strong>Event overview</strong></div><div className="environment"><span className="environment-dot" /> Synthetic environment</div></header>
      <main id="main" tabIndex={-1}>
        <div className="page-heading"><div><p className="eyebrow">NETWORK ASSURANCE / WORKSHOP</p><h1>Event overview<span className="heading-dot">.</span></h1><p className="intro">Explore network events. Focus on what needs attention.</p></div><div className="snapshot"><span className="snapshot-label">FIXED DATA SNAPSHOT</span><strong>21 Oct 2026 · 00:42 UTC</strong></div></div>
        <div className="synthetic-banner"><span className="banner-icon" aria-hidden="true">i</span><p><strong>Built for learning.</strong> All assets and events are fictional. No live network connection.</p><span className="sample-tag">SYNTHETIC DATA</span></div>
        <section className="metrics" aria-label="Event summary">
          <div className="metric metric-primary"><div className="metric-label">Visible events <span aria-hidden="true">↗</span></div><div className="metric-number" data-testid="visible-count">{view.visibleCount}</div><div className="metric-description" role="status" aria-live="polite" aria-atomic="true">{view.visibleCount} {filter === "All" ? "events across all statuses" : `${filter.toLowerCase()} events in view`}</div></div>
          {statuses.map((status) => <div className={`metric metric-${status.toLowerCase()}`} key={status}><div className="metric-label"><span className={`status-dot ${status.toLowerCase()}`} />{status}</div><div className="metric-number">{totals[status]}</div><div className="metric-description">{status === "Healthy" ? "Operating normally" : status === "Degraded" ? "Requires attention" : "Connection unavailable"}<span className="metric-percent">{Math.round(totals[status] / events.length * 100)}%</span></div></div>)}
        </section>
        <section className="events-panel" aria-labelledby="events-heading">
          <div className="panel-heading"><div><h2 id="events-heading">Network events <span className="total-badge">{events.length} total</span></h2><p>Filter the event list by operational status.</p></div><span className="read-only"><span aria-hidden="true">◈</span> Read-only snapshot</span></div>
          <div className="filter-toolbar"><div className="filter-group" role="group" aria-label="Filter events by status">{(["All", ...statuses] as const).map((status) => <button key={status} type="button" aria-pressed={filter === status} onClick={() => setFilter(status)}>{status !== "All" && <span aria-hidden="true" className={`status-dot ${status.toLowerCase()}`} />}{status}<span className="filter-count" aria-hidden="true">{status === "All" ? events.length : totals[status]}</span></button>)}</div><span className="result-label">{view.rows.length} of {events.length} events</span></div>
          <table className="event-table"><caption className="sr-only">Synthetic network events, {filter.toLowerCase()} status</caption><thead><tr><th scope="col">Asset / Event ID</th><th scope="col">Region</th><th scope="col">Status</th><th scope="col">Signal</th><th scope="col">Observed (UTC)</th></tr></thead><tbody>{view.rows.map((event) => <tr key={event.id} data-testid="event-row"><th scope="row"><span className="asset-icon" aria-hidden="true">▥</span><span><span className="asset-name">{event.asset}</span><span className="event-id">{event.id}</span></span></th><td data-label="Region">{event.region}</td><td data-label="Status"><span className={`status-badge ${event.status.toLowerCase()}`}><span className="status-dot" />{event.status}</span></td><td data-label="Signal">{event.signal}</td><td data-label="Observed (UTC)" className="observed"><time dateTime={event.observedAt}>{formatObservedAt(event.observedAt)}</time></td></tr>)}</tbody></table>
          <div className="panel-footer"><span>Showing {view.rows.length} of {events.length} synthetic events</span><span>All times UTC · Fixed workshop fixture</span></div>
        </section>
        <footer className="page-footer"><span>NetworkOps Lite <span className="footer-separator">/</span> Agentic SDLC workshop</span><span>Fictional environment · No customer data</span></footer>
      </main>
    </div>
  </>;
}
