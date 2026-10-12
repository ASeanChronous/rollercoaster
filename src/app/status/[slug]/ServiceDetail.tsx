"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useLive, useLiveJson } from "@/components/LiveProvider";
import { ReportButton } from "@/components/ReportButton";
import { ReportCurve, type CurvePoint } from "@/components/ReportCurve";
import { StatusBadge } from "@/components/StatusBadge";
import { STATES } from "@/lib/geo-states";
import { CATEGORY_LABEL, PROBLEM_LABEL, type ProblemType, type Service, type StatusLevel, type StatusResult } from "@/lib/types";

interface Detail {
  status: StatusResult;
  national?: StatusResult;
  curve: CurvePoint[];
  breakdown: {
    total: number;
    problems: { type: ProblemType; share: number }[];
    places: { label: string; state: string; zip?: string; count: number }[];
    comments: { at: number; text: string; zip: string }[];
  };
  history: { area: string; start: number; end?: number; peak: StatusLevel }[];
  uptime24h: number;
  sources: { id: string; name: string; url: string; attribution: string }[];
}

type Scope = { kind: "us" } | { kind: "zip"; zip: string } | { kind: "state"; state: string };

const stateName = (c: string) => STATES.find((s) => s.code === c)?.name ?? c;
const fmtTime = (t: number) => new Date(t).toLocaleString("en-US", { weekday: "short", hour: "numeric", minute: "2-digit" });
const fmtDur = (ms: number) => {
  const m = Math.round(ms / 60_000);
  return m < 60 ? `${m} min` : `${Math.floor(m / 60)} hr ${m % 60 ? `${m % 60} min` : ""}`.trim();
};

