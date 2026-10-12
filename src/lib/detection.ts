// Outage detection: baselines and the unified status model (PRD §6.1).
// Everything here is pure so it can be unit-tested and backtested.

import type { StatusLevel, StatusResult } from "./types";

export const THRESHOLDS = {
  /** Report volume vs. baseline that triggers each level. */
  possibleRatio: 2,
  problemsRatio: 5,
  /** Minimum weighted reports before crowd volume alone can move the status. */
  minPossibleReports: 5,
  minProblemsReports: 8,
  /**
   * How unlikely the report count must be under normal conditions (Poisson
   * upper-tail probability). Strict, because every service is checked in
   * every area many times a day, so ordinary chance spikes are common.
   */
  possibleP: 1e-4,
  problemsP: 1e-7,
  /** Crowd-only "Problems" for a whole state or the nation needs reports from this many map cells. */
  minCellsForWideArea: 3,
  /** A source signal older than this no longer counts. */
  freshnessMs: 10 * 60_000,
  /** Floor so a near-zero baseline doesn't turn one report into a huge ratio. */
  baselineFloor: 0.5,
};

const RANK: Record<StatusLevel, number> = { ok: 0, possible: 1, problems: 2 };

export function maxLevel(a: StatusLevel, b: StatusLevel): StatusLevel {
  return RANK[a] >= RANK[b] ? a : b;
}

export function levelAtLeast(level: StatusLevel, min: StatusLevel): boolean {
  return RANK[level] >= RANK[min];
}

// ---------------------------------------------------------------------------
// Baselines

/**
 * Relative report volume by local hour (0–23). Reports track how many people
 * are online: quiet overnight, peaking in the evening. Mean is ~1.
 */
const DIURNAL = [
  0.35, 0.25, 0.2, 0.18, 0.2, 0.3, 0.55, 0.8, 0.95, 1.05, 1.1, 1.15,
  1.15, 1.15, 1.15, 1.2, 1.3, 1.45, 1.6, 1.7, 1.7, 1.55, 1.1, 0.6,
];

/** Expected-volume multiplier for a local hour and day of week (0 = Sunday). */
export function hourOfWeekFactor(localHour: number, dayOfWeek: number): number {
  const weekend = dayOfWeek === 0 || dayOfWeek === 6;
  return DIURNAL[((localHour % 24) + 24) % 24] * (weekend ? 1.1 : 1);
}

/** Hour-of-week index 0–167, the key baselines are learned under. */
export function hourOfWeek(localHour: number, dayOfWeek: number): number {
  return dayOfWeek * 24 + localHour;
}

/**
 * Expected reports in a 15-minute window from the prior model:
 * national base rate × geographic share × time-of-week factor.
 */
export function priorBaseline15(baseRatePerHour: number, share: number, localHour: number, dayOfWeek: number): number {
  return (baseRatePerHour * share * hourOfWeekFactor(localHour, dayOfWeek)) / 4;
}

/**
 * Learns baselines per (service, area, hour-of-week) from quiet periods with an
 * exponentially weighted mean, falling back to the prior until enough samples exist.
 * Windows already classified as outages are skipped so spikes don't inflate "normal".
 */
export class BaselineModel {
  private readonly cells = new Map<string, { mean: number; n: number }>();

  constructor(
    private readonly alpha = 0.1,
    private readonly minSamples = 4,
  ) {}

  observe(key: string, how: number, value: number, level: StatusLevel): void {
    if (level !== "ok") return;
    const k = `${key}|${how}`;
    const cell = this.cells.get(k);
    if (!cell) {
      this.cells.set(k, { mean: value, n: 1 });
    } else {
      cell.mean = cell.mean + this.alpha * (value - cell.mean);
      cell.n += 1;
    }
  }

  baseline(key: string, how: number, prior: number): number {
    const cell = this.cells.get(`${key}|${how}`);
    if (!cell || cell.n < this.minSamples) return prior;
    // Blend toward the prior so one odd week can't drag the baseline far.
    const w = Math.min(1, cell.n / 20);
    return w * cell.mean + (1 - w) * prior;
  }
}

// ---------------------------------------------------------------------------
// Classification

export interface SourceVote {
  sourceId: string;
  sourceName: string;
  level: StatusLevel;
  official?: boolean;
  message?: string;
  etaAt?: number;
  observedAt: number;
  /**
   * A nationwide signal applied to a state or ZIP. It shows there's a wider
   * issue, but only counts as local evidence once local reports rise too.
   */
  inherited?: boolean;
}

export interface ClassifyInput {
  now: number;
  /** Weighted crowd reports (ours) in the last 15 minutes. */
  current: number;
  baseline: number;
  /** Distinct map cells those reports came from. */
  distinctCells: number;
  /** True for state or national scope, where brigading protection applies. */
  wideArea: boolean;
  /** Latest signal from each third-party or official source. */
  votes: SourceVote[];
  /** Number of sources that cover this service (for "3 of 4 sources"). */
  sourcesTotal: number;
}

const CROWD_SOURCE = "Rollercoaster users";

