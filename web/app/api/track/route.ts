import { NextRequest, NextResponse } from "next/server";

type TrackBody = {
  event?: string;
  props?: Record<string, unknown>;
  ts?: string;
};

// 적재 허용 이벤트 (admin/시트 노이즈 방지). signup은 /api/waitlist 별도.
const ALLOWED = new Set([
  "page_view",
  "scroll_depth",
  "section_view",
  "cta_click",
  "character_click",
  "character_drag",
  "email_focus",
  "role_select",
  "waitlist_submit_attempt",
  "waitlist_submit_error",
  "session_end",
]);

function str(v: unknown, max = 500): string {
  return typeof v === "string" ? v.slice(0, max) : "";
}

export async function POST(req: NextRequest) {
  let body: TrackBody;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const event = body.event;
  if (!event || !ALLOWED.has(event)) {
    return NextResponse.json({ ok: true, mode: "skipped" });
  }

  const p = body.props ?? {};
  const payload = {
    event,
    ts: body.ts || new Date().toISOString(),
    session_id: str(p.session_id, 64),
    path: str(p.path, 200),
    label: str(p.label, 120),
    elapsed_ms: typeof p.elapsed_ms === "number" ? p.elapsed_ms : 0,
    props_json: JSON.stringify(p).slice(0, 1200),
  };

  const SHEETS_URL = process.env.SHEETS_WEBHOOK_URL;
  if (!SHEETS_URL) {
    console.log("[track:console-only]", payload);
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
    console.error("[track:exception]", e);
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
