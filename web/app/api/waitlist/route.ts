import { NextRequest, NextResponse } from "next/server";

type Body = {
  email?: string;
  role?: string; // "팬" | "아이돌"
  idolName?: string;
  idolSns?: string;
  session_id?: string;
  path?: string;
  referrer?: string;
};

const ALLOWED_ROLES = new Set(["팬", "아이돌"]);

function isValidEmail(s: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s);
}
function str(v: unknown, max = 300): string {
  return typeof v === "string" ? v.slice(0, max) : "";
}

export async function POST(req: NextRequest) {
  let body: Body;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const email = (body.email || "").trim().toLowerCase();
  if (!isValidEmail(email)) {
    return NextResponse.json({ error: "Invalid email" }, { status: 400 });
  }
  const role = ALLOWED_ROLES.has(body.role || "") ? body.role! : "팬";

  const payload = {
    event: "signup",
    ts: new Date().toISOString(),
    email,
    role,
    idol_name: role === "아이돌" ? str(body.idolName, 100) : "",
    idol_sns: role === "아이돌" ? str(body.idolSns, 200) : "",
    session_id: str(body.session_id, 64),
    path: str(body.path, 200),
    referrer: str(body.referrer, 500),
  };

  const SHEETS_URL = process.env.SHEETS_WEBHOOK_URL;
  if (!SHEETS_URL) {
    console.log("[waitlist:console-only]", payload);
    return NextResponse.json({ ok: true, mode: "console" });
  }

  try {
    const res = await fetch(SHEETS_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      redirect: "manual",
    });
    const accepted = res.status >= 200 && res.status < 400;
    return accepted
      ? NextResponse.json({ ok: true, mode: "sheets" })
      : NextResponse.json({ error: "Sheets write failed" }, { status: 502 });
  } catch (e) {
    console.error("[waitlist:exception]", e);
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
