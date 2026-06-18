import type { Bar, Overview } from "../_lib/analytics";

// 개요 — KPI 카드 + 퍼널/분포 막대. 서버 렌더(프레젠테이션).

export function OverviewView({ ov }: { ov: Overview }) {
  return (
    <div className="space-y-8">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
        <Kpi label="세션" value={ov.totalSessions} />
        <Kpi label="페이지뷰" value={ov.totalPageViews} />
        <Kpi label="CTA 클릭" value={ov.ctaTotal} />
        <Kpi label="사전신청" value={ov.signups.total} sub={`팬 ${ov.signups.fan} · 아이돌 ${ov.signups.idol}`} />
        <Kpi label="캐릭터 상호작용" value={ov.characterInteractions} />
        <Kpi label="총 이벤트" value={ov.totalEvents} />
      </div>

      <Panel title="사전신청 퍼널" desc="방문 → 신청 완료까지 단계별 세션 (전체 세션 대비 %)">
        <BarList bars={ov.signupFunnel} accent />
      </Panel>

      <div className="grid gap-6 lg:grid-cols-2">
        <Panel title="섹션 도달률" desc="각 섹션이 화면에 들어온 세션 수">
          <BarList bars={ov.sectionFunnel} />
        </Panel>
        <Panel title="스크롤 깊이" desc="해당 깊이 이상 내려간 세션 수">
          <BarList bars={ov.scrollDist} />
        </Panel>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Panel title="CTA 클릭 분석" desc="어떤 버튼이 눌렸는지 (클릭 횟수 기준)">
          {ov.ctaByLabel.length ? (
            <BarList bars={ov.ctaByLabel} />
          ) : (
            <Empty>아직 CTA 클릭이 없습니다.</Empty>
          )}
        </Panel>
        <Panel title="유입 소스" desc="세션별 utm_source (없으면 direct)">
          {ov.sources.length ? <BarList bars={ov.sources} /> : <Empty>데이터 없음</Empty>}
        </Panel>
      </div>
    </div>
  );
}

function Kpi({ label, value, sub }: { label: string; value: number; sub?: string }) {
  return (
    <div className="rounded-xl border border-outline-soft bg-surface-2/40 p-4">
      <p className="text-xs text-fg-muted">{label}</p>
      <p className="mt-1 text-2xl font-semibold text-fg">{value.toLocaleString()}</p>
      {sub && <p className="mt-0.5 text-[11px] text-fg-faint">{sub}</p>}
    </div>
  );
}

function Panel({
  title,
  desc,
  children,
}: {
  title: string;
  desc?: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-xl border border-outline-soft bg-surface-2/30 p-5">
      <h2 className="text-sm font-semibold text-fg">{title}</h2>
      {desc && <p className="mt-0.5 text-xs text-fg-faint">{desc}</p>}
      <div className="mt-4">{children}</div>
    </section>
  );
}

function BarList({ bars, accent = false }: { bars: Bar[]; accent?: boolean }) {
  const max = Math.max(1, ...bars.map((b) => b.count));
  return (
    <ul className="space-y-2.5">
      {bars.map((b) => (
        <li key={b.key} className="grid grid-cols-[9rem_1fr_auto] items-center gap-3 text-sm">
          <span className="truncate text-fg-muted" title={b.label}>
            {b.label}
          </span>
          <span className="h-2.5 overflow-hidden rounded-full bg-bg/60">
            <span
              className={`block h-full rounded-full ${accent ? "bg-primary" : "bg-secondary"}`}
              style={{ width: `${Math.max(2, (b.count / max) * 100)}%` }}
            />
          </span>
          <span className="tabular-nums text-fg">
            {b.count}
            <span className="ml-1 text-xs text-fg-faint">{b.pct}%</span>
          </span>
        </li>
      ))}
    </ul>
  );
}

function Empty({ children }: { children: React.ReactNode }) {
  return <p className="text-sm text-fg-faint">{children}</p>;
}
