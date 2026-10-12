// The detection engine: polls sources, ingests crowd reports, keeps a status
// snapshot for every service nationally and per state, and drives alerts.
// Runs in-process on a timer; one instance per server process (PRD §9).

import { EventEmitter } from "node:events";
import { AbuseGuard } from "./abuse";
import { AlertManager, ConsoleEmailTransport, type AlertMessage } from "./alerts";
import { BaselineModel, classify, hourOfWeek, priorBaseline15, THRESHOLDS, type SourceVote } from "./detection";
import { getState, lookupZip, nearbyZips, stateShare, STATES, toCell, zipsInState, type Place } from "./geo";
import { getService, SERVICES } from "./services";
import { LICENSED_SOURCES, licensedAdapter } from "./sources/licensed";
import { Simulator } from "./sources/simulator";
import { statuspageAdapter } from "./sources/statuspage";
import { covers, type Env, type SourceAdapter, type SourceInfo } from "./sources/types";
import { scopeKey, Store } from "./store";
import { HOUR, localHourAndDay, MINUTE, minuteOf } from "./time";
import type { CrowdReport, ProblemType, Service, StatusLevel, StatusResult } from "./types";

export interface Scope {
  state?: string;
  zip?: string;
}

export interface IncidentRecord {
  slug: string;
  /** "US" or a state code. */
  area: string;
  start: number;
  end?: number;
  peak: StatusLevel;
}

export interface ServiceSummary {
  slug: string;
  name: string;
  category: Service["category"];
  status: StatusResult;
  /** Reports per 15 minutes over the last 6 hours, for sparklines. */
  spark: number[];
}

type Events = { change: [IncidentRecord & { level: StatusLevel }]; alert: [AlertMessage]; tick: [number] };

const WINDOW_MIN = 15;

export class Engine {
  readonly store = new Store();
  readonly guard = new AbuseGuard();
  readonly bus = new EventEmitter<Events>();
  readonly email = new ConsoleEmailTransport();
  readonly alerts = new AlertManager(this.email, (m) => this.bus.emit("alert", m));
  readonly demo: boolean;
  readonly sim?: Simulator;
  readonly adapters: SourceAdapter[];
  private readonly baselines = new BaselineModel();
  private snapshot = new Map<string, StatusResult>();
  private readonly incidents: IncidentRecord[] = [];
  private readonly open = new Map<string, IncidentRecord>();
  private lastTick = 0;
  private lastLearned = 0;
  private sourceNames = new Map<string, string>();
  private timer?: NodeJS.Timeout;
  lastPollErrors: { source: string; error: string; at: number }[] = [];

  constructor(env: Env = process.env, now = Date.now()) {
    this.demo = env.DEMO_MODE !== "false";
    this.adapters = [...LICENSED_SOURCES.map((s) => licensedAdapter(s, env)), statuspageAdapter(env)];
    this.bus.setMaxListeners(1000);
    this.sourceNames = new Map(this.activeSources().map((s) => [s.id, s.name]));
    if (this.demo) {
      this.sim = new Simulator();
      this.sim.seedIncidents(now);
      this.backfill(now);
    }
    this.lastTick = now;
  }

  start(intervalMs: number): void {
    if (this.timer) return;
    this.timer = setInterval(() => void this.tick(Date.now()), intervalMs);
    this.timer.unref?.();
  }

  /** Sources treated as live: enabled adapters, plus every licensed source in demo mode. */
  activeSources(): SourceInfo[] {
    return this.adapters.filter((a) => a.enabled || (this.demo && a.info.kind === "aggregator")).map((a) => a.info);
  }

  sourcesFor(service: Service): SourceInfo[] {
    return this.activeSources().filter((s) => covers(s, service.slug, service.category));
  }

  // -------------------------------------------------------------------------
  // Ingestion

