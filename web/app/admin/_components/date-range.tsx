"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import type { RangeKey } from "../_lib/range";

// 날짜 구간 선택 — 프리셋 링크 + 커스텀 from~to. 현재 view를 유지.

const PRESETS: { key: RangeKey; label: string }[] = [
  { key: "today", label: "오늘" },
  { key: "7d", label: "7일" },
  { key: "30d", label: "30일" },
  { key: "all", label: "전체" },
];

export function DateRange({
  view,
  activeKey,
  fromStr,
  toStr,
}: {
  view: string;
  activeKey: RangeKey | "custom";
  fromStr: string;
  toStr: string;
}) {
  const router = useRouter();
  const [from, setFrom] = useState(fromStr);
  const [to, setTo] = useState(toStr);

  function applyCustom(e: React.FormEvent) {
    e.preventDefault();
    if (!from || !to) return;
    router.push(`/admin?view=${view}&from=${from}&to=${to}`);
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      <div className="flex gap-1.5 text-xs">
        {PRESETS.map((p) => {
          const active = activeKey === p.key;
          const href = `/admin?view=${view}${p.key === "all" ? "" : `&range=${p.key}`}`;
          return (
            <a
              key={p.key}
              href={href}
              className={`rounded-full px-3 py-1 transition ${
                active
                  ? "bg-fg text-bg"
                  : "border border-outline-soft text-fg-muted hover:text-fg"
              }`}
            >
              {p.label}
            </a>
          );
        })}
      </div>

      <form onSubmit={applyCustom} className="flex items-center gap-1.5 text-xs">
        <input
          type="date"
          value={from}
          max={to || undefined}
          onChange={(e) => setFrom(e.target.value)}
          className="rounded-lg border border-outline bg-bg/60 px-2 py-1 text-fg outline-none focus:border-primary"
        />
        <span className="text-fg-faint">~</span>
        <input
          type="date"
          value={to}
          min={from || undefined}
          onChange={(e) => setTo(e.target.value)}
          className="rounded-lg border border-outline bg-bg/60 px-2 py-1 text-fg outline-none focus:border-primary"
        />
        <button
          type="submit"
          className={`rounded-full px-3 py-1 transition ${
            activeKey === "custom"
              ? "bg-fg text-bg"
              : "border border-outline-soft text-fg-muted hover:text-fg"
          }`}
        >
          적용
        </button>
      </form>
    </div>
  );
}
