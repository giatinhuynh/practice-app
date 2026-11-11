import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "NetworkOps Lite · Synthetic workshop",
  description: "A synthetic network operations teaching application for an agentic SDLC workshop.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en-AU"><body>{children}</body></html>;
}
