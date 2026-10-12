import type { Category, SourceSignal } from "../types";

/** Environment variables, as a plain map so tests can pass their own. */
export type Env = Record<string, string | undefined>;

export interface SourceInfo {
  id: string;
  name: string;
  url: string;
  /** Shown wherever this source's data appears, as its terms require (PRD §5.1). */
  attribution: string;
  /** Which service categories this source covers. Empty = all. */
  categories: Category[];
  /** Restrict to specific services (e.g. SpectrumOutage.org only covers Spectrum). */
  serviceSlugs?: string[];
  kind: "aggregator" | "official" | "crowd";
}

export interface SourceAdapter {
  info: SourceInfo;
  enabled: boolean;
  /** Why the adapter is off, for the sources page. */
  disabledReason?: string;
  poll(now: number): Promise<SourceSignal[]>;
}

export function covers(info: SourceInfo, slug: string, category: Category): boolean {
  if (info.serviceSlugs) return info.serviceSlugs.includes(slug);
  return info.categories.length === 0 || info.categories.includes(category);
}
