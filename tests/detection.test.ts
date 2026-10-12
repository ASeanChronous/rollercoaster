import { describe, expect, it } from "vitest";
import { BaselineModel, classify, hourOfWeekFactor, poissonTail, priorBaseline15, type ClassifyInput, type SourceVote } from "@/lib/detection";

const NOW = 1_700_000_000_000;

function input(overrides: Partial<ClassifyInput> = {}): ClassifyInput {
  return { now: NOW, current: 4, baseline: 4, distinctCells: 10, wideArea: false, votes: [], sourcesTotal: 3, ...overrides };
}

function vote(overrides: Partial<SourceVote> = {}): SourceVote {
  return { sourceId: "dd", sourceName: "Downdetector", level: "possible", observedAt: NOW - 60_000, ...overrides };
}

describe("classify", () => {
  it("reports no problems at normal volume with no source flags", () => {
    const r = classify(input());
    expect(r.level).toBe("ok");
    expect(r.sourcesReporting).toEqual([]);
  });

  it("flags possible problems at 2× baseline once the spike is statistically clear", () => {
    expect(classify(input({ current: 12, baseline: 6 })).level).toBe("ok"); // 2×, but within random variation
    expect(classify(input({ current: 30, baseline: 12 })).level).toBe("possible");
  });

  it("flags problems at 5× baseline", () => {
    const r = classify(input({ current: 20 }));
    expect(r.level).toBe("problems");
    expect(r.ratio).toBe(5);
  });

  it("does not flag normal random variation in small counts", () => {
    // Expecting 2.5 reports; seeing 5 happens about 1 time in 10 by chance.
    expect(classify(input({ current: 5, baseline: 2.5 })).level).toBe("ok");
  });

  it("computes Poisson tail probabilities", () => {
    expect(poissonTail(0, 3)).toBe(1);
    expect(poissonTail(1, 2)).toBeCloseTo(1 - Math.exp(-2), 10);
    expect(poissonTail(20, 4)).toBeLessThan(1e-7);
    expect(poissonTail(5, 10)).toBeGreaterThan(0.95);
  });

  it("ignores large ratios built on a handful of reports", () => {
    // 2 reports against a tiny baseline is a 4× ratio but too few to mean anything.
    expect(classify(input({ current: 2, baseline: 0.1 })).level).toBe("ok");
  });

  it("does not let a concentrated crowd spike mark a whole state red", () => {
    const r = classify(input({ current: 50, wideArea: true, distinctCells: 1 }));
    expect(r.level).toBe("possible");
  });

  it("escalates to problems when one source and the crowd agree", () => {
    const r = classify(input({ current: 16, votes: [vote()] }));
    expect(r.level).toBe("problems");
    expect(r.sourcesReporting).toHaveLength(2);
  });

  it("treats a single source flag as possible problems", () => {
    expect(classify(input({ votes: [vote({ level: "problems" })] })).level).toBe("possible");
  });

  it("escalates when two independent sources agree", () => {
    const r = classify(input({ votes: [vote(), vote({ sourceId: "on", sourceName: "OutageNow" })] }));
    expect(r.level).toBe("problems");
  });

  it("goes straight to problems on an official confirmation and carries the ETA", () => {
    const r = classify(input({ votes: [vote({ sourceName: "Spectrum (official)", official: true, level: "problems", etaAt: NOW + 3_600_000, message: "Working on it" })] }));
    expect(r.level).toBe("problems");
    expect(r.etaAt).toBe(NOW + 3_600_000);
    expect(r.officialMessage).toBe("Working on it");
    expect(r.confidence).toBeGreaterThan(0.8);
  });

  it("caps a nationwide signal at possible problems until local reports rise", () => {
    const national = [vote({ inherited: true, level: "problems" }), vote({ sourceId: "on", sourceName: "OutageNow", inherited: true, level: "problems" })];
    expect(classify(input({ votes: national })).level).toBe("possible");
    expect(classify(input({ current: 16, votes: national })).level).toBe("problems");
  });

  it("drops stale source signals", () => {
    const r = classify(input({ votes: [vote({ observedAt: NOW - 30 * 60_000, level: "problems" })] }));
    expect(r.level).toBe("ok");
  });

  it("is more confident about problems as more sources agree", () => {
    const one = classify(input({ current: 20 }));
    const three = classify(input({ current: 20, votes: [vote(), vote({ sourceId: "on", sourceName: "OutageNow" })] }));
    expect(three.confidence).toBeGreaterThan(one.confidence);
  });
});

describe("baselines", () => {
  it("expects more reports in the evening than overnight", () => {
    expect(hourOfWeekFactor(20, 2)).toBeGreaterThan(hourOfWeekFactor(3, 2) * 4);
  });

  it("scales the prior by geographic share", () => {
    expect(priorBaseline15(40, 0.5, 12, 2)).toBeCloseTo(priorBaseline15(40, 1, 12, 2) / 2);
  });

  it("uses the prior until enough quiet samples are learned", () => {
    const m = new BaselineModel(0.5, 3);
    m.observe("k", 10, 100, "ok");
    expect(m.baseline("k", 10, 5)).toBe(5);
    m.observe("k", 10, 100, "ok");
    m.observe("k", 10, 100, "ok");
    expect(m.baseline("k", 10, 5)).toBeGreaterThan(5);
  });

  it("does not learn from outage windows", () => {
    const m = new BaselineModel(0.5, 1);
    m.observe("k", 10, 1000, "problems");
    expect(m.baseline("k", 10, 5)).toBe(5);
  });
});
