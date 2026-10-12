// Shared domain types. See docs/PRD.md §6.1 for the status model.

export type StatusLevel = "ok" | "possible" | "problems";

export const STATUS_LABEL: Record<StatusLevel, string> = {
  ok: "No problems",
  possible: "Possible problems",
  problems: "Problems",
};

export type Category =
  | "isp"
  | "mobile"
  | "tv"
  | "streaming"
  | "gaming"
  | "banking"
  | "cloud"
  | "social"
  | "power";

export const CATEGORY_LABEL: Record<Category, string> = {
  isp: "Internet / ISP",
  mobile: "Mobile",
  tv: "TV / Cable",
  streaming: "Streaming",
  gaming: "Gaming",
  banking: "Banking & Payments",
  cloud: "Cloud & Dev",
  social: "Social",
  power: "Power",
};

export type ProblemType =
  | "no_connection"
  | "slow"
  | "intermittent"
  | "tv"
  | "phone"
  | "login"
  | "app"
  | "payments"
  | "power";

export const PROBLEM_LABEL: Record<ProblemType, string> = {
  no_connection: "No connection",
  slow: "Slow speeds",
  intermittent: "Keeps dropping",
  tv: "TV / video",
  phone: "Phone / calls",
  login: "Login / account",
  app: "App or website",
  payments: "Payments",
  power: "Power out",
};

export interface Service {
  slug: string;
  name: string;
  category: Category;
  /** Other names the same company goes by in source feeds. */
  aliases: string[];
  /** Two-letter states where the service operates. Empty = nationwide. */
  states: string[];
  /** Typical crowd reports per hour nationwide at a quiet time (seeds baselines). */
  baseRate: number;
  problemTypes: ProblemType[];
  troubleshooting: string[];
  officialStatusUrl?: string;
  /** Atlassian Statuspage summary endpoint, when the provider publishes one. */
  statuspageApi?: string;
}

/** Where a signal applies. A missing field means "the whole level above". */
export interface GeoScope {
  state?: string;
  zip?: string;
}

/** One observation from one source about one service. */
export interface SourceSignal {
  sourceId: string;
  serviceSlug: string;
  observedAt: number;
  /** Reports/complaints the source counted in the last 15 minutes. */
  reportCount?: number;
  /** The source's own verdict, mapped onto our status levels. */
  level?: StatusLevel;
  /** True when this is the provider's own confirmed incident. */
  official?: boolean;
  message?: string;
  etaAt?: number;
  scope: GeoScope;
  lat?: number;
  lng?: number;
}

export interface CrowdReport {
  id: string;
  serviceSlug: string;
  createdAt: number;
  problemType: ProblemType;
  comment?: string;
  zip: string;
  state: string;
  /** Rounded grid cell, never raw GPS (PRD §8). */
  cellLat: number;
  cellLng: number;
  /** 0–1 weight; unverified or suspicious reporters count for less. */
  weight: number;
  deviceHash: string;
}

export interface StatusResult {
  level: StatusLevel;
  /** 0–1 confidence in the level. */
  confidence: number;
  /** Weighted reports in the last 15 minutes. */
  current: number;
  /** Expected reports for this 15-minute slot. */
  baseline: number;
  ratio: number;
  reasons: string[];
  sourcesReporting: string[];
  sourcesTotal: number;
  officialMessage?: string;
  etaAt?: number;
  /** True when the level comes only from a nationwide signal, with no local evidence. */
  inheritedOnly?: boolean;
}
