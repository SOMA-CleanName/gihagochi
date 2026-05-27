"use client";

import { useState } from "react";

export function ApplyForm() {
  const [submitted, setSubmitted] = useState(false);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [intro, setIntro] = useState("");
  const [sns, setSns] = useState("");

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    // 백엔드 연결은 별도 작업. 1차는 인입 흐름 검증용 클라이언트 상태.
    setSubmitted(true);
  };

  if (submitted) {
    return (
      <div className="rounded-2xl border border-outline-soft bg-surface px-8 py-10 text-center">
        <h2 className="text-2xl font-semibold text-fg">
          신청이 접수되었어요.
        </h2>
        <p className="mt-3 text-sm leading-relaxed text-fg-muted">
          검토 후 1주일 이내 입력해주신 이메일로 연락드릴게요.
          <br />
          관련 문의는 hello@encore.app 으로 보내주셔도 됩니다.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <Field label="활동명" required>
        <input
          type="text"
          required
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="예) 김지수"
          className={inputClass}
        />
      </Field>

      <Field label="이메일" required>
        <input
          type="email"
          required
          autoComplete="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="연락받을 이메일 주소"
          className={inputClass}
        />
      </Field>

      <Field label="한 줄 소개" required>
        <textarea
          required
          value={intro}
          onChange={(e) => setIntro(e.target.value)}
          placeholder="어떤 활동을 하고 있고, 앙코르에서 무엇을 하고 싶은지 적어주세요."
          rows={4}
          className={`${inputClass} resize-none py-4`}
        />
      </Field>

      <Field label="SNS 링크" hint="선택">
        <input
          type="url"
          value={sns}
          onChange={(e) => setSns(e.target.value)}
          placeholder="https://"
          className={inputClass}
        />
      </Field>

      <button
        type="submit"
        className="inline-flex h-14 w-full items-center justify-center rounded-full bg-primary px-7 text-base font-semibold text-primary-on transition hover:bg-primary-hover"
      >
        신청하기
      </button>

      <p className="text-xs leading-relaxed text-fg-faint">
        신청 내용은 본인 확인 및 활동 승인 검토 용도로만 사용되며, 자세한 사항은
        개인정보처리방침을 따릅니다.
      </p>
    </form>
  );
}

const inputClass =
  "block w-full rounded-2xl border border-outline-soft bg-surface px-5 py-3.5 text-base text-fg outline-none placeholder:text-fg-faint focus:border-primary";

function Field({
  label,
  required,
  hint,
  children,
}: {
  label: string;
  required?: boolean;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="mb-2 flex items-baseline gap-2">
        <span className="text-sm font-medium text-fg">{label}</span>
        {required ? (
          <span className="text-xs text-primary">필수</span>
        ) : hint ? (
          <span className="text-xs text-fg-faint">{hint}</span>
        ) : null}
      </span>
      {children}
    </label>
  );
}
