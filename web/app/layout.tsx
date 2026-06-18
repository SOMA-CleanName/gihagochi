import type { Metadata, Viewport } from "next";
import { LightSticks } from "./_components/light-sticks";
import { StageLights } from "./_components/stage-lights";
import { TrackPage } from "./_components/track-page";
import "./globals.css";

const SITE_URL = "https://encore.app";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "앙코르 — 지하돌 팬덤 플랫폼 · 소속사 파트너 모집",
    template: "%s | 앙코르",
  },
  description:
    "소속 아이돌의 첫 팬덤을 디지털에서. 입점 0원, 멤버 부담 없이 매일의 채팅으로 팬을 모으고 후원으로 수익을 나누는 지하돌 팬덤 플랫폼. 소속사·아이돌 파트너를 찾습니다.",
  keywords: [
    "앙코르",
    "encore",
    "지하돌",
    "아이돌 소속사",
    "팬덤 플랫폼",
    "아이돌 수익화",
    "팬 채팅",
    "소속사 제휴",
  ],
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "앙코르 — 지하돌 팬덤 플랫폼 · 소속사 파트너 모집",
    description:
      "소속 아이돌의 첫 팬덤을 디지털에서. 입점 0원·수익 셰어로 팬덤을 만들고 무대로 잇습니다.",
    url: SITE_URL,
    siteName: "앙코르",
    type: "website",
    locale: "ko_KR",
  },
  twitter: {
    card: "summary_large_image",
    title: "앙코르 — 지하돌 팬덤 플랫폼 · 소속사 파트너 모집",
    description:
      "소속 아이돌의 첫 팬덤을 디지털에서. 입점 0원·수익 셰어로 팬덤을 만들고 무대로 잇습니다.",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: { index: true, follow: true },
  },
};

export const viewport: Viewport = {
  themeColor: "#0a0a0f",
  colorScheme: "dark",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" className="h-full">
      <head>
        <link
          rel="stylesheet"
          href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable.min.css"
        />
      </head>
      <body className="min-h-full bg-bg text-fg kr-keep">
        <StageLights />
        <LightSticks />
        <TrackPage />
        <div className="relative z-10">{children}</div>
      </body>
    </html>
  );
}
