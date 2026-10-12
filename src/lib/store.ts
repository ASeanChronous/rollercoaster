// In-memory store for crowd reports and source signals, indexed by minute so
// status queries are cheap. A production deployment swaps this for Postgres +
// a time-series store (PRD §9); the interface stays the same.

import type { CrowdReport, SourceSignal } from "./types";
import { minuteOf, HOUR } from "./time";

/** How long raw reports and counters are kept. */
export const RETENTION_MS = 48 * HOUR;

/** Sparse per-minute counters under string keys like "spectrum|TX". */
class MinuteCounter {
  private readonly series = new Map<string, Map<number, number>>();

  add(key: string, minute: number, value: number): void {
    let s = this.series.get(key);
    if (!s) this.series.set(key, (s = new Map()));
    s.set(minute, (s.get(minute) ?? 0) + value);
  }

  /** Sum over minutes [from, to). */
  sum(key: string, fromMinute: number, toMinute: number): number {
    const s = this.series.get(key);
    if (!s) return 0;
    let total = 0;
    if (toMinute - fromMinute < s.size) {
      for (let m = fromMinute; m < toMinute; m++) total += s.get(m) ?? 0;
    } else {
      for (const [m, v] of s) if (m >= fromMinute && m < toMinute) total += v;
    }
    return total;
  }

  prune(beforeMinute: number): void {
    for (const [key, s] of this.series) {
      for (const m of s.keys()) if (m < beforeMinute) s.delete(m);
      if (s.size === 0) this.series.delete(key);
    }
  }
}

export const scopeKey = {
  nation: (slug: string) => `${slug}|US`,
  state: (slug: string, state: string) => `${slug}|${state}`,
  zip: (slug: string, zip: string) => `${slug}|z${zip}`,
};

export class Store {
  readonly counts = new MinuteCounter();
  private reports: CrowdReport[] = [];
  /** Latest signal per service, then per source/scope. */
  private readonly latest = new Map<string, Map<string, SourceSignal>>();

  addReport(r: CrowdReport): void {
    this.reports.push(r);
    const m = minuteOf(r.createdAt);
    this.counts.add(scopeKey.nation(r.serviceSlug), m, r.weight);
    this.counts.add(scopeKey.state(r.serviceSlug, r.state), m, r.weight);
    this.counts.add(scopeKey.zip(r.serviceSlug, r.zip), m, r.weight);
  }

  /** Reports matching a filter, newest last. Scans memory; fine at MVP volume. */
  queryReports(since: number, filter: (r: CrowdReport) => boolean = () => true): CrowdReport[] {
    const out: CrowdReport[] = [];
    // Reports are appended in time order (backfill aside), so walk from the end.
    for (let i = this.reports.length - 1; i >= 0; i--) {
      const r = this.reports[i];
      if (r.createdAt < since) {
        if (r.createdAt < since - HOUR) break;
        continue;
      }
      if (filter(r)) out.push(r);
    }
    return out.reverse();
  }

  addSignal(s: SourceSignal): void {
    let bySvc = this.latest.get(s.serviceSlug);
    if (!bySvc) this.latest.set(s.serviceSlug, (bySvc = new Map()));
    bySvc.set(`${s.sourceId}|${s.scope.state ?? "US"}|${s.scope.zip ?? ""}`, s);
  }

  /** Latest signals for a service that apply to a scope (state signals also apply to their ZIPs). */
  signalsFor(slug: string, state?: string): SourceSignal[] {
    const out: SourceSignal[] = [];
    for (const s of this.latest.get(slug)?.values() ?? []) {
      if (state ? s.scope.state === state || !s.scope.state : !s.scope.state) out.push(s);
    }
    return out;
  }

  allSignals(): SourceSignal[] {
    return [...this.latest.values()].flatMap((m) => [...m.values()]);
  }

  prune(now: number): void {
    const cutoff = now - RETENTION_MS;
    this.reports.sort((a, b) => a.createdAt - b.createdAt);
    const first = this.reports.findIndex((r) => r.createdAt >= cutoff);
    this.reports = first === -1 ? [] : this.reports.slice(first);
    this.counts.prune(minuteOf(cutoff));
    for (const m of this.latest.values()) for (const [k, s] of m) if (s.observedAt < cutoff) m.delete(k);
  }
}
