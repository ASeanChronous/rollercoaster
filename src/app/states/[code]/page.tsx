import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { STATES } from "@/lib/geo-states";
import { StateDetail } from "./StateDetail";

export function generateStaticParams() {
  return STATES.map((s) => ({ code: s.code }));
}

export async function generateMetadata({ params }: { params: Promise<{ code: string }> }): Promise<Metadata> {
  const code = (await params).code.toUpperCase();
  const st = STATES.find((s) => s.code === code);
  return st ? { title: `${st.name} outages right now`, description: `Live internet, mobile, power and other outages in ${st.name}.` } : {};
}

export default async function Page({ params }: { params: Promise<{ code: string }> }) {
  const code = (await params).code.toUpperCase();
  const st = STATES.find((s) => s.code === code);
  if (!st) notFound();
  return <StateDetail code={st.code} name={st.name} />;
}
