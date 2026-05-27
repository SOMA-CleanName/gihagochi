"use client";

import { useState } from "react";

export function NotifyForm() {
  const [email, setEmail] = useState("");
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    // 백엔드 연결은 별도 작업. 1차는 인입 흐름 검증용 클라이언트 상태.
    setSubmitted(true);
  };

  if (submitted) {
    return (
      <div className="mt-10 flex flex-col items-center gap-2">
        <p className="text-base font-medium text-fg">
          신청이 접수되었어요.
        </p>
        <p className="text-sm text-fg-muted">
          출시 소식이 준비되면 가장 먼저 알려드릴게요.
        </p>
      </div>
    );
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="mt-10 mx-auto flex w-full max-w-md flex-col gap-2 sm:flex-row"
    >
      <label htmlFor="notify-email" className="sr-only">
        이메일 주소
      </label>
      <input
        id="notify-email"
        type="email"
        required
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="이메일 주소"
        autoComplete="email"
        className="h-12 flex-1 rounded-full border border-outline bg-surface/70 px-5 text-sm text-fg outline-none placeholder:text-fg-faint focus:border-primary"
      />
      <button
        type="submit"
        className="inline-flex h-12 items-center justify-center rounded-full bg-primary px-6 text-sm font-semibold text-primary-on transition hover:bg-primary-hover"
      >
        알림 받기
      </button>
    </form>
  );
}
