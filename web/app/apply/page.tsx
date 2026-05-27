import type { Metadata } from "next";
import { ApplyForm } from "../_components/apply-form";
import { SiteFooter } from "../_components/site-footer";
import { SiteHeader } from "../_components/site-header";

export const metadata: Metadata = {
  title: "아이돌 활동 신청",
  description:
    "앙코르에서 아이돌로 활동하고 싶다면 신청해주세요. 검토 후 연락드립니다.",
};

export default function ApplyPage() {
  return (
    <>
      <SiteHeader />
      <main className="mx-auto max-w-2xl px-6 pt-32 pb-24">
        <h1 className="text-4xl font-semibold tracking-tight text-fg sm:text-5xl">
          아이돌로 활동하기.
        </h1>
        <p className="mt-5 text-base leading-relaxed text-fg-muted sm:text-lg">
          앙코르는 관리자 승인을 거친 아이돌만 활동할 수 있어요. 아래 정보를
          남겨주시면 검토 후 1주일 이내 연락드립니다.
        </p>

        <div className="mt-12">
          <ApplyForm />
        </div>
      </main>
      <SiteFooter />
    </>
  );
}
