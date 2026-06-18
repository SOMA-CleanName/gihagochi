import { cookies } from "next/headers";
import { NextResponse } from "next/server";

import { ADMIN_COOKIE, adminPassword, sessionToken } from "@/app/admin/_lib/auth";

const MAX_AGE = 60 * 60 * 24 * 7; // 7일

export async function POST(req: Request) {
  const pw = adminPassword();
  if (!pw) {
    return NextResponse.json({ error: "admin disabled" }, { status: 503 });
  }
  let body: { password?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "bad request" }, { status: 400 });
  }
  if ((body.password ?? "") !== pw) {
    return NextResponse.json({ error: "invalid" }, { status: 401 });
  }
  const store = await cookies();
  store.set(ADMIN_COOKIE, sessionToken(pw), {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: MAX_AGE,
  });
  return NextResponse.json({ ok: true });
}

export async function DELETE() {
  const store = await cookies();
  store.delete(ADMIN_COOKIE);
  return NextResponse.json({ ok: true });
}