export function ServiceDetail({ service, initialZip, initialState }: { service: Service; initialZip?: string; initialState?: string }) {
  const { location } = useLive();
  const [scope, setScope] = useState<Scope>(initialZip ? { kind: "zip", zip: initialZip } : initialState ? { kind: "state", state: initialState } : { kind: "us" });

  // Default to the user's saved location when the URL doesn't name one.
  useEffect(() => {
    if (!initialZip && !initialState && location) setScope({ kind: "zip", zip: location.zip });
  }, [location, initialZip, initialState]);

  const q = scope.kind === "zip" ? `?zip=${scope.zip}` : scope.kind === "state" ? `?state=${scope.state}` : "";
  const { data, error } = useLiveJson<Detail>(`/api/services/${service.slug}${q}`);

  const where =
    scope.kind === "zip"
      ? `near ${scope.zip === location?.zip ? `${location.city}, ${location.state}` : scope.zip}`
      : scope.kind === "state"
        ? `in ${stateName(scope.state)}`
        : "nationwide";

  const s = data?.status;
  const flagging = s ? s.sourcesReporting.length : 0;

  return (
    <div className="stack">
      <div className="tiny">
        <Link href="/">Overview</Link> / {CATEGORY_LABEL[service.category]} / {service.name}
      </div>

      <div className="row" style={{ alignItems: "flex-start" }}>
        <div style={{ flex: "1 1 320px" }}>
          <h1>Is {service.name} down?</h1>
          <div className="row">
            {s ? <StatusBadge level={s.level} large /> : <span className="muted">Loading…</span>}
            <span className="muted">{where}</span>
          </div>
        </div>
        <div className="row">
          <ReportButton slug={service.slug} name={service.name} problemTypes={service.problemTypes} />
          <Link className="btn" href={`/alerts?service=${service.slug}`}>
            Get alerts
          </Link>
        </div>
      </div>

      <div className="chips" role="group" aria-label="Area">
        {location && (
          <button className="chip" aria-pressed={scope.kind === "zip" && scope.zip === location.zip} onClick={() => setScope({ kind: "zip", zip: location.zip })}>
            Near me ({location.zip})
          </button>
        )}
        {location && (
          <button className="chip" aria-pressed={scope.kind === "state" && scope.state === location.state} onClick={() => setScope({ kind: "state", state: location.state })}>
            {stateName(location.state)}
          </button>
        )}
        <button className="chip" aria-pressed={scope.kind === "us"} onClick={() => setScope({ kind: "us" })}>
          Nationwide
        </button>
      </div>

      {error && <div className="error">{error}</div>}

      {s && data && (
        <>
          <div className="card stack">
            {s.officialMessage && (
              <div className="callout bad">
                <strong>Update from {service.name}:</strong> {s.officialMessage}
                {s.etaAt && <div className="small">Estimated fix: {new Date(s.etaAt).toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" })}</div>}
              </div>
            )}
            <div>
              <strong>
                {s.level === "ok"
                  ? `User reports indicate no current problems with ${service.name} ${where}.`
                  : `${service.name} may be having ${s.level === "problems" ? "an outage" : "issues"} ${where}.`}
              </strong>
              <ul className="reasons">
                {s.reasons.map((r) => (
                  <li key={r}>{r}</li>
                ))}
              </ul>
            </div>
            <div className="kpis">
              <div className="kpi">
                <div className="v">{Math.round(s.current)}</div>
                <div className="l">Reports, last 15 min</div>
              </div>
              <div className="kpi">
                <div className="v">{s.baseline < 1 ? "<1" : Math.round(s.baseline)}</div>
                <div className="l">Normal for this time</div>
              </div>
              <div className="kpi">
                <div className="v">
                  {flagging} of {s.sourcesTotal}
                </div>
                <div className="l">Sources reporting issues</div>
              </div>
              <div className="kpi">
                <div className="v">{Math.round(s.confidence * 100)}%</div>
                <div className="l">Confidence</div>
              </div>
              <div className="kpi">
                <div className="v">{(data.uptime24h * 100).toFixed(1)}%</div>
                <div className="l">Normal nationwide, last 24 hr</div>
              </div>
            </div>
            {flagging > 0 && <div className="small muted">Reporting issues: {s.sourcesReporting.join(", ")}</div>}
            {data.national && data.national.level !== s.level && (
              <div className="small muted">
                Nationwide: <StatusBadge level={data.national.level} />
              </div>
            )}
          </div>

          <div className="card">
            <h2>Reports over the last 24 hours</h2>
            <ReportCurve points={data.curve} label={`${service.name} reports ${where} over 24 hours`} />
          </div>

          <div className="grid-2">
            <div className="card">
              <h2>What people are reporting</h2>
              {data.breakdown.problems.length === 0 ? (
                <p className="muted">No reports in the last hour.</p>
              ) : (
                <ul className="bars">
                  {data.breakdown.problems.map((p) => (
                    <li key={p.type}>
                      <span>{PROBLEM_LABEL[p.type]}</span>
                      <span className="track">
                        <span className="fill" style={{ width: `${Math.max(2, p.share * 100)}%`, display: "block" }} />
                      </span>
                      <span className="pct">{Math.round(p.share * 100)}%</span>
                    </li>
                  ))}
                </ul>
              )}
              <p className="tiny" style={{ marginTop: 8 }}>
                Based on {data.breakdown.total} reports in the last hour.
              </p>
            </div>
            <div className="card">
              <h2>Most reports from</h2>
              {data.breakdown.places.length === 0 ? (
                <p className="muted">No reports in the last hour.</p>
              ) : (
                <table className="data">
                  <tbody>
                    {data.breakdown.places.map((p) => (
                      <tr key={p.label}>
                        <td>
                          {p.zip ? (
                            <button className="btn btn-sm" style={{ border: 0, padding: 0, background: "none", color: "var(--accent-ink)" }} onClick={() => setScope({ kind: "zip", zip: p.zip! })}>
                              {p.label}
                            </button>
                          ) : (
                            <button className="btn btn-sm" style={{ border: 0, padding: 0, background: "none", color: "var(--accent-ink)" }} onClick={() => setScope({ kind: "state", state: p.state })}>
                              {p.label}
                            </button>
                          )}
                        </td>
                        <td className="num">{p.count}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>

          <div className="grid-2">
            <div className="card">
              <h2>{s.level !== "ok" && scope.kind === "zip" ? "It's probably not you" : "Troubleshooting"}</h2>
              {s.level !== "ok" && scope.kind === "zip" && (
                <p>
                  Others near you are reporting the same problem, so it's likely on {service.name}&apos;s side. Restarting your equipment probably won&apos;t help. We&apos;ll
                  keep this page updated; <Link href={`/alerts?service=${service.slug}`}>get an alert</Link> when it&apos;s fixed.
                </p>
              )}
              <ol className="tips">
                {service.troubleshooting.map((t) => (
                  <li key={t}>{t}</li>
                ))}
              </ol>
              {service.officialStatusUrl && (
                <p className="small">
                  <a href={service.officialStatusUrl} target="_blank" rel="noreferrer">
                    {service.name} official status page ↗
                  </a>
                </p>
              )}
            </div>
            <div className="card">
              <h2>Recent comments</h2>
              {data.breakdown.comments.length === 0 ? (
                <p className="muted">No comments in the last hour.</p>
              ) : (
                <ul className="tips" style={{ listStyle: "none", padding: 0 }}>
                  {data.breakdown.comments.map((c) => (
                    <li key={c.at + c.text}>
                      <div>{c.text}</div>
                      <div className="tiny">
                        {c.zip} · {fmtTime(c.at)}
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>

          <div className="card">
            <h2>Outage history (48 hours)</h2>
            {data.history.length === 0 ? (
              <p className="muted">No outages detected.</p>
            ) : (
              <table className="data">
                <thead>
                  <tr>
                    <th>Area</th>
                    <th>Started</th>
                    <th>Duration</th>
                    <th>Worst status</th>
                  </tr>
                </thead>
                <tbody>
                  {data.history.map((h) => (
                    <tr key={h.area + h.start}>
                      <td>{h.area === "US" ? "Nationwide" : stateName(h.area)}</td>
                      <td>{fmtTime(h.start)}</td>
                      <td>{h.end ? fmtDur(h.end - h.start) : "Ongoing"}</td>
                      <td>
                        <StatusBadge level={h.peak} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <p className="tiny">
            Sources for this service: Rollercoaster user reports
            {data.sources.map((src) => (
              <span key={src.id}>
                {" · "}
                <a href={src.url} target="_blank" rel="noreferrer">
                  {src.attribution}
                </a>
              </span>
            ))}
          </p>
        </>
      )}
    </div>
  );
}
