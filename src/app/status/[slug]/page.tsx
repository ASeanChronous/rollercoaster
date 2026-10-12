import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getService } from "@/lib/services";
import { ServiceDetail } from "./ServiceDetail";

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const s = getService((await params).slug);
  if (!s) return {};
  return {
    title: `${s.name} down? Live outage status`,
    description: `Is ${s.name} down right now? Live ${s.name} outage reports, map, problem types and troubleshooting tips.`,
  };
}

export default async function Page({ params, searchParams }: { params: Promise<{ slug: string }>; searchParams: Promise<{ zip?: string; state?: string }> }) {
  const { slug } = await params;
  const service = getService(slug);
  if (!service) notFound();
  const sp = await searchParams;
  return <ServiceDetail service={service} initialZip={sp.zip} initialState={sp.state} />;
}
