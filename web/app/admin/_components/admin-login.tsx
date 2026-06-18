"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

export function AdminLogin() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [status, setStatus] = useState<"idle" | "submitting" | "error">("idle");

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!password || status === "submitting") return;
    setStatus("submitting");
    try {
      const res = await fetch("/api/admin/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ password }),
      });
      if (!res.ok) throw new Error("login failed");
      router.refresh();
    } catch {
      setStatus("error");
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center px-6">
      <form
        onSubmit={onSubmit}
        className="w-full max-w-sm rounded-2xl border border-outline-soft bg-surface-2/70 p-7 backdrop-blur-md"
      >
        <h1 className="text-lg font-semibold text-fg">앙코르 관리자</h1>
        <p className="mt-1 text-sm text-fg-muted">비밀번호를 입력하세요.</p>
        <input
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(e) => {
            setPassword(e.target.value);
            if (status === "error") setStatus("idle");
          }}
          placeholder="비밀번호"
          className="mt-5 w-full rounded-xl border border-outline bg-bg/60 px-4 py-3 text-sm text-fg outline-none transition placeholder:text-fg-faint focus:border-primary focus:ring-2 focus:ring-primary/30"
        />
        <button
          type="submit"
          disabled={!password || status === "submitting"}
          className="mt-4 w-full rounded-xl bg-primary py-3 text-sm font-semibold text-primary-on transition hover:bg-primary-hover disabled:cursor-not-allowed disabled:opacity-40"
        >
          {status === "submitting" ? "확인 중…" : "로그인"}
        </button>
        {status === "error" && (
          <p className="mt-3 text-center text-xs text-error">
            비밀번호가 올바르지 않습니다.
          </p>
        )}
      </form>
    </div>
  );
}
