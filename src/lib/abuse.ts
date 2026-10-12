// Anti-abuse for crowd reports (PRD §6.7): rate limits, first-time-reporter
// down-weighting, and burst detection from a single network block.

import { createHash } from "node:crypto";
import { MINUTE, HOUR } from "./time";

export const LIMITS = {
  perDeviceServiceWindow: 10 * MINUTE,
  perIpPerHour: 12,
  burstWindow: 10 * MINUTE,
  /** More than this many reports from one /24 (or /48) in the burst window looks coordinated. */
  burstThreshold: 25,
  firstTimeWeight: 0.6,
  burstWeight: 0.1,
};

export type Verdict = { ok: true; weight: number; deviceHash: string } | { ok: false; reason: string; retryAfterSec: number };

export function hashId(value: string): string {
  return createHash("sha256").update(`rollercoaster:${value}`).digest("hex").slice(0, 16);
}

/** Network block a client IP belongs to: /24 for IPv4, /48 for IPv6. */
export function networkBlock(ip: string): string {
  if (ip.includes(":")) return ip.split(":").slice(0, 3).join(":");
  return ip.split(".").slice(0, 3).join(".");
}

export class AbuseGuard {
  private readonly lastByDeviceService = new Map<string, number>();
  private readonly ipHits = new Map<string, number[]>();
  private readonly blockHits = new Map<string, number[]>();
  private readonly seenDevices = new Map<string, number>();

  check(params: { deviceId: string; ip: string; serviceSlug: string; now: number }): Verdict {
    const { now, serviceSlug } = params;
    const deviceHash = hashId(params.deviceId || params.ip);
    const ipHash = hashId(params.ip);
    const blockHash = hashId(networkBlock(params.ip));

    const dsKey = `${deviceHash}|${serviceSlug}`;
    const last = this.lastByDeviceService.get(dsKey);
    if (last !== undefined && now - last < LIMITS.perDeviceServiceWindow) {
      return { ok: false, reason: "You already reported this service recently. Thanks, it's counted.", retryAfterSec: Math.ceil((LIMITS.perDeviceServiceWindow - (now - last)) / 1000) };
    }

    const ipList = recent(this.ipHits, ipHash, now - HOUR);
    if (ipList.length >= LIMITS.perIpPerHour) {
      return { ok: false, reason: "Too many reports from this network. Try again later.", retryAfterSec: Math.ceil((ipList[0] + HOUR - now) / 1000) };
    }

    const blockList = recent(this.blockHits, blockHash, now - LIMITS.burstWindow);

    let weight = 1;
    if (!this.seenDevices.has(deviceHash)) weight = LIMITS.firstTimeWeight;
    if (blockList.length >= LIMITS.burstThreshold) weight = LIMITS.burstWeight;

    this.lastByDeviceService.set(dsKey, now);
    ipList.push(now);
    blockList.push(now);
    this.seenDevices.set(deviceHash, now);
    return { ok: true, weight, deviceHash };
  }
}

function recent(map: Map<string, number[]>, key: string, since: number): number[] {
  const list = (map.get(key) ?? []).filter((t) => t >= since);
  map.set(key, list);
  return list;
}
