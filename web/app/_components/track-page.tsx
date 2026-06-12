"use client";

import { useEffect } from "react";
import {
  installSessionEndListeners,
  markPageLoad,
  track,
} from "@/app/_lib/track";

const SCROLL_BUCKETS = [25, 50, 75, 100] as const;

function readUtm(): Record<string, string> {
  if (typeof window === "undefined") return {};
  const sp = new URLSearchParams(window.location.search);
  const out: Record<string, string> = {};
  for (const k of ["utm_source", "utm_campaign", "utm_medium", "utm_content", "utm_term"]) {
    const v = sp.get(k);
    if (v) out[k] = v;
  }
  return out;
}

/**
 * 진입 시 page_view(UTM·referrer), 스크롤 도달 시 scroll_depth,
 * 섹션 진입 시 section_view, 이탈 시 session_end.
 * layout에 1회 마운트.
 */
export function TrackPage() {
  // page_view + 세션 종료 리스너
  useEffect(() => {
    markPageLoad();
    const utm = readUtm();
    track("page_view", {
      referrer: (typeof document !== "undefined" ? document.referrer : "").slice(0, 500),
      utm_source: utm.utm_source || "direct",
      utm_campaign: utm.utm_campaign || "",
      utm_medium: utm.utm_medium || "",
      utm_content: utm.utm_content || "",
    });
    return installSessionEndListeners();
  }, []);

  // scroll_depth
  useEffect(() => {
    const fired = new Set<number>();
    function onScroll() {
      const docH = document.documentElement.scrollHeight - window.innerHeight;
      if (docH <= 0) return;
      const pct = (window.scrollY / docH) * 100;
      for (const b of SCROLL_BUCKETS) {
        if (pct >= b && !fired.has(b)) {
          fired.add(b);
          track("scroll_depth", { label: String(b), pct: b });
        }
      }
    }
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // section_view (각 섹션이 화면에 들어오면 1회)
  useEffect(() => {
    const seen = new Set<string>();
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting && e.target.id && !seen.has(e.target.id)) {
            seen.add(e.target.id);
            track("section_view", { label: e.target.id });
          }
        }
      },
      { threshold: 0.5 },
    );
    document.querySelectorAll("section[id]").forEach((s) => io.observe(s));
    return () => io.disconnect();
  }, []);

  return null;
}
