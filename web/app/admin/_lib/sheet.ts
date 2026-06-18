import { connection } from "next/server";

// 시트(Apps Script doGet) 되읽기. 읽기 URL은 SHEETS_READ_URL 우선,
// 없으면 적재용 SHEETS_WEBHOOK_URL 재사용(같은 웹앱 배포 URL).

export type SheetRow = Record<string, string | number | null>;
export type SheetData = {
  ok: boolean;
  events: SheetRow[];
  signups: SheetRow[];
  error?: string;
};

export type SheetResult =
  | { state: "unconfigured" }
  | { state: "error"; message: string }
  | { state: "ok"; data: SheetData };

export async function fetchSheet(): Promise<SheetResult> {
  await connection();
  const base = process.env.SHEETS_READ_URL || process.env.SHEETS_WEBHOOK_URL;
  const token = process.env.SHEETS_READ_TOKEN;
  if (!base || !token) return { state: "unconfigured" };

  const url = `${base}${base.includes("?") ? "&" : "?"}token=${encodeURIComponent(token)}&limit=1000`;
  try {
    const res = await fetch(url, { cache: "no-store", redirect: "follow" });
    if (!res.ok) return { state: "error", message: `GET ${res.status}` };
    const data = (await res.json()) as SheetData;
    if (!data.ok) {
      return { state: "error", message: data.error ?? "sheet returned ok:false" };
    }
    return { state: "ok", data };
  } catch (e) {
    return { state: "error", message: e instanceof Error ? e.message : String(e) };
  }
}
