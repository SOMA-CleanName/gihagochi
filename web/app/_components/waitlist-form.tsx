"use client";

import { useState } from "react";
import { getSessionId, track } from "@/app/_lib/track";

type Role = "idol" | "agency";
type Status = "idle" | "submitting" | "success" | "error";

const ROLE_KR: Record<Role, string> = { idol: "아이돌", agency: "소속사" };

export function WaitlistForm() {
  const [email, setEmail] = useState("");
  const [role, setRole] = useState<Role>("idol");
  const [name, setName] = useState(""); // 활동명/팀명 or 소속사명
  const [sns, setSns] = useState(""); // SNS or 홈페이지
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState<Status>("idle");

  const emailValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

  function selectRole(r: Role) {
    setRole(r);
    track("role_select", { label: ROLE_KR[r] });
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!emailValid || status === "submitting") return;
    setStatus("submitting");
    track("waitlist_submit_attempt", { label: ROLE_KR[role] });

    const payload = {
      email,
      role: ROLE_KR[role],
      idolName: role === "idol" ? name : "",
      idolSns: role === "idol" ? sns : "",
      company: role === "agency" ? name : "",
      message: role === "agency" ? message : "",
      session_id: getSessionId(),
      path: typeof window !== "undefined" ? window.location.pathname : "",
      referrer: typeof document !== "undefined" ? document.referrer : "",
    };

    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error("submit failed");
      setStatus("success");
    } catch {
      track("waitlist_submit_error", { label: ROLE_KR[role] });
      setStatus("error");
    }
  }

  if (status === "success") {
    return (
      <div className="mx-auto mt-10 w-full max-w-md rounded-2xl border border-primary/40 bg-surface-2/80 p-8 text-center backdrop-blur-md animate-neon-pulse">
        <p className="text-2xl">🎉</p>
        <p className="mt-3 text-lg font-semibold text-fg">
          {role === "agency" ? "문의 접수 완료!" : "신청 완료!"}
        </p>
        <p className="mt-2 text-sm leading-relaxed text-fg-muted">
          {role === "agency"
            ? "감사합니다. 제휴 자료와 함께 빠르게 회신드릴게요."
            : "감사합니다. 합류 절차 안내를 위해 곧 연락드릴게요."}
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
        {(["idol", "agency"] as const).map((r) => {
          const active = role === r;
          return (
            <button
              key={r}
              type="button"
              onClick={() => selectRole(r)}
              className={`rounded-lg py-2.5 text-sm font-semibold transition ${
                active
                  ? "bg-primary text-primary-on shadow-[0_0_18px_rgba(199,112,255,0.45)]"
                  : "text-fg-muted hover:text-fg"
              }`}
            >
              {r === "idol" ? "아이돌로 신청" : "소속사 문의"}
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
          onFocus={() => track("email_focus")}
          placeholder="you@example.com"
          className="mt-1.5 w-full rounded-xl border border-outline bg-bg/60 px-4 py-3 text-sm text-fg outline-none transition placeholder:text-fg-faint focus:border-primary focus:ring-2 focus:ring-primary/30"
        />
      </label>

      {/* 아이돌 전용 필드 */}
      {role === "idol" && (
        <div className="mt-3 space-y-3 rounded-xl border border-tertiary/25 bg-tertiary-container/15 p-3">
          <p className="text-[11px] leading-relaxed text-tertiary-container-on/90">
            합류 안내를 위해 알려주세요. (선택)
          </p>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="활동명 / 팀명"
            className="w-full rounded-xl border border-outline bg-bg/60 px-4 py-2.5 text-sm text-fg outline-none transition placeholder:text-fg-faint focus:border-tertiary focus:ring-2 focus:ring-tertiary/30"
          />
          <input
            type="text"
            inputMode="url"
            value={sns}
            onChange={(e) => setSns(e.target.value)}
            placeholder="SNS 링크 (인스타 / X 등)"
            className="w-full rounded-xl border border-outline bg-bg/60 px-4 py-2.5 text-sm text-fg outline-none transition placeholder:text-fg-faint focus:border-tertiary focus:ring-2 focus:ring-tertiary/30"
          />
        </div>
      )}

      {/* 소속사 전용 필드 */}
      {role === "agency" && (
        <div className="mt-3 space-y-3 rounded-xl border border-secondary/25 bg-secondary-container/15 p-3">
          <p className="text-[11px] leading-relaxed text-secondary-container-on/90">
            제휴 자료를 보내드릴게요. (회사명·내용 선택)
          </p>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="회사 / 소속사명"
            className="w-full rounded-xl border border-outline bg-bg/60 px-4 py-2.5 text-sm text-fg outline-none transition placeholder:text-fg-faint focus:border-secondary focus:ring-2 focus:ring-secondary/30"
          />
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            rows={3}
            placeholder="문의 내용 (소속 아이돌, 제휴 방향 등)"
            className="w-full resize-none rounded-xl border border-outline bg-bg/60 px-4 py-2.5 text-sm text-fg outline-none transition placeholder:text-fg-faint focus:border-secondary focus:ring-2 focus:ring-secondary/30"
          />
        </div>
      )}

      {/* 제출 */}
      <button
        type="submit"
        disabled={!emailValid || status === "submitting"}
        className="mt-5 w-full rounded-xl bg-primary py-3.5 text-sm font-semibold text-primary-on transition hover:bg-primary-hover disabled:cursor-not-allowed disabled:opacity-40"
      >
        {status === "submitting"
          ? "보내는 중…"
          : role === "agency"
            ? "문의 보내기"
            : "신청하기"}
      </button>

      {status === "error" && (
        <p className="mt-3 text-center text-xs text-error">
          잠시 후 다시 시도해 주세요.
        </p>
      )}
      <p className="mt-3 text-center text-[11px] leading-relaxed text-fg-faint">
        입력한 정보는 안내·회신 외 다른 용도로 사용하지 않아요.
      </p>
    </form>
  );
}
