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

export function clientIp(req: Request): string {
  const fwd = req.headers.get("x-forwarded-for");
  return fwd?.split(",")[0].trim() || req.headers.get("x-real-ip") || "0.0.0.0";
}
