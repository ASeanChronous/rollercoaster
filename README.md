# Rollercoaster

An outage aggregator for the US. It combines crowd reports with third-party outage trackers and official status pages, and turns them into one status per service: **No problems**, **Possible problems** or **Problems**. That status is worked out nationally, per state, and within 15 miles of a ZIP code.

The product spec is in [`docs/PRD.md`](docs/PRD.md). This codebase implements the MVP (Phase 1 / P0).

## Run it

```bash
npm install
npm run dev        # http://localhost:3000
npm test           # unit + engine tests
npm run lint       # type check
npm run build && npm start
```

Copy `.env.example` to `.env.local` to change settings. With the defaults the app runs in **demo mode**: it simulates crowd reports, outage incidents and the five licensed sources, so every feature works without data agreements. On startup it seeds a Spectrum outage in Dallas, a nationwide PlayStation Network outage, Verizon issues in New York and a power outage in Miami, plus 24 hours of history.

## What's built

| PRD feature | Where |
|---|---|
| Unified status model with baselines, multi-source fusion and confidence (§6.1) | `src/lib/detection.ts` |
| Service pages: 24-hour report curve, problem types, top locations, history, uptime, official updates and ETA (§6.2) | `/status/[slug]` |
| Live map with red dots (k-anonymous cells) and a state-by-state layer; filter by service, category and time window (§6.3) | `/map` |
| GPS detection, ZIP search, state selection (§6.4) | `src/components/LocationBar.tsx` |
| Overview by provider with outage counts and category filters; state dashboards (§6.5) | `/`, `/states`, `/states/[code]` |
| Alerts by ZIP and service: opened, escalated and resolved (with duration); browser and email (§6.6) | `/alerts`, `src/lib/alerts.ts` |
| Crowd reporting with rate limits, first-time down-weighting, burst detection and profanity masking (§6.7) | `src/lib/abuse.ts`, `/api/reports` |
| Troubleshooting tips per service, plus "it's probably not you" when an outage is confirmed nearby (§6.8) | `src/lib/services.ts` |
| Accessibility: status shown as icon + label, chart table view, dark mode, mobile layout (§6.15) | `src/app/globals.css` |
| Privacy: GPS → ZIP only, reports snapped to ~7-mile cells, map shows cells with 5+ reports (§8) | `src/lib/geo.ts`, `Engine.mapCells` |

### How detection works

Each tick (60 s by default) the engine polls the enabled sources, adds new crowd reports and recomputes every service, nationally and in every state. ZIP-level status is computed on request. A service is flagged when:

- **Crowd reports** are at least 2× (possible) or 5× (problems) the learned normal for that service, area and hour of the week. The count must also be statistically unlikely by chance (Poisson tail p < 10⁻⁴ / 10⁻⁷), so small services don't flicker.
- **One other source** flags it (possible), **two or more independent sources** agree (problems), or **the provider confirms** it (problems).
- A **nationwide signal** only colors a state or ZIP as "possible" until local reports rise too. A crowd spike packed into one small area can't turn a whole state red.

### Data sources

| Source | Adapter | Status |
|---|---|---|
| Downdetector, OutageNow, SpectrumOutage.org, FiberFinder, GeoBlackout | `src/lib/sources/licensed.ts` | Off until a data agreement supplies `SOURCE_<ID>_URL` and `_KEY`. Simulated in demo mode. |
| Official status pages (Atlassian Statuspage format: Discord, GitHub, Cloudflare, Zoom, Epic Games) | `src/lib/sources/statuspage.ts` | Real HTTP adapter. Turn on with `SOURCE_STATUSPAGES_ENABLED=true`. |
| Rollercoaster user reports | `/api/reports` | Live |

None of the five aggregators publish a public API, and scraping is against their terms. Each licensed feed is mapped into a neutral JSON contract (documented in `licensed.ts`), so adding a partner only means writing a field mapping.

### API

`GET /api/services?zip=|state=` · `GET /api/services/:slug?zip=|state=` · `POST /api/reports` · `GET /api/map?minutes=60|360|1440&service=&category=` · `GET /api/states` · `GET /api/geo?zip=` or `?lat=&lng=` · `POST|GET|DELETE /api/alerts` · `GET /api/stream` (server-sent events) · `GET /api/sources`

## Deploy (Fly.io)

The app has to run as **one long-running server**. The engine keeps its data in memory and recomputes on a timer, and browsers hold a live connection for updates. Serverless hosts (Vercel, Netlify) won't work. `fly.toml` keeps exactly one machine always on.

1. Install the Fly CLI and sign in:
   ```bash
   curl -L https://fly.io/install.sh | sh    # macOS: brew install flyctl
   fly auth signup                           # or: fly auth login
   ```
2. In `fly.toml`, change `app = "rollercoaster-outages"` to a unique name. `primary_region = "dfw"` (Dallas) is a reasonable central-US default.
3. Create the app and deploy it as a single machine:
   ```bash
   fly apps create <your-app-name>
   fly deploy --ha=false
   ```
   `--ha=false` matters: by default Fly starts two machines, and each would show different data. If you ever end up with two, run `fly scale count 1`.
4. Open it with `fly open`. It's served at `https://<your-app-name>.fly.dev`. Check `/api/health` and `fly logs` if something looks wrong.
5. **Custom domain (optional):** `fly certs add www.example.com`, then add the DNS records it prints at your domain registrar.
6. **Map tiles (do this before sharing publicly):** OpenStreetMap's free tile server forbids heavy traffic. Create a free key at a tile provider such as [MapTiler](https://www.maptiler.com/cloud/), restrict it to your domain, uncomment `[build.args]` in `fly.toml` with your key, and run `fly deploy --ha=false` again.

**Cost:** one `shared-cpu-1x` machine with 512 MB, which costs a few dollars a month (see [fly.io/pricing](https://fly.io/pricing)). The app uses about 230 MB.

**Settings** go in `[env]` in `fly.toml`. Secrets, such as data-feed keys once you have agreements, go in with `fly secrets set SOURCE_DOWNDETECTOR_URL=... SOURCE_DOWNDETECTOR_KEY=...`. Keep `DEMO_MODE = "true"` until real feeds are connected, so the "simulated" banner stays up.

**Restarts reset data.** Each deploy or restart wipes reports, alerts and learned baselines (demo mode refills 24 hours of simulated history on boot). Moving storage to a database fixes this, and also allows more than one machine.

To build and run the same image locally: `docker build -t rollercoaster . && docker run -p 3000:3000 rollercoaster`.

## Not production-ready yet

- **Storage is in memory.** Reports, alerts and learned baselines are lost when the server restarts, and it runs as a single process. The next step is Postgres/PostGIS plus a time-series store, as in PRD §9. The `Store` class is the seam.
- **Email is logged, not sent.** `ConsoleEmailTransport` needs a real provider (SES, Postmark, etc.) behind the `EmailTransport` interface.
- **Browser alerts only arrive while a tab is open.** Background Web Push needs a service worker and VAPID keys.
- **No accounts.** Alert subscriptions are managed with a secret token kept in the browser.
- **Map tiles** default to the public OpenStreetMap tile server, which doesn't allow heavy production traffic. Set `NEXT_PUBLIC_MAP_TILE_URL` (see Deploy) before launch.
- **Detection thresholds** are starting values. Backtest them against real outage data before launch.
- P1/P2 features (SMS, ISP-vs-service diagnosis, credit helper, backup ISP suggestions, power/weather overlays, reliability scores, widgets) aren't built yet.
