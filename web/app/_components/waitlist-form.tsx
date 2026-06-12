"use client";

import { useState } from "react";

type Role = "fan" | "idol";
type Status = "idle" | "submitting" | "success" | "error";

// 배포 시 Vercel 환경변수로 설정 (Formspree 등 폼 엔드포인트)
const ENDPOINT = process.env.NEXT_PUBLIC_WAITLIST_ENDPOINT;

export function WaitlistForm() {
  const [email, setEmail] = useState("");
  const [role, setRole] = useState<Role>("fan");
  const [idolName, setIdolName] = useState("");
  const [idolSns, setIdolSns] = useState("");
  const [status, setStatus] = useState<Status>("idle");

  const emailValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!emailValid || status === "submitting") return;
    setStatus("submitting");

    const payload = {
      email,
      role: role === "idol" ? "아이돌" : "팬",
      ...(role === "idol" ? { idolName, idolSns } : {}),
    };

    try {
      if (ENDPOINT) {
        const res = await fetch(ENDPOINT, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },
          body: JSON.stringify(payload),
        });
        if (!res.ok) throw new Error("submit failed");
      } else {
        // 엔드포인트 미설정 시 UI 동작 확인용 (배포 시 NEXT_PUBLIC_WAITLIST_ENDPOINT 설정 필요)
        await new Promise((r) => setTimeout(r, 600));
      }
      setStatus("success");
    } catch {
      setStatus("error");
    }
  }

  if (status === "success") {
    return (
      <div className="mx-auto mt-10 w-full max-w-md rounded-2xl border border-primary/40 bg-surface-2/80 p-8 text-center backdrop-blur-md animate-neon-pulse">
        <p className="text-2xl">🎉</p>
        <p className="mt-3 text-lg font-semibold text-fg">사전신청 완료!</p>
        <p className="mt-2 text-sm leading-relaxed text-fg-muted">
          {role === "idol"
            ? "감사합니다. 합류 절차 안내를 위해 곧 연락드릴게요."
            : "출시되면 가장 먼저 알려드릴게요. 무대에서 만나요."}
        </p>
      </div>
    );
  }

  return (
    <form
      onSubmit={onSubmit}
      className="mx-auto mt-10 w-full max-w-md rounded-2xl border border-outline-soft bg-surface-2/70 p-6 text-left backdrop-blur-md sm:p-7"
    >
      {/* 역할 토글 */}
      <div className="grid grid-cols-2 gap-2 rounded-xl bg-bg/60 p-1">
        {(["fan", "idol"] as const).map((r) => {
          const active = role === r;
          return (
            <button
              key={r}
              type="button"
              onClick={() => setRole(r)}
              className={`rounded-lg py-2.5 text-sm font-semibold transition ${
                active
                  ? "bg-primary text-primary-on shadow-[0_0_18px_rgba(199,112,255,0.45)]"
                  : "text-fg-muted hover:text-fg"
              }`}
            >
              {r === "fan" ? "팬으로 신청" : "아이돌로 신청"}
            </button>
          );
        })}
      </div>

      {/* 이메일 */}
      <label className="mt-4 block">
        <span className="text-xs font-medium text-fg-muted">이메일</span>
        <input
          type="email"
          inputMode="email"
          autoComplete="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@example.com"
          className="mt-1.5 w-full rounded-xl border border-outline bg-bg/60 px-4 py-3 text-sm text-fg outline-none transition placeholder:text-fg-faint focus:border-primary focus:ring-2 focus:ring-primary/30"
        />
      </label>

      {/* 아이돌 전용 추가 필드 (시드 영입 컨택용) */}
      {role === "idol" && (
        <div className="mt-3 space-y-3 rounded-xl border border-tertiary/25 bg-tertiary-container/15 p-3">
          <p className="text-[11px] leading-relaxed text-tertiary-container-on/90">
            합류 안내를 위해 알려주세요. (선택)
          </p>
          <input
            type="text"
            value={idolName}
            onChange={(e) => setIdolName(e.target.value)}
            placeholder="활동명 / 팀명"
            className="w-full rounded-xl border border-outline bg-bg/60 px-4 py-2.5 text-sm text-fg outline-none transition placeholder:text-fg-faint focus:border-tertiary focus:ring-2 focus:ring-tertiary/30"
          />
          <input
            type="text"
            inputMode="url"
            value={idolSns}
            onChange={(e) => setIdolSns(e.target.value)}
            placeholder="SNS 링크 (인스타 / X 등)"
            className="w-full rounded-xl border border-outline bg-bg/60 px-4 py-2.5 text-sm text-fg outline-none transition placeholder:text-fg-faint focus:border-tertiary focus:ring-2 focus:ring-tertiary/30"
          />
        </div>
      )}

      {/* 제출 */}
      <button
        type="submit"
        disabled={!emailValid || status === "submitting"}
        className="mt-5 w-full rounded-xl bg-primary py-3.5 text-sm font-semibold text-primary-on transition hover:bg-primary-hover disabled:cursor-not-allowed disabled:opacity-40"
      >
        {status === "submitting" ? "신청 중…" : "사전신청 하기"}
      </button>

      {status === "error" && (
        <p className="mt-3 text-center text-xs text-error">
          잠시 후 다시 시도해 주세요.
        </p>
      )}
      <p className="mt-3 text-center text-[11px] leading-relaxed text-fg-faint">
        출시 알림 외 다른 용도로 사용하지 않아요.
      </p>
    </form>
  );
}
