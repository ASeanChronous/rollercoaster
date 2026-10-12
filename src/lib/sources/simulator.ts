// Demo-mode simulator. Generates realistic background crowd reports and
// outage incidents, and plays the part of each licensed source, so the whole
// pipeline (ingest → detect → alert → UI) runs without any data agreements.
// Turn off with DEMO_MODE=false.

import { getState, lookupZip, nearbyZips, stateShare, STATES, toCell, zipsInState } from "../geo";
import { hourOfWeekFactor } from "../detection";
import { getService, SERVICES } from "../services";
import { localHourAndDay, MINUTE, HOUR } from "../time";
import type { CrowdReport, ProblemType, Service, SourceSignal, StatusLevel } from "../types";
import { LICENSED_SOURCES } from "./licensed";
import { covers } from "./types";

export interface Incident {
  id: string;
  slug: string;
  /** Undefined = nationwide. */
  state?: string;
  /** ZIPs the incident affects; empty = whole state (or nation). */
  zips: string[];
  /** Center of a local incident; sources report it at this ZIP. */
  centerZip?: string;
  areaLabel: string;
  start: number;
  end: number;
  /** Extra crowd reports per hour at full intensity. */
  ratePerHour: number;
  problem: ProblemType;
  /** Licensed sources that pick this incident up, with their detection lag. */
  seenBy: { sourceId: string; lagMs: number }[];
  officialAt?: number;
  officialMessage?: string;
  etaAt?: number;
}

