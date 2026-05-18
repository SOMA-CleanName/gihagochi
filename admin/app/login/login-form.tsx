'use client';

// 로그인 폼 — react-hook-form + zod. Supabase 직접 호출 (browser client).
import { zodResolver } from '@hookform/resolvers/zod';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';

import { createClient } from '@/lib/supabase/client';

const schema = z.object({
  email: z.string().email('이메일 형식이 올바르지 않습니다'),
  password: z.string().min(8, '비밀번호는 8자 이상'),
});

type FormValues = z.infer<typeof schema>;

export function LoginForm({ redirectTo }: { redirectTo: string }) {
  const router = useRouter();
  const [submitError, setSubmitError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  async function onSubmit(values: FormValues) {
    setSubmitError(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword(values);

    if (error) {
      setSubmitError(error.message);
      return;
    }

    // proxy.ts가 role 검증 — 미인가면 다시 /login으로 튕김.
    router.replace(redirectTo);
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <label className="block space-y-1">
        <span className="text-sm font-medium">이메일</span>
        <input
          type="email"
          autoComplete="email"
          className="w-full rounded border px-3 py-2 text-sm"
          {...register('email')}
        />
        {errors.email && (
          <span className="text-xs text-red-600">{errors.email.message}</span>
        )}
      </label>

      <label className="block space-y-1">
        <span className="text-sm font-medium">비밀번호</span>
        <input
          type="password"
          autoComplete="current-password"
          className="w-full rounded border px-3 py-2 text-sm"
          {...register('password')}
        />
        {errors.password && (
          <span className="text-xs text-red-600">{errors.password.message}</span>
        )}
      </label>

      {submitError && (
        <div className="rounded border border-red-200 bg-red-50 p-2 text-xs text-red-700">
          {submitError}
        </div>
      )}

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full rounded bg-neutral-900 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
      >
        {isSubmitting ? '로그인 중…' : '로그인'}
      </button>
    </form>
  );
}
