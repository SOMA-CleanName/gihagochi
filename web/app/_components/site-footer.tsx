import Link from "next/link";

export function SiteFooter() {
  return (
    <footer className="border-t border-outline-soft bg-bg px-6 py-8">
      <div className="mx-auto flex max-w-6xl flex-col gap-3 text-sm text-fg-muted sm:flex-row sm:items-center sm:justify-between">
        <p>© 2026 앙코르</p>
        <div className="flex flex-wrap gap-x-6 gap-y-2">
          <a
            href="mailto:encoreofficial00@gmail.com"
            className="transition hover:text-fg"
          >
            문의
          </a>
          <a
            href="https://www.instagram.com/encoreofficial00/"
            target="_blank"
            rel="noopener noreferrer"
            className="transition hover:text-fg"
          >
            인스타그램
          </a>
          <a
            href="https://x.com/encoreofficial0"
            target="_blank"
            rel="noopener noreferrer"
            className="transition hover:text-fg"
          >
            X
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
