"use client";

import Link from "next/link";
import { track } from "@/app/_lib/track";

/** CTA 클릭을 추적하는 링크. label로 어느 CTA인지 구분. */
export function TrackedLink({
  href,
  label,
  className,
  children,
}: {
  href: string;
  label: string;
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <Link
      href={href}
      className={className}
      onClick={() => track("cta_click", { label })}
    >
      {children}
    </Link>
  );
}
