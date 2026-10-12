import type { Metadata, Viewport } from "next";
import Link from "next/link";
import { LiveProvider } from "@/components/LiveProvider";
import { Nav } from "@/components/Nav";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "Rollercoaster: Is it down right now?", template: "%s · Rollercoaster" },
  description: "Live internet, mobile, streaming, gaming, banking and power outage status across the US, combined from multiple trackers and user reports.",
};

export const viewport: Viewport = { width: "device-width", initialScale: 1 };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const demo = process.env.DEMO_MODE !== "false";
  return (
    <html lang="en">
      <body>
        <LiveProvider>
          {demo && (
            <div className="demo-banner">
              Demo mode: outages shown are simulated. <Link href="/sources">How data works</Link>
            </div>
          )}
          <header className="site-header">
            <div className="container">
              <Link href="/" className="brand">
                <svg width="22" height="22" viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M2 18c3 0 4-10 7-10s3 8 6 8 3-12 7-12" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
                </svg>
                Rollercoaster
              </Link>
              <Nav />
            </div>
          </header>
          <main className="container">{children}</main>
          <footer className="site-footer">
            <div className="container stack">
              <p>
                Rollercoaster combines outage reports from users with data from third-party trackers and official status pages. It is independent and not
                affiliated with any provider listed. Provider names are used only to describe their service status.
              </p>
              <p>
                <Link href="/sources">Data sources &amp; attribution</Link> · <Link href="/sources#privacy">Privacy</Link>
              </p>
            </div>
          </footer>
        </LiveProvider>
      </body>
    </html>
  );
}
