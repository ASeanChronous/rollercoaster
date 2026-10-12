import { beforeAll, describe, expect, it } from "vitest";
import { Engine } from "@/lib/engine";
import { MINUTE } from "@/lib/time";

const NOW = Date.UTC(2026, 9, 12, 23, 0); // a weekday evening in the US
let engine: Engine;

beforeAll(async () => {
  engine = new Engine({ DEMO_MODE: "true" }, NOW);
  await engine.tick(NOW);
}, 60_000);

describe("engine (demo mode)", () => {
  it("detects the seeded Spectrum outage in Texas with official confirmation", () => {
    const s = engine.status("spectrum", { state: "TX" }, NOW);
    expect(s.level).toBe("problems");
    expect(s.sourcesReporting).toContain("Spectrum (official)");
    expect(s.etaAt).toBeGreaterThan(NOW);
  });

  it("shows the outage at ZIP level inside the affected area but not far away", () => {
    expect(engine.status("spectrum", { zip: "75201" }, NOW).level).toBe("problems");
    expect(engine.status("spectrum", { zip: "78701" }, NOW).level).not.toBe("problems");
  });

  it("detects the nationwide PSN outage from multiple sources", () => {
    const s = engine.status("psn", {}, NOW);
    expect(s.level).toBe("problems");
    expect(s.sourcesReporting.length).toBeGreaterThanOrEqual(2);
  });

  it("reports quiet services as no problems", () => {
    expect(engine.status("steam", {}, NOW).level).toBe("ok");
  });

  it("keeps a 24-hour curve whose quiet buckets sit near the baseline", () => {
    const curve = engine.curve("steam", {}, NOW);
    expect(curve).toHaveLength(96);
    const totalReports = curve.reduce((a, p) => a + p.reports, 0);
    const totalBaseline = curve.reduce((a, p) => a + p.baseline, 0);
    expect(totalReports / totalBaseline).toBeGreaterThan(0.6);
    expect(totalReports / totalBaseline).toBeLessThan(1.6);
  });

  it("records resolved incidents in history", () => {
    const h = engine.history({ slug: "xfinity", area: "IL" }, NOW - 24 * 60 * MINUTE);
    expect(h.some((i) => i.end)).toBe(true);
  });

  it("only exposes map cells with at least 5 reports", () => {
    const cells = engine.mapCells({ minutes: 60 }, NOW);
    expect(cells.length).toBeGreaterThan(0);
    expect(cells.every((c) => c.count >= 5)).toBe(true);
  });

  it("accepts a crowd report and rate-limits a repeat", () => {
    const input = { serviceSlug: "steam", zip: "98101", problemType: "login" as const, deviceId: "dev-1", ip: "203.0.113.9" };
    const first = engine.report(input, NOW);
    expect(first.ok).toBe(true);
    const second = engine.report(input, NOW + 1000);
    expect(second.ok).toBe(false);
    if (!second.ok) expect(second.status).toBe(429);
  });

  it("rejects invalid ZIPs and problem types", () => {
    expect(engine.report({ serviceSlug: "steam", zip: "00000", problemType: "login", deviceId: "d", ip: "1.1.1.1" }, NOW).ok).toBe(false);
    expect(engine.report({ serviceSlug: "steam", zip: "98101", problemType: "power", deviceId: "d", ip: "1.1.1.1" }, NOW).ok).toBe(false);
  });

  it("opens an alert thread for a subscriber in the outage area, then resolves it", () => {
    const sub = engine.alerts.subscribe({ zip: "75201", serviceSlugs: ["spectrum"], minLevel: "possible", browser: true, email: "a@example.com" }, NOW);
    const opened = engine.alerts.evaluate(NOW, () => engine.status("spectrum", { zip: "75201" }, NOW));
    expect(opened.map((m) => m.kind)).toEqual(["opened"]);
    // Same status again: no duplicate alert.
    expect(engine.alerts.evaluate(NOW, () => engine.status("spectrum", { zip: "75201" }, NOW))).toEqual([]);
    const quiet = engine.status("steam", {}, NOW);
    const resolved = engine.alerts.evaluate(NOW + 90 * MINUTE, () => quiet);
    expect(resolved[0].kind).toBe("resolved");
    expect(resolved[0].durationMs).toBe(90 * MINUTE);
    expect(engine.email.outbox.length).toBe(2);
    expect(engine.alerts.unsubscribe(sub.id, "wrong-token")).toBe(false);
    expect(engine.alerts.unsubscribe(sub.id, sub.token)).toBe(true);
  });
});