  async tick(now: number): Promise<void> {
    if (this.sim) {
      this.sim.maybeSpawn(now, now - this.lastTick);
      for (const r of this.sim.reports(this.lastTick, now)) this.store.addReport(r);
      for (const s of this.sim.signals(now)) this.store.addSignal(s);
    }
    await Promise.all(
      this.adapters.filter((a) => a.enabled).map(async (a) => {
        try {
          for (const s of await a.poll(now)) this.store.addSignal(s);
        } catch (e) {
          this.lastPollErrors = [{ source: a.info.name, error: String(e), at: now }, ...this.lastPollErrors].slice(0, 20);
        }
      }),
    );
    this.lastTick = now;
    this.recompute(now, true);
    this.alerts.evaluate(now, (slug, zip) => this.status(slug, { zip }, now));
    if (now % (30 * MINUTE) < 2 * MINUTE) this.store.prune(now);
    this.bus.emit("tick", now);
  }

  /** Accept a report from a user. Returns an error string if rejected. */
  report(input: { serviceSlug: string; zip: string; problemType: ProblemType; comment?: string; deviceId: string; ip: string }, now: number):
    | { ok: true; report: CrowdReport; nearby: number }
    | { ok: false; error: string; status: number; retryAfterSec?: number } {
    const service = getService(input.serviceSlug);
    if (!service) return { ok: false, error: "Unknown service.", status: 400 };
    if (!service.problemTypes.includes(input.problemType)) return { ok: false, error: "Unknown problem type for this service.", status: 400 };
    const place = lookupZip(input.zip);
    if (!place) return { ok: false, error: "Enter a valid US ZIP code.", status: 400 };
    const verdict = this.guard.check({ deviceId: input.deviceId, ip: input.ip, serviceSlug: service.slug, now });
    if (!verdict.ok) return { ok: false, error: verdict.reason, status: 429, retryAfterSec: verdict.retryAfterSec };

    const report: CrowdReport = {
      id: crypto.randomUUID(),
      serviceSlug: service.slug,
      createdAt: now,
      problemType: input.problemType,
      comment: sanitizeComment(input.comment),
      zip: place.zip,
      state: place.state,
      ...toCell(place.lat, place.lng),
      weight: verdict.weight,
      deviceHash: verdict.deviceHash,
    };
    this.store.addReport(report);
    const nearby = Math.round(this.windowSum(service.slug, { zip: place.zip }, now, 60));
    return { ok: true, report, nearby };
  }

  // -------------------------------------------------------------------------
  // Status

  private snapKey(slug: string, area: string): string {
    return `${slug}|${area}`;
  }

  /** Status for a service at a scope. National and state come from the snapshot; ZIP is computed live. */
  status(slug: string, scope: Scope, now = Date.now()): StatusResult {
    if (!scope.zip) {
      const hit = this.snapshot.get(this.snapKey(slug, scope.state ?? "US"));
      if (hit) return hit;
    }
    return this.compute(getService(slug)!, scope, now);
  }

  private compute(service: Service, scope: Scope, now: number): StatusResult {
    const state = scope.zip ? lookupZip(scope.zip)?.state : scope.state;
    const current = this.windowSum(service.slug, scope, now, WINDOW_MIN);
    const baseline = this.baseline(service, scope, now);
    const wideArea = !scope.zip;
    const passes = current / Math.max(baseline, THRESHOLDS.baselineFloor) >= THRESHOLDS.problemsRatio;
    const distinctCells = wideArea && passes ? this.distinctCells(service.slug, scope, now) : 99;
    return classify({
      now, current, baseline, distinctCells, wideArea,
      votes: this.votes(service, state, scope.zip),
      sourcesTotal: this.sourcesFor(service).length + (service.statuspageApi || service.officialStatusUrl ? 1 : 0),
    });
  }

