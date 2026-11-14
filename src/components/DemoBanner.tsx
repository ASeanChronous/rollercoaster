"use client";

// Asks the server whether it's in demo mode. Reading the setting at render time
// would freeze it into pages generated at build time.

import Link from "next/link";
import { useEffect, useState } from "react";

export function DemoBanner() {
  const [demo, setDemo] = useState(false);
  useEffect(() => {
    fetch("/api/health")
      .then((r) => r.json())
      .then((b: { demo?: boolean }) => setDemo(Boolean(b.demo)))
      .catch(() => undefined);
  }, []);
  if (!demo) return null;
  return (
    <div className="demo-banner">
      Demo mode: outages shown are simulated. <Link href="/sources">How data works</Link>
    </div>
  );
}
