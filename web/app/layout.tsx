import type { Metadata, Viewport } from "next";
import "./globals.css";

const SITE_URL = "https://encore.app";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "앙코르 — 당신의 아이돌, 함께 자라요",
    template: "%s | 앙코르",
  },
  description:
    "팬이 아이돌의 성장을 함께하는 동반형 팬덤 서비스. 지켜보고, 대화하고, 후원하며, 한 명의 아이돌을 무대로 데려갑니다.",
  keywords: [
    "앙코르",
    "encore",
    "팬 채팅",
    "아이돌 응원",
    "팬덤 앱",
    "아이돌 채팅",
    "팬 커뮤니티",
  ],
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "앙코르 — 당신의 아이돌, 함께 자라요",
    description:
      "지켜보고, 대화하고, 후원하며. 작은 응원이 한 명의 아이돌을 무대로 데려갑니다.",
    url: SITE_URL,
    siteName: "앙코르",
    type: "website",
    locale: "ko_KR",
  },
  twitter: {
    card: "summary_large_image",
    title: "앙코르 — 당신의 아이돌, 함께 자라요",
    description:
      "지켜보고, 대화하고, 후원하며. 작은 응원이 한 명의 아이돌을 무대로 데려갑니다.",
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
      <body className="min-h-full bg-bg text-fg kr-keep">{children}</body>
    </html>
  );
}
