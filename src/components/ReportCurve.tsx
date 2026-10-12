"use client";

// Real-time reporting curve (PRD §6.2): reports per 15 minutes over 24 hours,
// with the expected baseline shown as a dashed line and shaded band.

import { useRef, useState } from "react";

export interface CurvePoint {
  t: number;
  reports: number;
  baseline: number;
}

const W = 720;
const H = 220;
const PAD = { top: 12, right: 12, bottom: 26, left: 36 };

function time(t: number) {
  return new Date(t).toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
}

export function ReportCurve({ points, label }: { points: CurvePoint[]; label: string }) {
  const [hover, setHover] = useState<number | null>(null);
  const [showTable, setShowTable] = useState(false);
  const ref = useRef<SVGSVGElement>(null);
  if (!points.length) return null;

  const max = niceMax(Math.max(4, ...points.map((p) => Math.max(p.reports, p.baseline * 2))));
  const iw = W - PAD.left - PAD.right;
  const ih = H - PAD.top - PAD.bottom;
  const x = (i: number) => PAD.left + (i / (points.length - 1)) * iw;
  const y = (v: number) => PAD.top + ih - (v / max) * ih;

  const line = points.map((p, i) => `${i ? "L" : "M"}${x(i).toFixed(1)},${y(p.reports).toFixed(1)}`).join("");
  const area = `${line}L${x(points.length - 1)},${y(0)}L${x(0)},${y(0)}Z`;
  const base = points.map((p, i) => `${i ? "L" : "M"}${x(i).toFixed(1)},${y(p.baseline).toFixed(1)}`).join("");
  // Normal range: up to 2× baseline, where "Possible problems" starts.
  const band =
    points.map((p, i) => `${i ? "L" : "M"}${x(i).toFixed(1)},${y(p.baseline * 2).toFixed(1)}`).join("") +
    `L${x(points.length - 1)},${y(0)}L${x(0)},${y(0)}Z`;

  const ticks = [0, max / 2, max];
  const xTicks = [0, 24, 48, 72, points.length - 1].filter((i) => i < points.length);

  const onMove = (e: React.PointerEvent) => {
    const rect = ref.current?.getBoundingClientRect();
    if (!rect) return;
    const px = ((e.clientX - rect.left) / rect.width) * W;
    const i = Math.round(((px - PAD.left) / iw) * (points.length - 1));
    setHover(Math.max(0, Math.min(points.length - 1, i)));
  };

  const hp = hover !== null ? points[hover] : null;

  return (
    <div className="chart">
      <svg
        ref={ref}
        viewBox={`0 0 ${W} ${H}`}
        role="img"
        aria-label={`${label}. Latest: ${points[points.length - 1].reports} reports in 15 minutes; normal is about ${points[points.length - 1].baseline}.`}
        onPointerMove={onMove}
        onPointerLeave={() => setHover(null)}
      >
        <path className="baseline-band" d={band} />
        <g className="grid">
          {ticks.map((v) => (
            <line key={v} x1={PAD.left} x2={W - PAD.right} y1={y(v)} y2={y(v)} />
          ))}
        </g>
        <g className="axis">
          {ticks.map((v) => (
            <text key={v} x={PAD.left - 6} y={y(v) + 4} textAnchor="end">
              {Math.round(v)}
            </text>
          ))}
          {xTicks.map((i) => (
            <text key={i} x={x(i)} y={H - 6} textAnchor={i === 0 ? "start" : i === points.length - 1 ? "end" : "middle"}>
              {i === points.length - 1 ? "Now" : time(points[i].t)}
            </text>
          ))}
        </g>
        <path className="area" d={area} />
        <path className="baseline-line" d={base} />
        <path className="series" d={line} />
        {hp && hover !== null && (
          <g>
            <line className="crosshair" x1={x(hover)} x2={x(hover)} y1={PAD.top} y2={PAD.top + ih} />
            <circle className="dot" cx={x(hover)} cy={y(hp.reports)} r={4.5} />
          </g>
        )}
        {/* Wide transparent hit area so hovering anywhere works */}
        <rect x={PAD.left} y={PAD.top} width={iw} height={ih} fill="transparent" />
      </svg>
      {hp && hover !== null && (
        <div
          className="tooltip"
          style={{ left: `${(x(hover) / W) * 100}%`, top: 0, transform: `translateX(${hover > points.length * 0.7 ? "-105%" : "8px"})` }}
        >
          <div className="tiny">{time(hp.t - 15 * 60_000)}–{time(hp.t)}</div>
          <div>
            <strong>{hp.reports}</strong> reports
          </div>
          <div className="muted">Normal ≈ {hp.baseline}</div>
        </div>
      )}
      <div className="legend">
        <span>
          <span className="sw" />
          Reports per 15 min
        </span>
        <span>
          <span className="sw base" />
          Normal for this time
        </span>
        <span className="spacer" />
        <button className="btn btn-sm" onClick={() => setShowTable((v) => !v)} aria-expanded={showTable}>
          {showTable ? "Hide table" : "Show as table"}
        </button>
      </div>
      {showTable && (
        <div style={{ maxHeight: 260, overflow: "auto", marginTop: 8 }}>
          <table className="data">
            <thead>
              <tr>
                <th>15 minutes ending</th>
                <th className="num">Reports</th>
                <th className="num">Normal</th>
              </tr>
            </thead>
            <tbody>
              {[...points].reverse().map((p) => (
                <tr key={p.t}>
                  <td>{time(p.t)}</td>
                  <td className="num">{p.reports}</td>
                  <td className="num">{p.baseline}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function niceMax(v: number): number {
  const mag = 10 ** Math.floor(Math.log10(v));
  for (const m of [1, 2, 2.5, 5, 10]) if (v <= m * mag) return m * mag;
  return 10 * mag;
}