/** Deterministic PRNG (mulberry32) so demos are reproducible. */
export function rng(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function poisson(lambda: number, rand: () => number): number {
  if (lambda <= 0) return 0;
  if (lambda > 30) return Math.max(0, Math.round(lambda + Math.sqrt(lambda) * gauss(rand)));
  const l = Math.exp(-lambda);
  let k = 0;
  let p = 1;
  do {
    k++;
    p *= rand();
  } while (p > l);
  return k - 1;
}

function gauss(rand: () => number): number {
  return Math.sqrt(-2 * Math.log(rand() || 1e-9)) * Math.cos(2 * Math.PI * rand());
}

/** 0–1 intensity: ramps up over 10 min, decays over the last 20% of the incident. */
export function intensity(inc: Incident, t: number): number {
  if (t < inc.start || t >= inc.end) return 0;
  const up = Math.min(1, (t - inc.start) / (10 * MINUTE));
  const tail = (inc.end - inc.start) * 0.2;
  const down = Math.min(1, (inc.end - t) / tail);
  return Math.max(0, Math.min(up, down));
}

export class Simulator {
  readonly incidents: Incident[] = [];
  private readonly rand: () => number;
  private readonly stateWeights = new Map<string, { codes: string[]; cum: number[] }>();
  private seq = 0;

  constructor(seed = 20261012) {
    this.rand = rng(seed);
  }

  /** Scripted incidents so a fresh demo has something to show right away. */
  seedIncidents(now: number): void {
    const all = (ids: string[], lag = 3) => ids.map((sourceId, i) => ({ sourceId, lagMs: (lag + i * 2) * MINUTE }));
    this.addIncident({
      slug: "spectrum", state: "TX", zips: nearbyZips("75201"), centerZip: "75201", areaLabel: "Dallas–Fort Worth, TX",
      start: now - 35 * MINUTE, end: now + 2 * HOUR, ratePerHour: 140, problem: "no_connection",
      seenBy: all(["spectrumoutage", "downdetector", "outagenow", "geoblackout", "fiberfinder"]),
      officialAt: now - 20 * MINUTE, etaAt: now + 2 * HOUR,
      officialMessage: "Technicians are working to restore internet service in parts of the Dallas–Fort Worth area.",
    });
    this.addIncident({
      slug: "psn", zips: [], areaLabel: "Nationwide",
      start: now - 14 * MINUTE, end: now + 50 * MINUTE, ratePerHour: 420, problem: "login",
      seenBy: all(["downdetector", "fiberfinder"], 2),
    });
    this.addIncident({
      slug: "verizon-wireless", state: "NY", zips: nearbyZips("10001"), centerZip: "10001", areaLabel: "New York, NY",
      start: now - 7 * MINUTE, end: now + 40 * MINUTE, ratePerHour: 30, problem: "phone",
      seenBy: all(["outagenow"], 4),
    });
    this.addIncident({
      slug: "power-grid", state: "FL", zips: nearbyZips("33101"), centerZip: "33101", areaLabel: "Miami, FL",
      start: now - 50 * MINUTE, end: now + 3 * HOUR, ratePerHour: 90, problem: "power",
      seenBy: all(["outagenow", "geoblackout"]),
    });
    // Resolved incidents earlier today, so history and curves have shape.
    this.addIncident({
      slug: "xfinity", state: "IL", zips: [], areaLabel: "Illinois",
      start: now - 9 * HOUR, end: now - 7 * HOUR, ratePerHour: 220, problem: "slow",
      seenBy: all(["downdetector", "outagenow", "fiberfinder"]),
      officialAt: now - 8.6 * HOUR, officialMessage: "A fiber cut affected service in the Chicago area. Service has been restored.",
    });
    this.addIncident({
      slug: "netflix", zips: [], areaLabel: "Nationwide",
      start: now - 18 * HOUR, end: now - 17.3 * HOUR, ratePerHour: 600, problem: "app",
      seenBy: all(["downdetector", "fiberfinder"], 2),
    });
  }

  addIncident(inc: Omit<Incident, "id">): Incident {
    const full = { ...inc, id: `inc-${++this.seq}` };
    this.incidents.push(full);
    return full;
  }

  /** Occasionally start a random incident, like the real world does. */
  maybeSpawn(now: number, dtMs: number): void {
    const perMinute = 1 / 240; // about one every four hours
    if (this.rand() > perMinute * (dtMs / MINUTE)) return;
    const service = SERVICES[Math.floor(this.rand() * SERVICES.length)];
    const states = service.states.length ? service.states : STATES.map((s) => s.code);
    const state = states[Math.floor(this.rand() * states.length)];
    const zipsHere = zipsInState(state);
    if (!zipsHere.length) return;
    const center = zipsHere[Math.floor(this.rand() * zipsHere.length)];
    const duration = (20 + this.rand() * 150) * MINUTE;
    const sources = LICENSED_SOURCES.filter((s) => covers(s, service.slug, service.category)).filter(() => this.rand() < 0.6);
    this.addIncident({
      slug: service.slug, state, zips: nearbyZips(center.zip), centerZip: center.zip, areaLabel: `${center.city}, ${state}`,
      start: now, end: now + duration, ratePerHour: 20 + this.rand() * 120,
      problem: service.problemTypes[0],
      seenBy: sources.map((s) => ({ sourceId: s.id, lagMs: (2 + this.rand() * 8) * MINUTE })),
    });
  }

  /** Synthetic crowd reports for [from, to), one-minute steps. */
  reports(from: number, to: number): CrowdReport[] {
    const out: CrowdReport[] = [];
    for (let t = from; t < to; t += MINUTE) {
      const { hour, day } = localHourAndDay(t);
      for (const s of SERVICES) {
        const n = poisson((s.baseRate / 60) * hourOfWeekFactor(hour, day), this.rand);
        for (let i = 0; i < n; i++) {
          const state = this.pickState(s);
          const zips = zipsInState(state);
          if (zips.length) out.push(this.report(s, t, zips[Math.floor(this.rand() * zips.length)].zip, this.pickProblem(s)));
        }
      }
      for (const inc of this.incidents) {
        const k = intensity(inc, t);
        if (k === 0) continue;
        const service = getService(inc.slug)!;
        const n = poisson((inc.ratePerHour / 60) * k, this.rand);
        for (let i = 0; i < n; i++) {
          const zip = this.pickIncidentZip(inc, service);
          if (zip) out.push(this.report(service, t, zip, this.rand() < 0.7 ? inc.problem : this.pickProblem(service)));
        }
      }
    }
    return out;
  }

  /** What each simulated licensed source (and the official status page) would report right now. */
  signals(now: number): SourceSignal[] {
    const out: SourceSignal[] = [];
    const flagged = new Set<string>();
    for (const inc of this.incidents) {
      if (now < inc.start || now > inc.end + 15 * MINUTE) continue;
      const k = intensity(inc, now);
      for (const seen of inc.seenBy) {
        const sees = now >= inc.start + seen.lagMs && k > 0;
        const level: StatusLevel = !sees ? "ok" : k > 0.5 && inc.ratePerHour >= 60 ? "problems" : "possible";
        out.push({
          sourceId: seen.sourceId, serviceSlug: inc.slug, observedAt: now, level,
          reportCount: Math.round((inc.ratePerHour / 4) * k * (0.6 + this.rand() * 0.8)),
          scope: { state: inc.state, zip: inc.centerZip },
        });
        if (!inc.state && level !== "ok") flagged.add(`${seen.sourceId}|${inc.slug}`);
      }
      if (inc.officialAt && now >= inc.officialAt) {
        const active = now < inc.end;
        out.push({
          sourceId: "official", serviceSlug: inc.slug, observedAt: now,
          level: active ? "problems" : "ok", official: active,
          message: inc.officialMessage, etaAt: active ? inc.etaAt : undefined,
          scope: { state: inc.state, zip: inc.centerZip },
        });
      }
    }
    // Heartbeat "all clear" national signals for everything a source covers.
    for (const src of LICENSED_SOURCES) {
      for (const s of SERVICES) {
        if (!covers(src, s.slug, s.category) || flagged.has(`${src.id}|${s.slug}`)) continue;
        out.push({ sourceId: src.id, serviceSlug: s.slug, observedAt: now, level: "ok", scope: {} });
      }
    }
    return out;
  }

  private report(s: Service, t: number, zip: string, problemType: ProblemType): CrowdReport {
    const place = lookupZip(zip)!;
    const { cellLat, cellLng } = toCell(place.lat + (this.rand() - 0.5) * 0.08, place.lng + (this.rand() - 0.5) * 0.08);
    return {
      id: `sim-${t.toString(36)}-${Math.floor(this.rand() * 1e9).toString(36)}`,
      serviceSlug: s.slug, createdAt: t + Math.floor(this.rand() * MINUTE), problemType,
      zip, state: place.state, cellLat, cellLng, weight: 1, deviceHash: "simulated",
    };
  }

  private pickState(s: Service): string {
    let w = this.stateWeights.get(s.slug);
    if (!w) {
      const codes: string[] = [];
      const cum: number[] = [];
      let acc = 0;
      for (const st of STATES) {
        const share = stateShare(s, st.code);
        if (share <= 0) continue;
        acc += share;
        codes.push(st.code);
        cum.push(acc);
      }
      w = { codes, cum };
      this.stateWeights.set(s.slug, w);
    }
    const r = this.rand() * w.cum[w.cum.length - 1];
    const i = w.cum.findIndex((c) => c >= r);
    return w.codes[Math.max(0, i)];
  }

  private pickIncidentZip(inc: Incident, s: Service): string | undefined {
    if (inc.zips.length) return inc.zips[Math.floor(this.rand() * inc.zips.length)];
    const state = inc.state && getState(inc.state) ? inc.state : this.pickState(s);
    const zips = zipsInState(state);
    return zips.length ? zips[Math.floor(this.rand() * zips.length)].zip : undefined;
  }

  private pickProblem(s: Service): ProblemType {
    // First listed problem type is the most common for that service.
    const i = this.rand() < 0.5 ? 0 : Math.floor(this.rand() * s.problemTypes.length);
    return s.problemTypes[i];
  }
}