  private votes(service: Service, state?: string, zip?: string): SourceVote[] {
    const names = this.sourceNames;
    // A signal pinned to a ZIP only counts for ZIPs near it; state-wide signals count everywhere in the state.
    const near = zip ? new Set(nearbyZips(zip)) : undefined;
    return this.store.signalsFor(service.slug, state).flatMap((s) => {
      if (near && s.scope.zip && !near.has(s.scope.zip)) return [];
      const official = s.sourceId === "official" || s.official;
      const name = official ? `${service.name} (official)` : names.get(s.sourceId);
      if (!name || !s.level) return [];
      const inherited = Boolean(state) && !s.scope.state;
      return [{ sourceId: s.sourceId, sourceName: name, level: s.level, official, message: s.message, etaAt: s.etaAt, observedAt: s.observedAt, inherited }];
    });
  }

  /** Weighted reports in the `minutes` before `now`. */
  windowSum(slug: string, scope: Scope, now: number, minutes: number): number {
    const to = minuteOf(now) + 1;
    return this.rangeSum(slug, scope, to - minutes, to);
  }

  private rangeSum(slug: string, scope: Scope, fromMin: number, toMin: number): number {
    if (scope.zip) {
      return nearbyZips(scope.zip).reduce((sum, z) => sum + this.store.counts.sum(scopeKey.zip(slug, z), fromMin, toMin), 0);
    }
    const key = scope.state ? scopeKey.state(slug, scope.state) : scopeKey.nation(slug);
    return this.store.counts.sum(key, fromMin, toMin);
  }

  /** Expected reports in a 15-minute window ending at `at`. */
  baseline(service: Service, scope: Scope, at: number): number {
    const place = scope.zip ? lookupZip(scope.zip) : undefined;
    const state = place?.state ?? scope.state;
    let share = 1;
    if (state) share = stateShare(service, state);
    if (place) share *= areaFraction(place);
    const { hour, day } = localHourAndDay(at, state);
    const prior = priorBaseline15(service.baseRate, share, hour, day);
    if (scope.zip) return prior;
    return this.baselines.baseline(this.snapKey(service.slug, state ?? "US"), hourOfWeek(hour, day), prior);
  }

  private distinctCells(slug: string, scope: Scope, now: number): number {
    const since = now - WINDOW_MIN * MINUTE;
    const cells = new Set<string>();
    for (const r of this.store.queryReports(since, (r) => r.serviceSlug === slug && (!scope.state || r.state === scope.state))) {
      cells.add(`${r.cellLat},${r.cellLng}`);
      if (cells.size >= THRESHOLDS.minCellsForWideArea) break;
    }
    return cells.size;
  }

  /** Recompute the national + per-state snapshot and record incident transitions. */
  private recompute(now: number, live: boolean): void {
    const next = new Map<string, StatusResult>();
    // Learn baselines once per 15-minute window so a slow-building outage isn't absorbed as "normal".
    const learn = now - this.lastLearned >= WINDOW_MIN * MINUTE;
    if (learn) this.lastLearned = now;
    for (const service of SERVICES) {
      const areas = ["US", ...(service.states.length ? service.states : STATES.map((s) => s.code))];
      for (const area of areas) {
        const scope = area === "US" ? {} : { state: area };
        const result = this.compute(service, scope, now);
        next.set(this.snapKey(service.slug, area), result);
        const { hour, day } = localHourAndDay(now, scope.state);
        if (learn) this.baselines.observe(this.snapKey(service.slug, area), hourOfWeek(hour, day), result.current, result.level);
        // History records local evidence only; a nationwide issue isn't repeated for every state.
        this.track(service.slug, area, result.inheritedOnly ? "ok" : result.level, now, live);
      }
    }
    this.snapshot = next;
  }

  private track(slug: string, area: string, level: StatusLevel, now: number, live: boolean): void {
    const key = this.snapKey(slug, area);
    const rec = this.open.get(key);
    if (level !== "ok" && !rec) {
      const r: IncidentRecord = { slug, area, start: now, peak: level };
      this.open.set(key, r);
      this.incidents.push(r);
      if (live) this.bus.emit("change", { ...r, level });
    } else if (rec && level === "problems" && rec.peak !== "problems") {
      rec.peak = "problems";
      if (live) this.bus.emit("change", { ...rec, level });
    } else if (rec && level === "ok") {
      rec.end = now;
      this.open.delete(key);
      if (live) this.bus.emit("change", { ...rec, level });
    }
  }

