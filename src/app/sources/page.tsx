import type { Metadata } from "next";
import { THRESHOLDS } from "@/lib/detection";
import { getEngine } from "@/lib/engine";
import { StatusBadge } from "@/components/StatusBadge";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Data sources & methodology" };

export default function SourcesPage() {
  const engine = getEngine();
  return (
    <div className="stack">
      <div>
        <h1>Data sources &amp; methodology</h1>
        <p className="muted">How Rollercoaster decides whether something is down, where the data comes from, and what we do with yours.</p>
      </div>

      <div className="card">
        <h2>Sources</h2>
        <table className="data">
          <thead>
            <tr>
              <th>Source</th>
              <th>Type</th>
              <th>State</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Rollercoaster user reports</td>
              <td>Crowd reports</td>
              <td>
                <StatusBadge level="ok" /> Live
              </td>
            </tr>
            {engine.adapters.map((a) => (
              <tr key={a.info.id}>
                <td>
                  <a href={a.info.url} target="_blank" rel="noreferrer">
                    {a.info.name}
                  </a>
                </td>
                <td>{a.info.kind === "official" ? "Official status pages" : "Outage aggregator"}</td>
                <td className="small">
                  {a.enabled ? "Live" : engine.demo && a.info.kind === "aggregator" ? "Simulated (demo mode)" : a.disabledReason}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <p className="tiny" style={{ marginTop: 8 }}>
          Third-party data is used only under a license or partner agreement and is credited wherever it appears. We don&apos;t scrape other sites.
        </p>
        {engine.lastPollErrors.length > 0 && (
          <p className="error small">
            Last feed error: {engine.lastPollErrors[0].source}: {engine.lastPollErrors[0].error}
          </p>
        )}
      </div>

      <div className="card stack">
        <h2>How the status is decided</h2>
        <p>Every service gets one of three statuses, worked out separately for the whole country, each state, and the area within 15 miles of a ZIP code:</p>
        <table className="data">
          <tbody>
            <tr>
              <td><StatusBadge level="ok" /></td>
              <td>Report volume is in the normal range for that time of day and week, and no source flags an issue.</td>
            </tr>
            <tr>
              <td><StatusBadge level="possible" /></td>
              <td>
                Reports are at least {THRESHOLDS.possibleRatio}× normal (and at least {THRESHOLDS.minPossibleReports}), or one other source reports an issue.
              </td>
            </tr>
            <tr>
              <td><StatusBadge level="problems" /></td>
              <td>
                Reports are at least {THRESHOLDS.problemsRatio}× normal (and at least {THRESHOLDS.minProblemsReports}), or two or more independent sources agree, or the
                provider has confirmed an incident.
              </td>
            </tr>
          </tbody>
        </table>
        <p className="small muted">
          &ldquo;Normal&rdquo; is learned for each service, area and hour of the week from quiet periods, so busy evenings don&apos;t look like outages. A report spike
          concentrated in one small area can&apos;t turn a whole state red on its own. Each status shows a confidence score and which sources are behind it.
        </p>
      </div>

      <div className="card stack" id="privacy">
        <h2>Privacy</h2>
        <ul className="tips">
          <li>When you use &ldquo;Use my location&rdquo;, your browser&apos;s coordinates are matched to a ZIP code and then discarded. We keep only the ZIP.</li>
          <li>Reports are stored with a ZIP code and an area about 7 miles across, never an exact location.</li>
          <li>The map only shows an area once it has at least 5 reports, so no single person&apos;s report can be picked out.</li>
          <li>Your device is identified only by a random ID stored in your browser, used to prevent duplicate reports. IP addresses are hashed for rate limiting.</li>
          <li>Alert subscriptions store your ZIP, the services you chose and (if you gave one) your email. You can remove them at any time on the Alerts page.</li>
        </ul>
      </div>
    </div>
  );
}
