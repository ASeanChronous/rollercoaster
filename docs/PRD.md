# PRD: Outage Aggregator (working name: "Rollercoaster")

| | |
|---|---|
| **Status** | Draft v0.1 |
| **Owner** | Sean (Traders Edge Group) |
| **Last updated** | 2026-10-12 (v0.2: GeoBlackout identified) |
| **Type** | Consumer web app (responsive), with mobile apps later |

---

## 1. Summary

Rollercoaster is a single place to answer "Is it just me, or is it down?" for internet, mobile, streaming, gaming, banking, and power services in the United States. It pulls outage signals from several third-party outage trackers, official provider status pages, and its own users, then normalizes them into one consistent status model, map, and alert system.

Today a user checking an outage has to bounce between SpectrumOutage.org, OutageNow, FiberFinder, GeoBlackout USA, and Downdetector. Each covers different providers, uses different status language, and has different geographic precision. Rollercoaster merges them, shows where the sources agree or disagree, and notifies users about outages that affect *their* address and *their* providers.

## 2. Problem

- **Fragmented signal.** No single tracker covers every provider and region well. Users have to check several.
- **Inconsistent language.** "Possible problems," "partial outage," and "12 reports in the last hour" mean different things on different sites.
- **Low precision.** Most trackers work at city or state level. Users care about their street.
- **Reactive only.** Users find out about outages by noticing them. Few tools push personalized alerts.
- **No next step.** When something is down, users want an ETA, a workaround (hotspot, backup ISP), and a way to request a bill credit. Most trackers stop at "it's down."

## 3. Goals and non-goals

### Goals
1. One normalized status for every tracked service, at national, state, ZIP, and address level.
2. Detect outages fast: within 5 minutes of a meaningful spike in any source.
3. Personalized push, SMS, and email alerts for a user's saved locations and providers.
4. Let users report outages in under 10 seconds, and use those reports as a first-class signal.
5. Help users act during an outage: troubleshooting, ETAs, backup options, credit requests.

### Non-goals (v1)
- Running our own network probes or hardware (we may revisit in v3, see §9).
- Coverage outside the US.
- Enterprise or NOC-grade SLA monitoring. That is a possible paid tier later, not v1.
- Fixing outages or acting on a user's behalf with their provider.

## 4. Target users

| Persona | Need | Key features |
|---|---|---|
| **Home user** ("Is my Spectrum down?") | Quick confirmation and an ETA | GPS/ZIP lookup, status badge, troubleshooting, ETA |
| **Remote worker** | Know before a meeting, and have a fallback | Address alerts, backup-ISP suggestions, uptime history |
| **Gamer / streamer** | Is it my ISP or the platform? | Category filters, platform pages, "ISP vs. service" view |
| **Small business owner** | Card readers, VoIP, and POS depend on internet | Multi-location watchlists, SMS alerts, outage history for credit claims |
| **Shopper comparing ISPs** | Which provider is most reliable here? | Reliability scores by ZIP, availability (FiberFinder-style) |
| **Local journalist / civic user** | What's down in my region right now? | State and region dashboards, embeddable widgets, public API |

## 5. Data sources

### 5.1 Sources named in the request

