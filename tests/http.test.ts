import { describe, expect, it } from "vitest";
import { clientIp } from "@/lib/http";

const req = (headers: Record<string, string>) => new Request("http://localhost/", { headers });

describe("clientIp", () => {
  it("uses Fly's client IP header when present", () => {
    expect(clientIp(req({ "fly-client-ip": "203.0.113.7", "x-forwarded-for": "1.2.3.4, 203.0.113.7" }))).toBe("203.0.113.7");
  });

  it("ignores a client-supplied first X-Forwarded-For entry", () => {
    // The client sent "1.2.3.4"; our proxy appended the real address.
    expect(clientIp(req({ "x-forwarded-for": "1.2.3.4, 198.51.100.20" }))).toBe("198.51.100.20");
  });

  it("falls back when no proxy headers are set", () => {
    expect(clientIp(req({}))).toBe("0.0.0.0");
  });
});
