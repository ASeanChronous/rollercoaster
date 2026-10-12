// Adapters for the licensed third-party aggregators named in PRD §5.1.
//
// None of these sites publish a public API, and their terms forbid scraping,
// so each adapter only runs once a data agreement supplies a feed URL and key.
// Every partner feed is expected to be translated into the neutral JSON
// contract below; per-partner mapping goes in `mapRow` when terms are signed.

import { getService, resolveService } from "../services";
import type { SourceSignal, StatusLevel } from "../types";
import type { Env, SourceAdapter, SourceInfo } from "./types";

export const LICENSED_SOURCES: SourceInfo[] = [
  {
    id: "downdetector",
    name: "Downdetector",
    url: "https://downdetector.com",
    attribution: "Outage data from Downdetector® by Ookla®",
    categories: [],
    kind: "aggregator",
  },
  {
    id: "outagenow",
    name: "OutageNow",
    url: "https://outagenow.com",
    attribution: "Data from OutageNow",
    categories: ["isp", "mobile", "tv", "power"],
    kind: "aggregator",
  },
  {
    id: "spectrumoutage",
    name: "SpectrumOutage.org",
    url: "https://spectrumoutage.org",
    attribution: "Data from SpectrumOutage.org",
    categories: ["isp"],
    serviceSlugs: ["spectrum"],
    kind: "aggregator",
  },
  {
    id: "fiberfinder",
    name: "FiberFinder",
    url: "https://fiberfinder.ai",
    attribution: "Data from FiberFinder.ai",
    categories: ["isp", "mobile", "streaming", "gaming", "banking"],
    kind: "aggregator",
  },
  {
    id: "geoblackout",
    name: "GeoBlackout",
    url: "https://geoblackout.com/us",
    attribution: "Data from GeoBlackout",
    categories: ["isp", "power"],
    kind: "aggregator",
  },
];

/**
 * Neutral feed contract every licensed source is mapped into:
 * { "signals": [ { "provider": "Charter", "state": "TX", "zip": "78701",
 *   "reports": 140, "status": "problems", "official": false,
 *   "message": "...", "eta": "2026-10-12T20:00:00Z", "lat": 30.2, "lng": -97.7 } ] }
 */
interface FeedRow {
  provider: string;
  state?: string;
  zip?: string;
  reports?: number;
  status?: string;
  official?: boolean;
  message?: string;
  eta?: string;
  lat?: number;
  lng?: number;
}

const STATUS_MAP: Record<string, StatusLevel> = {
  ok: "ok", none: "ok", up: "ok", "no problems": "ok",
  possible: "possible", minor: "possible", degraded: "possible", warning: "possible", "possible problems": "possible",
  problems: "problems", major: "problems", critical: "problems", down: "problems", outage: "problems",
};

export function mapRow(sourceId: string, row: FeedRow, now: number): SourceSignal | undefined {
  const service = resolveService(row.provider);
  if (!service) return undefined;
  const level = row.status ? STATUS_MAP[row.status.toLowerCase()] : undefined;
  const eta = row.eta ? Date.parse(row.eta) : NaN;
  return {
    sourceId,
    serviceSlug: service.slug,
    observedAt: now,
    reportCount: typeof row.reports === "number" ? row.reports : undefined,
    level,
    official: Boolean(row.official),
    message: row.message?.slice(0, 280),
    etaAt: Number.isFinite(eta) ? eta : undefined,
    scope: { state: row.state?.toUpperCase(), zip: row.zip },
    lat: row.lat,
    lng: row.lng,
  };
}

export function licensedAdapter(info: SourceInfo, env: Env = process.env): SourceAdapter {
  const prefix = `SOURCE_${info.id.toUpperCase()}`;
  const url = env[`${prefix}_URL`];
  const key = env[`${prefix}_KEY`];
  const enabled = Boolean(url && key);
  return {
    info,
    enabled,
    disabledReason: enabled ? undefined : `Waiting on a data agreement (set ${prefix}_URL and ${prefix}_KEY).`,
    async poll(now) {
      if (!url || !key) return [];
      const res = await fetch(url, { headers: { Authorization: `Bearer ${key}` }, signal: AbortSignal.timeout(10_000) });
      if (!res.ok) throw new Error(`${info.name} feed returned ${res.status}`);
      const body = (await res.json()) as { signals?: FeedRow[] };
      return (body.signals ?? [])
        .map((row) => mapRow(info.id, row, now))
        .filter((s): s is SourceSignal => Boolean(s && getService(s.serviceSlug)));
    },
  };
}
