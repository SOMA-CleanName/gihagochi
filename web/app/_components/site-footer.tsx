import Link from "next/link";

export function SiteFooter() {
  return (
    <footer className="border-t border-outline-soft bg-bg px-6 py-8">
      <div className="mx-auto flex max-w-6xl flex-col gap-3 text-sm text-fg-muted sm:flex-row sm:items-center sm:justify-between">
        <p>© 2026 앙코르</p>
        <div className="flex gap-6">
          <a
            href="mailto:hello@encore.app"
            className="transition hover:text-fg"
          >
            문의
          </a>
          <Link href="/terms" className="transition hover:text-fg">
            이용약관
          </Link>
          <Link href="/privacy" className="transition hover:text-fg">
            개인정보처리방침
          </Link>
        </div>
      </div>
    </footer>
  );
}
