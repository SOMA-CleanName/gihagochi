'use server';

// F-037 reports Server Actions — resolve (dismissed/message_deleted/warned/suspended).
// Server-only: cookies()로 supabase session 추출 → access_token으로 백엔드 API 호출.
// 백엔드가 트랜잭션 보장 (reports UPDATE + suspended일 경우 profiles UPDATE).

import { revalidatePath } from 'next/cache';

import { createClient } from '@/lib/supabase/server';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:8000';

export type ResolutionAction =
  | 'dismissed'
  | 'message_deleted'
  | 'warned'
  | 'suspended';

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

export async function resolveReport(
  reportId: string,
  resolutionAction: ResolutionAction,
  resolutionNote: string | null,
): Promise<ActionResult> {
  const body: Record<string, unknown> = { resolution_action: resolutionAction };
  if (resolutionNote && resolutionNote.trim()) {
    body.resolution_note = resolutionNote.trim();
  }
  const result = await callBackend(`/admin/reports/${reportId}/resolve`, body);
  if (result.ok) revalidatePath('/reports');
  return result;
}
