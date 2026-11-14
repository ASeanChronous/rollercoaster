// Severe weather context from the National Weather Service (api.weather.gov).
// NWS data is US government work and free to use commercially. It explains
// *why* an area may be down; it never changes a service's status on its own.

import { getState } from "./geo";
import { USER_AGENT } from "./sources/types";
import { MINUTE } from "./time";

/** NWS event types that commonly knock out power, cable, fiber or cell service. */
const OUTAGE_EVENTS = new Set([
  "Tornado Warning",
  "Severe Thunderstorm Warning",
  "Hurricane Warning",
  "Typhoon Warning",
  "Tropical Storm Warning",
  "Storm Surge Warning",
  "Extreme Wind Warning",
  "High Wind Warning",
  "Blizzard Warning",
  "Ice Storm Warning",
  "Winter Storm Warning",
  "Flash Flood Warning",
  "Flood Warning",
  "Excessive Heat Warning",
  "Extreme Heat Warning",
  "Fire Warning",
  "Red Flag Warning",
  "Earthquake Warning",
  "Tsunami Warning",
]);

export interface WeatherAlert {
  id: string;
  event: string;
  severity: string;
  headline: string;
  areaDesc: string;
  states: string[];
  onset?: string;
  ends?: string;
  sender: string;
}

interface NwsFeature {
  id?: string;
  properties?: {
    id?: string;
    event?: string;
    severity?: string;
    headline?: string;
    areaDesc?: string;
    onset?: string;
    ends?: string | null;
    expires?: string;
    senderName?: string;
    geocode?: { UGC?: string[] };
  };
}

/** Keep outage-relevant alerts and work out which states each covers from its UGC zone codes. */
export function parseAlerts(body: { features?: NwsFeature[] }): WeatherAlert[] {
  const out: WeatherAlert[] = [];
  for (const f of body.features ?? []) {
    const p = f.properties;
    if (!p?.event || !OUTAGE_EVENTS.has(p.event)) continue;
    // UGC codes look like "TXC113" or "TXZ119": the first two letters are the state.
    const states = [...new Set((p.geocode?.UGC ?? []).map((c) => c.slice(0, 2)).filter((c) => getState(c)))];
    if (!states.length) continue; // marine or territory zones
    out.push({
      id: p.id ?? f.id ?? `${p.event}-${p.onset}`,
      event: p.event,
      severity: p.severity ?? "Unknown",
      headline: p.headline ?? p.event,
      areaDesc: p.areaDesc ?? "",
      states,
      onset: p.onset,
      ends: p.ends ?? p.expires,
      sender: p.senderName ?? "National Weather Service",
    });
  }
  return out;
}

const NWS = "https://api.weather.gov/alerts/active";
const TTL = 5 * MINUTE;

/** Caches NWS responses so page views don't each hit the API. */
export class WeatherAlerts {
  private national?: { at: number; alerts: WeatherAlert[] };
  private readonly points = new Map<string, { at: number; alerts: WeatherAlert[] }>();
  lastError?: string;

  constructor(private readonly enabled: boolean) {}

  /** Alerts touching a state. */
  async forState(state: string, now = Date.now()): Promise<WeatherAlert[]> {
    if (!this.enabled) return [];
    if (!this.national || now - this.national.at > TTL) {
      const alerts = await this.fetch(`${NWS}?status=actual&message_type=alert,update`);
      if (alerts) this.national = { at: now, alerts };
    }
    return (this.national?.alerts ?? []).filter((a) => a.states.includes(state));
  }

  /** Alerts covering a point (a ZIP centroid). */
  async forPoint(lat: number, lng: number, now = Date.now()): Promise<WeatherAlert[]> {
    if (!this.enabled) return [];
    const key = `${lat.toFixed(2)},${lng.toFixed(2)}`;
    const hit = this.points.get(key);
    if (hit && now - hit.at <= TTL) return hit.alerts;
    const alerts = await this.fetch(`${NWS}?status=actual&point=${key}`);
    if (!alerts) return hit?.alerts ?? [];
    this.points.set(key, { at: now, alerts });
    if (this.points.size > 5000) this.points.delete(this.points.keys().next().value!);
    return alerts;
  }

  private async fetch(url: string): Promise<WeatherAlert[] | undefined> {
    try {
      const res = await fetch(url, {
        headers: { Accept: "application/geo+json", "User-Agent": USER_AGENT },
        signal: AbortSignal.timeout(8_000),
      });
      if (!res.ok) throw new Error(`weather.gov returned ${res.status}`);
      this.lastError = undefined;
      return parseAlerts(await res.json());
    } catch (e) {
      // Weather is context only: show nothing rather than break the page.
      this.lastError = e instanceof Error ? e.message : String(e);
      return undefined;
    }
  }
}