export function classify(input: ClassifyInput): StatusResult {
  const t = THRESHOLDS;
  const baseline = Math.max(input.baseline, t.baselineFloor);
  const ratio = input.current / baseline;
  const p = poissonTail(input.current, baseline);
  const reasons: string[] = [];

  // 1. Our own crowd reports.
  let crowd: StatusLevel = "ok";
  if (ratio >= t.problemsRatio && input.current >= t.minProblemsReports && p < t.problemsP) {
    if (input.wideArea && input.distinctCells < t.minCellsForWideArea) {
      crowd = "possible";
      reasons.push(`Report spike is concentrated in ${input.distinctCells} area(s), so it isn't treated as a wide outage yet.`);
    } else {
      crowd = "problems";
    }
  } else if (ratio >= t.possibleRatio && input.current >= t.minPossibleReports && p < t.possibleP) {
    crowd = "possible";
  }
  if (crowd !== "ok") reasons.push(`Reports are ${ratio.toFixed(1)}× the normal level for this time.`);

  // 2. Other sources' verdicts, freshest first, stale ones dropped.
  const fresh = input.votes
    .filter((v) => input.now - v.observedAt <= t.freshnessMs)
    .sort((a, b) => b.observedAt - a.observedAt);
  // Wider-area signals only count here once local reports corroborate them.
  const corroborated = crowd !== "ok";
  const counted = fresh.filter((v) => !v.inherited || corroborated);
  const background = fresh.filter((v) => v.inherited && !corroborated && v.level !== "ok");
  const flagging = counted.filter((v) => v.level !== "ok");
  const official = counted.find((v) => v.official && v.level !== "ok");

  const reporting = new Set(flagging.map((v) => v.sourceName));
  if (crowd !== "ok") reporting.add(CROWD_SOURCE);

  let level: StatusLevel = crowd;
  if (official) {
    level = "problems";
    reasons.unshift(`${official.sourceName} has confirmed an incident.`);
  }
  if (reporting.size >= 2) {
    level = "problems";
    reasons.push(`${reporting.size} independent sources agree.`);
  } else if (flagging.length === 1 && !official) {
    level = maxLevel(level, "possible");
    reasons.push(`${flagging[0].sourceName} reports ${flagging[0].level === "problems" ? "problems" : "possible problems"}.`);
  }
  let inheritedOnly = false;
  if (level === "ok" && background.length) {
    level = "possible";
    inheritedOnly = true;
    reasons.push(`${background.map((v) => v.sourceName).join(", ")} report${background.length === 1 ? "s" : ""} a nationwide issue, but local reports are normal so far.`);
  }

  // + our own crowd reports; never fewer than the sources actually reporting.
  const sourcesTotal = Math.max(input.sourcesTotal + 1, reporting.size);
  const confidence = scoreConfidence(level, reporting.size, ratio, Boolean(official), counted.length);

  if (level === "ok") reasons.push("Report volume is within the normal range and no source flags an issue.");

  return {
    level,
    confidence,
    current: round1(input.current),
    baseline: round1(input.baseline),
    ratio: round1(ratio),
    reasons,
    sourcesReporting: [...reporting],
    sourcesTotal,
    officialMessage: official?.message,
    etaAt: official?.etaAt ?? flagging.find((v) => v.etaAt)?.etaAt,
    inheritedOnly,
  };
}

function scoreConfidence(
  level: StatusLevel,
  agreeing: number,
  ratio: number,
  official: boolean,
  freshSources: number,
): number {
  let c: number;
  if (level === "ok") {
    // More sources checking in and saying "fine" → more confident it's fine.
    c = 0.55 + 0.08 * freshSources - (ratio > 1.5 ? 0.15 : 0);
  } else {
    c = 0.35 + 0.15 * agreeing + Math.min(0.2, Math.log2(Math.max(ratio, 1)) / 15);
    if (official) c += 0.4;
    if (level === "possible") c = Math.min(c, 0.75);
  }
  return Math.round(Math.max(0.05, Math.min(0.99, c)) * 100) / 100;
}

/** P(X ≥ k) for X ~ Poisson(lambda), computed in log space. */
export function poissonTail(k: number, lambda: number): number {
  const n = Math.floor(k);
  if (n <= 0) return 1;
  // Sum P(X = i) for i < n, then take the complement; switch to the tail sum when that is more precise.
  let logTerm = -lambda; // log P(X = 0)
  if (n > lambda) {
    // Upper tail directly: P(X = n) + P(X = n+1) + ...
    let logPn = -lambda + n * Math.log(lambda) - logFactorial(n);
    let sum = 0;
    for (let i = n; i < n + 1000; i++) {
      const term = Math.exp(logPn);
      sum += term;
      if (term < sum * 1e-12) break;
      logPn += Math.log(lambda) - Math.log(i + 1);
    }
    return Math.min(1, sum);
  }
  let below = 0;
  for (let i = 0; i < n; i++) {
    below += Math.exp(logTerm);
    logTerm += Math.log(lambda) - Math.log(i + 1);
  }
  return Math.max(0, 1 - below);
}

function logFactorial(n: number): number {
  let s = 0;
  for (let i = 2; i <= n; i++) s += Math.log(i);
  return s;
}

function round1(n: number): number {
  return Math.round(n * 10) / 10;
}
