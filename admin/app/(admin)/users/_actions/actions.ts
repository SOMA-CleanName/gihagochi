'use server';

// F-038 users Server Actions — 정지/해제.
// 백엔드 API 경유. 자기 자신 정지는 백엔드에서 400.

import { revalidatePath } from 'next/cache';

import { createClient } from '@/lib/supabase/server';

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

export async function suspendUser(
  userId: string,
  suspendReason: string,
): Promise<ActionResult> {
  const result = await callBackend(`/admin/users/${userId}/suspend`, {
    suspend_reason: suspendReason,
  });
  if (result.ok) revalidatePath('/users');
  return result;
}

export async function unsuspendUser(userId: string): Promise<ActionResult> {
  const result = await callBackend(`/admin/users/${userId}/unsuspend`, null);
  if (result.ok) revalidatePath('/users');
  return result;
}