  /** Replay the simulated last 24 hours so curves, baselines and history have data. */
  private backfill(now: number): void {
    const start = now - 24 * HOUR;
    for (const r of this.sim!.reports(start - WINDOW_MIN * MINUTE, now)) this.store.addReport(r);
    for (let t = start; t <= now; t += 5 * MINUTE) {
      for (const s of this.sim!.signals(t)) this.store.addSignal(s);
      this.recompute(t, false);
    }
  }

  // -------------------------------------------------------------------------
  // Read models for the UI

  summaries(scope: Scope, now = Date.now()): ServiceSummary[] {
    const services = scope.state || scope.zip ? servicesIn(scope) : SERVICES;
    return services.map((s) => ({
      slug: s.slug, name: s.name, category: s.category,
      status: this.status(s.slug, scope, now),
      spark: this.curve(s.slug, scope, now, 6).map((p) => p.reports),
    }));
  }

  /** Report curve in 15-minute buckets with the expected baseline for each. */
  curve(slug: string, scope: Scope, now: number, hours = 24): { t: number; reports: number; baseline: number }[] {
    const service = getService(slug)!;
    const end = minuteOf(now) + 1;
    const buckets = (hours * 60) / WINDOW_MIN;
    const out = [];
    for (let i = buckets - 1; i >= 0; i--) {
      const to = end - i * WINDOW_MIN;
      const t = to * MINUTE;
      out.push({
        t,
        reports: Math.round(this.rangeSum(slug, scope, to - WINDOW_MIN, to) * 10) / 10,
        baseline: Math.round(this.baseline(service, scope, t) * 10) / 10,
      });
    }
    return out;
  }

  /** Problem types and top locations among reports in the last hour. */
  breakdown(slug: string, scope: Scope, now: number) {
    const near = scope.zip ? new Set(nearbyZips(scope.zip)) : undefined;
    const reports = this.store.queryReports(now - HOUR, (r) =>
      r.serviceSlug === slug && (!scope.state || r.state === scope.state) && (!near || near.has(r.zip)),
    );
    const problems = new Map<ProblemType, number>();
    const places = new Map<string, { label: string; state: string; zip?: string; count: number }>();
    for (const r of reports) {
      problems.set(r.problemType, (problems.get(r.problemType) ?? 0) + r.weight);
      const p = lookupZip(r.zip);
      const key = scope.state || scope.zip ? `${p?.city}|${r.state}` : r.state;
      const label = scope.state || scope.zip ? `${p?.city ?? r.zip}, ${r.state}` : (getState(r.state)?.name ?? r.state);
      const cur = places.get(key) ?? { label, state: r.state, zip: scope.state || scope.zip ? r.zip : undefined, count: 0 };
      cur.count += r.weight;
      places.set(key, cur);
    }
    const total = [...problems.values()].reduce((a, b) => a + b, 0) || 1;
    return {
      total: Math.round(total),
      problems: [...problems.entries()].map(([type, n]) => ({ type, share: n / total })).sort((a, b) => b.share - a.share),
      places: [...places.values()].sort((a, b) => b.count - a.count).slice(0, 8).map((p) => ({ ...p, count: Math.round(p.count) })),
      comments: reports.filter((r) => r.comment).slice(-10).reverse().map((r) => ({ at: r.createdAt, text: r.comment!, zip: r.zip })),
    };
  }

  /** Incident history for a service (or everything), newest first. */
  history(filter: { slug?: string; area?: string }, since: number): IncidentRecord[] {
    return this.incidents
      .filter((i) => (!filter.slug || i.slug === filter.slug) && (!filter.area || i.area === filter.area) && (i.end ?? Infinity) >= since)
      .sort((a, b) => b.start - a.start);
  }

