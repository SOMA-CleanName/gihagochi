import { createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";

// 비밀번호 게이트 — 단일 env(ADMIN_PASSWORD)만으로 동작.
// 쿠키엔 비번 대신 HMAC 파생 토큰을 저장(비번 노출 방지, 위조엔 비번 필요).

export const ADMIN_COOKIE = "encore_admin";

export function adminPassword(): string | null {
  const p = process.env.ADMIN_PASSWORD;
  return p && p.length > 0 ? p : null;
}

export function sessionToken(password: string): string {
  return createHmac("sha256", password).update("encore-admin-v1").digest("hex");
}

export async function isAuthed(): Promise<boolean> {
  const pw = adminPassword();
  if (!pw) return false;
  const store = await cookies();
  const val = store.get(ADMIN_COOKIE)?.value;
  if (!val) return false;
  const a = Buffer.from(val);
  const b = Buffer.from(sessionToken(pw));
  return a.length === b.length && timingSafeEqual(a, b);
}
