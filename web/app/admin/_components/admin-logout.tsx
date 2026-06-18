"use client";

import { useRouter } from "next/navigation";

export function AdminLogout() {
  const router = useRouter();
  async function onClick() {
    await fetch("/api/admin/login", { method: "DELETE" });
    router.refresh();
  }
  return (
    <button
      onClick={onClick}
      className="rounded-full border border-outline px-3 py-1.5 text-xs font-medium text-fg-muted transition hover:border-primary hover:text-primary"
    >
      로그아웃
    </button>
  );
}