  /** Share of the last `hours` the national status was "ok". */
  uptime(slug: string, now: number, hours: number): number {
    const since = now - hours * HOUR;
    let down = 0;
    for (const i of this.history({ slug, area: "US" }, since)) down += (i.end ?? now) - Math.max(i.start, since);
    return Math.max(0, 1 - down / (hours * HOUR));
  }

  /** Map cells with at least K reports in the window (k-anonymity, PRD §8). */
  mapCells(filter: { slug?: string; category?: string; minutes: number }, now: number, k = 5) {
    const cells = new Map<string, { lat: number; lng: number; count: number; services: Map<string, number> }>();
    for (const r of this.store.queryReports(now - filter.minutes * MINUTE, (r) => {
      if (filter.slug) return r.serviceSlug === filter.slug;
      if (filter.category) return getService(r.serviceSlug)?.category === filter.category;
      return true;
    })) {
      const key = `${r.cellLat},${r.cellLng}`;
      const c = cells.get(key) ?? { lat: r.cellLat, lng: r.cellLng, count: 0, services: new Map() };
      c.count += r.weight;
      c.services.set(r.serviceSlug, (c.services.get(r.serviceSlug) ?? 0) + r.weight);
      cells.set(key, c);
    }
    return [...cells.values()]
      .filter((c) => c.count >= k)
      .map((c) => {
        const top = [...c.services.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3);
        return { lat: c.lat, lng: c.lng, count: Math.round(c.count), top: top.map(([slug, n]) => ({ slug, name: getService(slug)?.name ?? slug, count: Math.round(n) })) };
      });
  }

  /** Worst status per state, optionally for one service or category. */
  stateLevels(filter: { slug?: string; category?: string }, now = Date.now()) {
    return STATES.map((st) => {
      const services = servicesIn({ state: st.code }).filter((s) => (!filter.slug || s.slug === filter.slug) && (!filter.category || s.category === filter.category));
      let problems = 0;
      let possible = 0;
      for (const s of services) {
        const r = this.status(s.slug, { state: st.code }, now);
        if (r.inheritedOnly) continue; // a nationwide issue with no local reports doesn't color the state
        const lv = r.level;
        if (lv === "problems") problems++;
        else if (lv === "possible") possible++;
      }
      const level: StatusLevel = problems ? "problems" : possible ? "possible" : "ok";
      return { state: st.code, name: st.name, fips: st.fips, level, problems, possible };
    });
  }
}

function servicesIn(scope: Scope): Service[] {
  const state = scope.zip ? lookupZip(scope.zip)?.state : scope.state;
  return state ? SERVICES.filter((s) => s.states.length === 0 || s.states.includes(state)) : SERVICES;
}

/** Share of a state's ZIPs that fall within the "near you" radius. */
function areaFraction(place: Place): number {
  const inState = zipsInState(place.state).length;
  if (!inState) return 0;
  const near = nearbyZips(place.zip).filter((z) => lookupZip(z)?.state === place.state).length;
  return Math.max(1, near) / inState;
}

function sanitizeComment(text?: string): string | undefined {
  const t = text?.replace(/[\u0000-\u001f<>]/g, " ").replace(/\s+/g, " ").trim().slice(0, 280);
  return t ? maskProfanity(t) : undefined;
}

const PROFANITY = /\b(fuck\w*|shit\w*|bitch\w*|asshole\w*|cunt\w*)\b/gi;
function maskProfanity(s: string): string {
  return s.replace(PROFANITY, (w) => w[0] + "*".repeat(w.length - 1));
}

// ---------------------------------------------------------------------------
// Singleton: survives Next.js dev hot reloads.

const g = globalThis as unknown as { __rollercoaster?: Engine };

export function getEngine(): Engine {
  if (!g.__rollercoaster) {
    const engine = new Engine();
    const interval = Math.max(15, Number(process.env.POLL_INTERVAL_SECONDS) || 60) * 1000;
    engine.start(interval);
    void engine.tick(Date.now());
    g.__rollercoaster = engine;
  }
  return g.__rollercoaster;
}
