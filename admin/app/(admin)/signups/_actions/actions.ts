'use server';

// F-035 signups Server Actions — 승인/반려.
// Server-only: cookies()로 supabase session 추출 → access_token으로 백엔드 API 호출.
// 백엔드가 트랜잭션 보장 (idol_signup_applications UPDATE + idol_profiles INSERT + profiles UPDATE).

import { revalidatePath } from 'next/cache';

import { createClient } from '@/lib/supabase/server';

// 운영 시 NEXT_PUBLIC_API_BASE_URL 환경 변수로 주입 (Vercel + Railway dev/prod 분리).
// 본 PR에서는 .env.example 갱신을 건드리지 않으므로 dev fallback만.
const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:8000';

type ActionResult = { ok: true } | { ok: false; error: string };

async function callBackend(
  path: string,
  body: Record<string, unknown> | null,
): Promise<ActionResult> {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session) {
    return { ok: false, error: '세션이 만료되었습니다. 다시 로그인해주세요.' };
  }

  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${session.access_token}`,
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
    cache: 'no-store',
  });

  if (res.ok) return { ok: true };

  const payload = (await res.json().catch(() => null)) as
    | { error?: { message?: string } }
    | null;
  return {
    ok: false,
    error: payload?.error?.message ?? `요청 실패 (${res.status})`,
  };
}

export async function approveApplication(applicationId: string): Promise<ActionResult> {
  const result = await callBackend(
    `/admin/idol-applications/${applicationId}/approve`,
    null,
  );
  if (result.ok) revalidatePath('/signups');
  return result;
}

export async function rejectApplication(
  applicationId: string,
  rejectionReason: string,
): Promise<ActionResult> {
  const result = await callBackend(`/admin/idol-applications/${applicationId}/reject`, {
    rejection_reason: rejectionReason,
  });
  if (result.ok) revalidatePath('/signups');
  return result;
}
