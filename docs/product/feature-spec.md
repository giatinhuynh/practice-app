# Status filtering: NetworkOps Lite

An operator needs to focus on events with a selected operational status. This is a fictional teaching example, not a representation of any real network or policy.

- **AC-01:** All displays 12 events. Healthy displays 6, Degraded 3 and Offline 3. Filtering preserves fixture order and all event fields.
- **AC-02:** The visible summary count equals the rendered event row count after every filter transition. All-events and per-status totals remain global.
- **AC-03:** Native buttons support Tab, Space and Enter, expose exactly one `aria-pressed=true`, and announce the selected result count. The skip link reaches the main content.
- **AC-04:** At 390px and 1440px widths, content fits without horizontal page scrolling. Mobile filter buttons have a minimum 44px height. Status has a text label as well as colour.
- **AC-05:** GET `/api/events` keeps the v1 contract documented in `docs/architecture/ADR-001.md`. Invalid status returns HTTP 400. The regression changes UI count derivation only.
- **AC-06:** Fixtures, screenshots and MCP tool responses contain synthetic data only. No runtime external requests, credentials, infrastructure integrations, analytics or remote fonts.
- **AC-07:** Functional, keyboard and automated accessibility checks pass. Review desktop/mobile screenshot differences in the pinned Linux browser environment. Human review assesses clarity and task usability.

Non-goals: real monitoring, incident remediation, authentication, persistent storage, live polling, automated deployment and a production-ready operations platform.
