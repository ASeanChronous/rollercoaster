// Canonical service registry (PRD §9 "Service registry"). Source adapters map
// their own provider names onto these slugs through `aliases`.

import type { Category, ProblemType, Service } from "./types";

const ISP_PROBLEMS: ProblemType[] = ["no_connection", "slow", "intermittent", "tv", "phone"];
const MOBILE_PROBLEMS: ProblemType[] = ["no_connection", "slow", "phone", "intermittent"];
const APP_PROBLEMS: ProblemType[] = ["app", "login", "slow"];
const BANK_PROBLEMS: ProblemType[] = ["login", "app", "payments"];

const ISP_TIPS = [
  "Check whether the lights on your modem/router are solid or blinking red.",
  "Unplug the modem and router for 60 seconds, plug the modem in first, then the router.",
  "Connect a computer directly with an Ethernet cable to rule out Wi-Fi problems.",
  "Run a speed test and compare it to your plan's advertised speed.",
  "Check the provider's app or account page for an outage notice at your address.",
  "If an outage is confirmed here, there's nothing to fix at home. Use a mobile hotspot meanwhile.",
];
const MOBILE_TIPS = [
  "Toggle airplane mode on for 10 seconds, then off.",
  "Restart your phone.",
  "Turn on Wi-Fi Calling if you have Wi-Fi.",
  "Check that cellular data and roaming are enabled.",
  "Reset network settings as a last resort (this forgets saved Wi-Fi networks).",
];
const APP_TIPS = [
  "Check whether other websites and apps work, to rule out your own internet.",
  "Force-close the app and reopen it, or try the website instead.",
  "Sign out and back in.",
  "Clear the app cache or browser cache.",
  "Update the app to the latest version.",
];
const GAMING_TIPS = [
  "Check whether other online games or sites work, to rule out your ISP.",
  "Restart the console or PC and your router.",
  "Use a wired connection if you can.",
  "Check the platform's status page for maintenance windows.",
];
const BANK_TIPS = [
  "Try the website if the app fails, or the app if the website fails.",
  "Don't retry a payment repeatedly. Check your account later to avoid duplicate charges.",
  "Never share login codes with anyone who contacts you during an outage. Scammers exploit outages.",
  "Card payments at stores may still work even if the app is down.",
];
const POWER_TIPS = [
  "Check your breaker panel to rule out a tripped breaker.",
  "Report the outage to your utility. Don't assume someone else has.",
  "Stay away from downed lines and report them to 911.",
  "Unplug sensitive electronics to protect them from a surge when power returns.",
];

type Seed = Omit<Service, "problemTypes" | "troubleshooting" | "aliases" | "states"> &
  Partial<Pick<Service, "problemTypes" | "troubleshooting" | "aliases" | "states">>;

const DEFAULTS: Record<Category, Pick<Service, "problemTypes" | "troubleshooting">> = {
  isp: { problemTypes: ISP_PROBLEMS, troubleshooting: ISP_TIPS },
  tv: { problemTypes: ["tv", "no_connection", "app"], troubleshooting: ISP_TIPS },
  mobile: { problemTypes: MOBILE_PROBLEMS, troubleshooting: MOBILE_TIPS },
  streaming: { problemTypes: ["app", "tv", "login"], troubleshooting: APP_TIPS },
  gaming: { problemTypes: ["no_connection", "login", "app"], troubleshooting: GAMING_TIPS },
  banking: { problemTypes: BANK_PROBLEMS, troubleshooting: BANK_TIPS },
  cloud: { problemTypes: APP_PROBLEMS, troubleshooting: APP_TIPS },
  social: { problemTypes: APP_PROBLEMS, troubleshooting: APP_TIPS },
  power: { problemTypes: ["power"], troubleshooting: POWER_TIPS },
};

