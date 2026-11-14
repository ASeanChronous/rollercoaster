"use client";

// Severe-weather warnings that may explain an outage. Context only: they
// never change a service's status.

import { useLiveJson } from "./LiveProvider";

interface Alert {
  id: string;
  event: string;
  headline: string;
  areaDesc: string;
  ends?: string;
}

export function WeatherAlerts({ query, title }: { query: string; title: string }) {
  const { data } = useLiveJson<{ alerts: Alert[] }>(`/api/weather?${query}`);
  const alerts = data?.alerts ?? [];
  if (!alerts.length) return null;
  return (
    <div className="callout" role="note">
      <strong>{title}</strong>
      <ul className="reasons">
        {alerts.slice(0, 5).map((a) => (
          <li key={a.id}>
            <strong>{a.event}</strong>: {a.areaDesc}
            {a.ends && ` (until ${new Date(a.ends).toLocaleString("en-US", { weekday: "short", hour: "numeric", minute: "2-digit" })})`}
          </li>
        ))}
      </ul>
      <div className="tiny" style={{ marginTop: 6 }}>
        From the National Weather Service.{alerts.length > 5 ? ` ${alerts.length - 5} more not shown.` : ""}
      </div>
    </div>
  );
}
