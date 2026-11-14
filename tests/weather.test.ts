import { describe, expect, it } from "vitest";
import { parseAlerts } from "@/lib/weather";
import sample from "./fixtures/nws-alerts.json";

describe("parseAlerts", () => {
  const alerts = parseAlerts(sample);

  it("keeps outage-relevant warnings from a real NWS response", () => {
    expect(alerts.some((a) => a.event === "Flood Warning")).toBe(true);
    expect(alerts.every((a) => a.states.length > 0)).toBe(true);
  });

  it("drops frost and marine-only alerts", () => {
    expect(alerts.some((a) => a.event === "Freeze Warning")).toBe(false);
    expect(alerts.some((a) => a.event === "Heavy Freezing Spray Warning")).toBe(false);
  });

  it("reads states from UGC zone codes and ignores marine zones", () => {
    const parsed = parseAlerts({
      features: [{ properties: { event: "Tornado Warning", geocode: { UGC: ["TXC113", "TXC085", "GMZ250"] } } }],
    });
    expect(parsed[0].states).toEqual(["TX"]);
  });
});