const SEEDS: Seed[] = [
  // Internet / ISP
  { slug: "spectrum", name: "Spectrum", category: "isp", baseRate: 40, aliases: ["charter", "charter spectrum", "spectrum internet"],
    states: ["NY", "CA", "TX", "FL", "NC", "OH", "KY", "WI", "MO", "SC", "MI", "TN", "AL", "LA", "NE", "HI", "ME", "MA", "CT", "VA"],
    officialStatusUrl: "https://www.spectrum.net/support/internet/spectrum-outage" },
  { slug: "xfinity", name: "Xfinity (Comcast)", category: "isp", baseRate: 45, aliases: ["comcast", "xfinity internet"],
    states: ["PA", "NJ", "IL", "MI", "FL", "GA", "CA", "CO", "WA", "OR", "MA", "MD", "VA", "TN", "TX", "MN", "IN", "UT"],
    officialStatusUrl: "https://www.xfinity.com/support/status" },
  { slug: "att-internet", name: "AT&T Internet", category: "isp", baseRate: 30, aliases: ["at&t fiber", "att fiber", "at&t internet"],
    states: ["TX", "CA", "FL", "GA", "NC", "IL", "MI", "OH", "TN", "LA", "AL", "MO", "IN", "KY", "SC", "OK", "AR", "KS", "WI", "MS", "NV"] },
  { slug: "verizon-fios", name: "Verizon Fios", category: "isp", baseRate: 18, aliases: ["fios", "verizon internet"],
    states: ["NY", "NJ", "PA", "MA", "MD", "VA", "DE", "RI", "DC"] },
  { slug: "cox", name: "Cox", category: "isp", baseRate: 14, aliases: ["cox communications"],
    states: ["AZ", "CA", "NV", "OK", "KS", "LA", "VA", "RI", "NE", "IA", "AR", "FL", "GA", "CT", "ID", "OH"] },
  { slug: "optimum", name: "Optimum", category: "isp", baseRate: 12, aliases: ["altice", "suddenlink"],
    states: ["NY", "NJ", "CT", "TX", "WV", "LA", "AR", "OK", "NC", "MO"] },
  { slug: "frontier", name: "Frontier", category: "isp", baseRate: 10, aliases: ["frontier fiber"],
    states: ["CA", "TX", "FL", "CT", "NY", "IN", "OH", "IL", "WV", "PA", "MN", "WI", "AZ", "NC", "SC"] },
  { slug: "centurylink", name: "CenturyLink / Quantum Fiber", category: "isp", baseRate: 10, aliases: ["lumen", "quantum fiber"],
    states: ["CO", "AZ", "WA", "OR", "MN", "UT", "NM", "NV", "ID", "MT", "WY", "IA", "NE", "MO", "LA"] },
  { slug: "google-fiber", name: "Google Fiber", category: "isp", baseRate: 3, aliases: ["gfiber"],
    states: ["MO", "KS", "TX", "UT", "TN", "NC", "GA", "AL", "CA", "AZ", "CO", "NE", "IA", "ID", "NV"] },
  { slug: "starlink", name: "Starlink", category: "isp", baseRate: 6, aliases: ["spacex starlink"] },
  { slug: "tmobile-home", name: "T-Mobile Home Internet", category: "isp", baseRate: 8, aliases: ["t-mobile 5g home internet"] },
  { slug: "mediacom", name: "Mediacom", category: "isp", baseRate: 4, aliases: [],
    states: ["IA", "IL", "MO", "MN", "WI", "GA", "AL", "FL", "MS", "TN", "KY", "IN", "DE", "SD", "KS", "CA"] },
  { slug: "windstream", name: "Windstream / Kinetic", category: "isp", baseRate: 4, aliases: ["kinetic"],
    states: ["GA", "KY", "AR", "NC", "OH", "PA", "AL", "IA", "NE", "NY", "TX", "MS", "OK", "FL", "MN", "NM", "SC"] },
  { slug: "wow", name: "WOW!", category: "isp", baseRate: 3, aliases: ["wideopenwest"],
    states: ["MI", "OH", "IL", "IN", "AL", "GA", "FL", "SC", "TN"] },

  // Mobile
  { slug: "verizon-wireless", name: "Verizon Wireless", category: "mobile", baseRate: 35, aliases: ["verizon"] },
  { slug: "att-wireless", name: "AT&T Wireless", category: "mobile", baseRate: 35, aliases: ["at&t", "att", "at&t mobility"] },
  { slug: "tmobile", name: "T-Mobile", category: "mobile", baseRate: 35, aliases: ["t-mobile", "metro by t-mobile", "sprint"] },
  { slug: "boost", name: "Boost Mobile", category: "mobile", baseRate: 5, aliases: ["boost"] },

  // TV / Cable
  { slug: "directv", name: "DIRECTV", category: "tv", baseRate: 8, aliases: ["directv stream"] },
  { slug: "dish", name: "DISH", category: "tv", baseRate: 6, aliases: ["dish network", "sling"] },
  { slug: "youtube-tv", name: "YouTube TV", category: "tv", baseRate: 8, aliases: [] },

  // Streaming
  { slug: "netflix", name: "Netflix", category: "streaming", baseRate: 20, aliases: [] },
  { slug: "youtube", name: "YouTube", category: "streaming", baseRate: 25, aliases: [] },
  { slug: "disney-plus", name: "Disney+", category: "streaming", baseRate: 8, aliases: ["disney plus", "disneyplus"] },
  { slug: "hulu", name: "Hulu", category: "streaming", baseRate: 7, aliases: [] },
  { slug: "max", name: "Max", category: "streaming", baseRate: 6, aliases: ["hbo max", "hbo"] },
  { slug: "spotify", name: "Spotify", category: "streaming", baseRate: 10, aliases: [] },
  { slug: "prime-video", name: "Prime Video", category: "streaming", baseRate: 7, aliases: ["amazon prime video"] },

  // Gaming
  { slug: "psn", name: "PlayStation Network", category: "gaming", baseRate: 15, aliases: ["playstation", "psn"] },
  { slug: "xbox-live", name: "Xbox Live", category: "gaming", baseRate: 12, aliases: ["xbox", "xbox network"] },
  { slug: "steam", name: "Steam", category: "gaming", baseRate: 10, aliases: ["valve"] },
  { slug: "fortnite", name: "Fortnite", category: "gaming", baseRate: 9, aliases: ["epic games"],
    statuspageApi: "https://status.epicgames.com/api/v2/summary.json", officialStatusUrl: "https://status.epicgames.com" },
  { slug: "roblox", name: "Roblox", category: "gaming", baseRate: 12, aliases: [] },
  { slug: "nintendo", name: "Nintendo Switch Online", category: "gaming", baseRate: 5, aliases: ["nintendo"] },

  // Banking & Payments
  { slug: "chase", name: "Chase", category: "banking", baseRate: 10, aliases: ["jpmorgan chase", "chase bank"] },
  { slug: "bank-of-america", name: "Bank of America", category: "banking", baseRate: 9, aliases: ["bofa"] },
  { slug: "wells-fargo", name: "Wells Fargo", category: "banking", baseRate: 8, aliases: [] },
  { slug: "capital-one", name: "Capital One", category: "banking", baseRate: 7, aliases: [] },
  { slug: "paypal", name: "PayPal", category: "banking", baseRate: 6, aliases: ["venmo"] },
  { slug: "cash-app", name: "Cash App", category: "banking", baseRate: 6, aliases: ["square cash"] },

  // Cloud & Dev
  { slug: "aws", name: "Amazon Web Services", category: "cloud", baseRate: 4, aliases: ["aws", "amazon aws"],
    officialStatusUrl: "https://health.aws.amazon.com/health/status" },
  { slug: "cloudflare", name: "Cloudflare", category: "cloud", baseRate: 3, aliases: [],
    statuspageApi: "https://www.cloudflarestatus.com/api/v2/summary.json", officialStatusUrl: "https://www.cloudflarestatus.com" },
  { slug: "github", name: "GitHub", category: "cloud", baseRate: 3, aliases: [],
    statuspageApi: "https://www.githubstatus.com/api/v2/summary.json", officialStatusUrl: "https://www.githubstatus.com" },
  { slug: "microsoft-365", name: "Microsoft 365", category: "cloud", baseRate: 6, aliases: ["outlook", "teams", "office 365"] },
  { slug: "zoom", name: "Zoom", category: "cloud", baseRate: 4, aliases: [],
    statuspageApi: "https://status.zoom.us/api/v2/summary.json", officialStatusUrl: "https://status.zoom.us" },

  // Social
  { slug: "instagram", name: "Instagram", category: "social", baseRate: 18, aliases: [] },
  { slug: "facebook", name: "Facebook", category: "social", baseRate: 15, aliases: ["meta"] },
  { slug: "x", name: "X (Twitter)", category: "social", baseRate: 12, aliases: ["twitter"] },
  { slug: "discord", name: "Discord", category: "social", baseRate: 10, aliases: [],
    statuspageApi: "https://discordstatus.com/api/v2/summary.json", officialStatusUrl: "https://discordstatus.com" },
  { slug: "tiktok", name: "TikTok", category: "social", baseRate: 12, aliases: [] },

  // Power
  { slug: "power-grid", name: "Power (all utilities)", category: "power", baseRate: 15, aliases: ["power outage", "electricity"] },
];

export const SERVICES: Service[] = SEEDS.map((s) => ({
  aliases: [],
  states: [],
  ...DEFAULTS[s.category],
  ...s,
}));

const BY_SLUG = new Map(SERVICES.map((s) => [s.slug, s]));
const BY_ALIAS = new Map<string, Service>();
for (const s of SERVICES) {
  for (const name of [s.slug, s.name, ...s.aliases]) BY_ALIAS.set(normalizeName(name), s);
}

function normalizeName(name: string): string {
  return name.toLowerCase().replace(/[^a-z0-9&]+/g, " ").trim();
}

export function getService(slug: string): Service | undefined {
  return BY_SLUG.get(slug);
}

/** Resolve a provider name as a source spells it ("Charter", "Comcast") to our service. */
export function resolveService(name: string): Service | undefined {
  return BY_SLUG.get(name) ?? BY_ALIAS.get(normalizeName(name));
}

export function servicesInState(state: string): Service[] {
  return SERVICES.filter((s) => s.states.length === 0 || s.states.includes(state));
}

