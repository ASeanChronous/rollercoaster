import { NextResponse } from "next/server";
import { lookupZip } from "./geo";
import type { Scope } from "./engine";

export function json(data: unknown, init?: ResponseInit): NextResponse {
  return NextResponse.json(data, { ...init, headers: { "Cache-Control": "no-store", ...init?.headers } });
}

export function error(message: string, status = 400, headers?: Record<string, string>): NextResponse {
  return json({ error: message }, { status, headers });
}

/** Read ?zip= or ?state= into a scope. Returns a string error for bad input. */
export function scopeFrom(params: URLSearchParams): Scope | string {
  const zip = params.get("zip")?.trim();
  if (zip) return lookupZip(zip) ? { zip } : "Enter a valid US ZIP code.";
  const state = params.get("state")?.trim().toUpperCase();
  if (state) return /^[A-Z]{2}$/.test(state) ? { state } : "Unknown state.";
  return {};
}

/**
 * The visitor's IP, for rate limiting. Only trust what our own proxy sets:
 * Fly-Client-IP on Fly.io, otherwise the last X-Forwarded-For entry (the one
 * the proxy in front of us appended). The first entry is whatever the client
 * sent, so trusting it would let anyone dodge the per-IP limits.
 */
export function clientIp(req: Request): string {
  const fly = req.headers.get("fly-client-ip")?.trim();
  if (fly) return fly;
  const hops = req.headers.get("x-forwarded-for")?.split(",").map((h) => h.trim()).filter(Boolean);
  return hops?.at(-1) || req.headers.get("x-real-ip")?.trim() || "0.0.0.0";
}
