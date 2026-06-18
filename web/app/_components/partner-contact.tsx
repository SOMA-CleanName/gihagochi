"use client";

import { track } from "@/app/_lib/track";

/**
 * 소속사 컨택 채널 — 클릭을 cta_click(label=partner_*)으로 추적.
 * mailto / 외부 SNS라 TrackedLink(next/link) 대신 순수 <a> + onClick.
 */
const CHANNELS = [
  {
    label: "partner_email",
    href: "mailto:encoreofficial00@gmail.com?subject=%5B%EC%95%99%EC%BD%94%EB%A5%B4%5D%20%EC%86%8C%EC%86%8D%EC%82%AC%20%ED%8C%8C%ED%8A%B8%EB%84%88%EC%8B%AD%20%EB%AC%B8%EC%9D%98",
    title: "이메일",
    value: "encoreofficial00@gmail.com",
  },
  {
    label: "partner_instagram",
    href: "https://www.instagram.com/encoreofficial00/",
    title: "인스타그램",
    value: "@encoreofficial00",
  },
  {
    label: "partner_x",
    href: "https://x.com/encoreofficial0",
    title: "X (트위터)",
    value: "@encoreofficial0",
  },
] as const;

export function PartnerContact() {
  return (
    <div className="grid gap-3 sm:grid-cols-3">
      {CHANNELS.map((c) => {
        const external = c.href.startsWith("http");
        return (
          <a
            key={c.label}
            href={c.href}
            {...(external
              ? { target: "_blank", rel: "noopener noreferrer" }
              : {})}
            onClick={() => track("cta_click", { label: c.label })}
            className="text-card group flex flex-col gap-1 rounded-2xl border border-outline-soft transition hover:border-primary"
          >
            <span className="text-xs font-medium text-fg-muted">{c.title}</span>
            <span className="text-sm font-semibold text-fg transition group-hover:text-primary">
              {c.value}
            </span>
          </a>
        );
      })}
    </div>
  );
}