| Source | What it contributes | Notes |
|---|---|---|
| **Downdetector** | Crowd-report volume and baselines across thousands of services; three-level status | Owned by Ookla. Has an enterprise data/API product. Needs a commercial license. Scraping is against its terms. |
| **SpectrumOutage.org** | Spectrum-specific outage reports and areas | Unofficial third-party site. Check its terms and contact the owner about a data agreement. |
| **OutageNow** | Address-level reports, live map, reporting curves, coverage of 322 networks | Ask about a partner feed. |
| **FiberFinder.ai** | Provider overview, outage counts, regional reports, category filters; ISP availability by address | Availability data also powers the "backup ISP" feature. |
| **GeoBlackout** ([geoblackout.com/us](https://geoblackout.com/us)) | Crowdsourced **internet and power** outage map with street-level precision, refreshed every minute; red-dot map, ZIP search, state-by-state status, troubleshooting | Founded 2024; covers ~20 countries (US first for us). Sells **GeoBlackout Pro** to telecom operators, which is the natural route to a data license. Its power data also feeds the power overlay (§6.3). |

> **Legal gate (blocking).** None of these sources should be scraped without written permission. Every source needs a license, a partner agreement, or an approved public API before launch. Each source integration lives behind its own adapter and a feature flag so we can turn it off quickly if terms change. Display attribution ("Data from Downdetector, OutageNow, …") wherever the terms require it.

### 5.2 Additional sources (recommended)

These reduce dependence on licensed third-party aggregators and improve accuracy:

- **Official provider status pages and social accounts:** Comcast/Xfinity, Spectrum, AT&T, Verizon, T-Mobile, Cox, and others. Many expose RSS, JSON, or Statuspage APIs.
- **Platform status pages:** AWS, Azure, GCP, Cloudflare, PlayStation Network, Xbox Live, Steam, Netflix, and major banks.
- **Internet measurement:** Cloudflare Radar (traffic anomalies and outage annotations), IODA from Georgia Tech (BGP, active probing, telescope signals), and RIPE Atlas.
- **Power:** utility outage feeds and PowerOutage.us (licensed). Power outages often cause the internet outages users are seeing.
- **Weather and emergencies:** NWS alerts and FEMA/IPAWS, to explain *why* an area is down.
- **FCC:** the Disaster Information Reporting System (DIRS), when activated, and the Broadband Data Collection for coverage.
- **Our own users:** crowd reports from Rollercoaster (§6.7).

## 6. Features

Priority key: **P0** = MVP launch, **P1** = fast follow (≤ 3 months after launch), **P2** = later.

### 6.1 Unified status model (P0)
The core of the product. Every service in every geography gets one normalized status:

| Status | Label | Default trigger |
|---|---|---|
| 🟢 | **No problems** | Report volume within the normal range and no official incident |
| 🟡 | **Possible problems** | Volume ≥ 2× the baseline for that hour and weekday, **or** one source flags an issue |
| 🔴 | **Problems** | Volume ≥ 5× the baseline, **or** two or more independent sources agree, **or** the provider has confirmed an incident |

- The baseline is computed per service, geography, hour-of-week, and source, so normal evening traffic doesn't trigger alerts.
- Each status shows a **confidence score** and the **sources behind it** ("3 of 4 sources report issues; Spectrum confirmed at 2:14 PM").
- When sources disagree, the page says so instead of hiding it.
- The thresholds above are starting points to tune against historical data before launch.

### 6.2 Service-specific pages (P0)
One page per provider or platform (for example `/status/spectrum`), with:
- The current status badge and a plain-language summary
- A **real-time report curve** (last 24 hours, with the baseline band shaded)
- A breakdown of reported problem types (no internet, slow, TV, phone, login, and so on)
- The most-affected cities, ZIPs, and states
- Official provider statements, and an ETA when the provider gives one
- Outage history and an uptime percentage (7, 30, and 90 days)
- Troubleshooting steps specific to that service
- A "Report a problem" button

### 6.3 Live outage map (P0)
- National map with **red dots** for reported outages, clustered at low zoom and showing individual dots at high zoom.
- Heatmap layer for report density.
- Filter by provider, category, status, and time window (1 hour, 6 hours, 24 hours).
- A **state-by-state** choropleth view that drills down to county, then ZIP.
- Optional overlay layers: power outages, severe weather alerts.
- Dots and heat are aggregated (§8). We never show a pin at a user's exact home.

### 6.4 Location: GPS, ZIP, address, and state (P0)
- **GPS detection**, used only after the user opts in, with ZIP entry as the fallback.
- **ZIP code search** and **address search** (geocoded) for address-level precision.
- **State selector** that opens a state dashboard: top affected providers, active outages, and trends.
- Users can save multiple locations (home, office, parents' house).

### 6.5 Provider and category overview (P0)
- A home dashboard with **live outage counts by provider**, sorted by current severity.
- **Category filters:** Internet/ISP, Mobile, TV/Cable, Streaming, Gaming, Banking & Payments, Cloud & Dev, Social, Power.
- **Region reports:** "Top outages in Texas right now," "Northeast summary."
- **Coverage:** at least 322 networks at launch (matching OutageNow), growing to over 1,000 services including platforms.

### 6.6 Notifications and alerts (P0 core, P1 advanced)
The app's main reason for repeat visits.
- **P0:** Users follow providers and locations. They get an alert when status turns 🟡 or 🔴 near a saved location, and again when it returns to 🟢. Channels: web push and email.
- **P1:** SMS and native mobile push. Quiet hours. Choice of severity threshold. A daily digest option.
- **P1:** "Resolved" alerts with the outage duration, ready to use in a credit request (§6.10).
- Alerts are rate-limited and deduplicated. One incident produces one alert thread, not a stream of messages.

### 6.7 Crowd-sourced reporting (P0)
- One-tap "I'm having problems" with an optional problem type and a short comment.
- Reports are tied to an approximate location (GPS or ZIP) and a provider. We auto-suggest the user's ISP from their IP address, and they confirm it.
- **Anti-abuse:** rate limits per device and IP, bot detection, anomaly checks (for example, sudden reports from one network block), and lower weight for unverified first-time reporters.
- Comment feed per outage, with moderation and profanity filtering.
- "Me too" confirmation on existing reports. This adds signal without creating duplicates.

### 6.8 Troubleshooting assistant (P0 static, P1 guided)
- **P0:** Static, provider-specific checklists: restart modem/router, check for lights, run a speed test, check the provider's app.
- **P1:** Guided flow that branches on "is the outage confirmed in your area?" If yes: "It's not you. Here's the ETA." If no: "Try these steps." Can include a built-in speed test.

### 6.9 "Is it my ISP or the service?" diagnosis (P1)
When a user reports a gaming or streaming problem, we cross-check the ISP status for their area against the platform's status and tell them where the problem most likely is. This handles the most common confusion users have.

### 6.10 Outage credit helper (P1)
Uses alert history to generate a dated outage log, plus provider-specific instructions or a template for requesting a bill credit.

### 6.11 Backup connectivity suggestions (P1)
During a confirmed 🔴 outage, show alternatives available at the user's address (mobile hotspot, 5G home internet, other ISPs), using FiberFinder-style availability data. This is also a possible affiliate revenue source (§11).

### 6.12 Reliability scores and ISP comparison (P2)
Historical uptime, outage frequency, and mean time to restore for each provider in each ZIP. "Most reliable ISP in 78701." Useful for shoppers and good for SEO.

### 6.13 Predictive and scheduled outages (P2)
- Show scheduled maintenance windows when providers publish them.
- Warn ahead of severe weather that outages are likely in the user's area.

### 6.14 Embeddable widgets and public API (P2)
- Status badges and mini-maps that local news sites and blogs can embed.
- A rate-limited public API, with a paid tier for businesses (§11).

### 6.15 Accessibility and offline-friendly design (P0)
- WCAG 2.2 AA. Status is never shown by color alone: every badge has an icon and a label.
- A lightweight page that loads on a phone with only a weak cellular signal. This matters because users often check outages over cellular when their home internet is down.
- SMS alerts (P1) reach users who have no data at all.

## 7. Key user flows

1. **"Is it down?"** Land on the home page → GPS or ZIP detects location → see status for the user's likely ISP and the top outages nearby → tap through to the service page → confirm → report or follow.
2. **Set up alerts.** Create an account (email or OAuth) → add a location → choose providers → choose channels → done in under 60 seconds.
3. **Report.** Tap "Report" → confirm provider and location → pick a problem type (optional) → submit → see "You and 214 others nearby are reporting problems."
4. **Outage resolved.** Get a resolution alert with the duration → optionally open the credit helper.

## 8. Privacy, trust, and compliance

- **Location minimization.** Store the reported location rounded to a grid cell or ZIP. Raw GPS is used only in the moment and is not retained. Saved addresses are encrypted at rest.
- **k-anonymity on the map.** Only show an aggregated dot or cell once it contains at least N reports (N = 5 to start).
- Comply with **CCPA/CPRA** and other state privacy laws. Provide a clear privacy policy, data export, and account deletion.
- Follow **TCPA** rules for SMS: explicit opt-in, STOP handling, and quiet hours.
- **Source attribution and licensing** per §5. Keep a record of which source contributed to each status.
- Clear disclaimer: Rollercoaster is independent and not affiliated with any provider unless a partnership says otherwise.

## 9. System architecture (high level)

```
 Sources ──► Ingestion adapters ──► Normalizer ──► Event stream ──► Detection engine ──► Status store
 (licensed feeds,   (one per source,    (service IDs,   (e.g. Kafka /     (baselines, spikes,   (current +
  status pages,      flagged, retries)   geo → H3/ZIP,   Redis Streams)    source fusion,        history)
  user reports)                          problem types)                    confidence)              │
                                                                                                    ▼
                                                     Notification service ◄── Status change events ─┤
                                                     (push, email, SMS)                             │
                                                                                                    ▼
                                                                         API (REST + WebSocket/SSE) ──► Web / mobile apps
```

- **Geo indexing:** H3 hexagons plus a ZIP/county/state lookup, so any level of the map can be queried quickly.
- **Real time:** WebSocket or SSE pushes status changes and map updates to open clients.
- **Storage:** Postgres + PostGIS for entities and geography, a time-series store (TimescaleDB or ClickHouse) for report volume and curves, and Redis for hot status.
- **Map:** Mapbox GL or MapLibre with vector tiles.
- **Frontend:** Next.js (SSR/ISR so service and state pages rank well in search), mobile-first, PWA for push.
- **Service registry:** a canonical list of services and providers, with aliases so the same company from different sources maps to one entry ("Charter" = "Spectrum").
- **Resilience:** if one source goes down, the status still works from the rest. A stale source decays out of the confidence calculation.

## 10. Success metrics

| Metric | Target (6 months post-launch) |
|---|---|
| Detection latency (spike → 🟡/🔴) | p50 < 3 min, p95 < 5 min |
| Precision of 🔴 status (later confirmed by provider or ≥ 2 sources) | ≥ 90% |
| Alert-to-resolution accuracy (users who mark an alert "helpful") | ≥ 80% |
| Monthly active users | 250k |
| Users with ≥ 1 saved alert | 20% of MAU |
| D30 retention of alert subscribers | ≥ 40% |
| Crowd reports per day | 10k+ |
| Page load (LCP) on 3G | < 2.5 s |

## 11. Monetization options

1. **Display ads** on high-traffic status pages. This is the industry norm; keep them away from the status badge.
2. **Affiliate referrals** for backup connectivity and ISP switching (§6.11, §6.12).
3. **Premium tier** (~$3–5/month): SMS alerts, unlimited locations, ad-free, full history export.
4. **Business tier:** multi-location monitoring, a team alert channel (Slack/Teams/webhooks), and API access.
5. **Data licensing** (P2), once our own crowd-report volume is large enough.

## 12. Release plan

| Phase | Scope |
|---|---|
| **0 – Foundations (weeks 0–4)** | Source licensing conversations, service registry, ingestion for official status pages, Cloudflare Radar, and IODA. Legal review. |
| **1 – MVP (weeks 5–12)** | §6.1–6.8 P0 items, with at least 2 licensed aggregator feeds plus our own reports. Web only. Push and email alerts. |
| **2 – Fast follow (months 4–6)** | SMS, native apps, ISP-vs-service diagnosis, credit helper, backup suggestions, guided troubleshooting, power and weather overlays. |
| **3 – Scale (months 7–12)** | Reliability scores, widgets and public API, business tier, predictive alerts. |

## 13. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Source owners refuse to license data or change their terms | Treat licensed aggregators as one input among several. Invest early in official status pages, measurement data (Radar/IODA), and our own crowd reports. |
| False alarms damage trust | Baselines, multi-source fusion, confidence scores, and visible "why" explanations. Tune with backtesting. |
| Brigading or fake reports | Rate limits, device reputation, anomaly detection, and reweighting. Never let crowd reports alone trigger 🔴 for a whole state. |
| Trademark issues from using provider names and logos | Use names in a factual, descriptive way. Get a legal review of logo use and the "Spectrum outage" SEO pages. |
| Traffic spikes during major outages (exactly when we're needed) | CDN-cached status pages, a static fallback page, and load-tested autoscaling sized for 50× normal traffic. |
| Location privacy | Minimization, k-anonymity, and encryption (§8). |

## 14. Open questions

1. Does GeoBlackout Pro include a data feed or API we can license, and on what terms?
2. Which source is the "322 networks" figure from? Do we want our launch catalog to match it exactly?
3. Is power-outage coverage in scope for MVP, or only as a P1 overlay?
4. Product name and brand. Is "Rollercoaster" final, or a codename?
5. Is there a budget for licensing Downdetector enterprise data, or do we launch without it?
6. Accounts: require sign-up for reporting, or allow anonymous reports with lower weight?

---

## Appendix A: Feature-to-request mapping

| Requested feature | PRD section |
|---|---|
| Live status updates, outage maps, service-specific pages | §6.1, §6.2, §6.3 |
| "No problems / Possible problems / Problems" by report volume | §6.1 |
| Address-level precision | §6.4 |
| Real-time reporting curves | §6.2 |
| Monitoring of 322 networks | §6.5 |
| Live overview by provider, outage counts, region reports | §6.5 |
| Category filters (banking, gaming, streaming) | §6.5 |
| Red dots for reported outages | §6.3 |
| ZIP code search | §6.4 |
| Troubleshooting tips | §6.8 |
| State-by-state status | §6.3, §6.4 |
| GPS-based location detection, state selection | §6.4 |
| Crowd-sourced reporting | §6.7 |
| Notifications about outages | §6.6 |

## Appendix B: Features added beyond the request

Personalized multi-location alerts with resolution notices · confidence scores and source transparency · ISP-vs-service diagnosis · outage credit helper · backup connectivity suggestions · power and weather overlays · reliability scores and ISP comparison · scheduled maintenance and predictive warnings · embeddable widgets and public API · design for weak connections and SMS · privacy-preserving map aggregation · business multi-location tier.
