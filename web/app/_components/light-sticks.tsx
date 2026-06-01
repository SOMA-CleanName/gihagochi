"use client";

/**
 * 페이지 하단에 깔리는 팬 펜라이트(형광봉) 빛점들.
 *
 * 지하 아이돌 라이브 현장의 시안 형광봉 군중 분위기를 mock.
 * - 약 36개 빛점 (대부분 시안, 일부 핑크/보라/하늘색)
 * - fixed bottom — 모든 섹션 위/아래에 따라 항상 보임
 * - 각 점은 sway keyframe 으로 좌우 살짝 흔들거림 (서로 다른 phase delay)
 * - prefers-reduced-motion 시 정지
 *
 * 좌표는 SSR hydration mismatch 회피 위해 hardcoded.
 */

type Stick = {
  /** 0~100, 화면 가로 위치(%) */
  x: number;
  /** 0~100, 하단 영역 내 세로 위치(%) — 0=가장 아래, 100=영역 top */
  y: number;
  /** 코어 크기 (px) */
  size: number;
  /** 색상 키 */
  color: "cyan" | "sky" | "mint" | "pink" | "purple";
  /** sway duration ms */
  durMs: number;
  /** sway delay ms (음수 OK — 시작 시점 분산) */
  delayMs: number;
  /** sway 진폭 deg */
  amp: number;
};

// 36개. 시안 dominant (~70%), 나머지 색 섞임. y는 0~70 분산 (하단 군중).
const STICKS: Stick[] = [
  { x: 2,  y: 12, size: 10, color: "cyan",  durMs: 3200, delayMs: 0,    amp: 12 },
  { x: 6,  y: 35, size: 8,  color: "sky",   durMs: 2800, delayMs: 400,  amp: 10 },
  { x: 10, y: 18, size: 12, color: "cyan",  durMs: 3600, delayMs: -800, amp: 14 },
  { x: 14, y: 50, size: 7,  color: "mint",  durMs: 3000, delayMs: 1200, amp: 9  },
  { x: 18, y: 8,  size: 11, color: "cyan",  durMs: 2600, delayMs: 300,  amp: 11 },
  { x: 22, y: 28, size: 9,  color: "sky",   durMs: 3400, delayMs: -500, amp: 13 },
  { x: 26, y: 45, size: 8,  color: "cyan",  durMs: 2900, delayMs: 700,  amp: 10 },
  { x: 30, y: 15, size: 13, color: "cyan",  durMs: 3700, delayMs: -200, amp: 12 },
  { x: 34, y: 60, size: 7,  color: "pink",  durMs: 3300, delayMs: 900,  amp: 8  },
  { x: 38, y: 25, size: 10, color: "mint",  durMs: 2700, delayMs: 100,  amp: 11 },
  { x: 42, y: 40, size: 8,  color: "cyan",  durMs: 3500, delayMs: -400, amp: 12 },
  { x: 46, y: 10, size: 12, color: "cyan",  durMs: 3100, delayMs: 600,  amp: 14 },
  { x: 50, y: 55, size: 9,  color: "sky",   durMs: 2800, delayMs: -700, amp: 10 },
  { x: 54, y: 20, size: 11, color: "cyan",  durMs: 3800, delayMs: 200,  amp: 13 },
  { x: 58, y: 38, size: 8,  color: "purple", durMs: 3000, delayMs: 1100, amp: 9  },
  { x: 62, y: 8,  size: 10, color: "cyan",  durMs: 3300, delayMs: -300, amp: 11 },
  { x: 66, y: 48, size: 7,  color: "mint",  durMs: 2600, delayMs: 800,  amp: 12 },
  { x: 70, y: 22, size: 13, color: "cyan",  durMs: 3600, delayMs: 0,    amp: 14 },
  { x: 74, y: 35, size: 9,  color: "sky",   durMs: 2900, delayMs: 500,  amp: 10 },
  { x: 78, y: 12, size: 11, color: "cyan",  durMs: 3400, delayMs: -600, amp: 12 },
  { x: 82, y: 58, size: 8,  color: "pink",  durMs: 3200, delayMs: 1000, amp: 9  },
  { x: 86, y: 28, size: 12, color: "cyan",  durMs: 2800, delayMs: 400,  amp: 13 },
  { x: 90, y: 42, size: 7,  color: "sky",   durMs: 3700, delayMs: -100, amp: 11 },
  { x: 94, y: 18, size: 10, color: "cyan",  durMs: 3100, delayMs: 700,  amp: 12 },
  { x: 98, y: 50, size: 8,  color: "mint",  durMs: 2700, delayMs: -500, amp: 10 },
  // 더 흩어지는 작은 점들 (배경 깊이감)
  { x: 8,  y: 65, size: 5,  color: "cyan",  durMs: 2400, delayMs: 200,  amp: 8  },
  { x: 16, y: 70, size: 6,  color: "sky",   durMs: 2600, delayMs: 900,  amp: 7  },
  { x: 28, y: 68, size: 5,  color: "cyan",  durMs: 2500, delayMs: -400, amp: 9  },
  { x: 40, y: 62, size: 6,  color: "mint",  durMs: 2800, delayMs: 600,  amp: 8  },
  { x: 52, y: 68, size: 5,  color: "cyan",  durMs: 2300, delayMs: 1000, amp: 7  },
  { x: 64, y: 65, size: 6,  color: "sky",   durMs: 2700, delayMs: -300, amp: 9  },
  { x: 76, y: 70, size: 5,  color: "cyan",  durMs: 2500, delayMs: 500,  amp: 8  },
  { x: 88, y: 64, size: 6,  color: "purple", durMs: 2900, delayMs: -800, amp: 7  },
  { x: 4,  y: 50, size: 6,  color: "cyan",  durMs: 2600, delayMs: 1100, amp: 10 },
  { x: 36, y: 5,  size: 8,  color: "cyan",  durMs: 3000, delayMs: -200, amp: 13 },
  { x: 68, y: 5,  size: 9,  color: "sky",   durMs: 2800, delayMs: 800,  amp: 12 },
];

const COLOR_CORE: Record<Stick["color"], string> = {
  cyan: "#7BF6FF",
  sky: "#A5DFFF",
  mint: "#9BFFE0",
  pink: "#FFB6E0",
  purple: "#D9B5FF",
};

const COLOR_GLOW: Record<Stick["color"], string> = {
  cyan: "rgba(0, 229, 255, 0.85)",
  sky: "rgba(120, 200, 255, 0.75)",
  mint: "rgba(80, 255, 200, 0.75)",
  pink: "rgba(255, 100, 200, 0.7)",
  purple: "rgba(190, 120, 255, 0.7)",
};

export function LightSticks() {
  return (
    <div
      aria-hidden
      className="pointer-events-none fixed inset-x-0 bottom-0 z-50 h-[55vh] overflow-hidden"
      style={{ mixBlendMode: "screen" }}
    >
      {STICKS.map((s, i) => (
        <span
          key={i}
          className="light-stick"
          style={
            {
              left: `${s.x}%`,
              bottom: `${s.y}%`,
              width: `${s.size}px`,
              height: `${s.size}px`,
              ["--core" as string]: COLOR_CORE[s.color],
              ["--glow" as string]: COLOR_GLOW[s.color],
              ["--dur" as string]: `${s.durMs}ms`,
              ["--delay" as string]: `${s.delayMs}ms`,
              ["--amp" as string]: `${s.amp}deg`,
            } as React.CSSProperties
          }
        />
      ))}

      <style jsx>{`
        .light-stick {
          position: absolute;
          border-radius: 9999px;
          background: var(--core);
          box-shadow:
            0 0 8px var(--core),
            0 0 24px var(--glow),
            0 0 48px var(--glow);
          transform-origin: 50% 100%;
          animation:
            sway var(--dur) ease-in-out var(--delay) infinite alternate,
            pulse calc(var(--dur) * 1.5) ease-in-out var(--delay) infinite alternate;
          will-change: transform, opacity;
        }
        @keyframes sway {
          0% {
            transform: rotate(calc(var(--amp) * -1));
          }
          100% {
            transform: rotate(var(--amp));
          }
        }
        @keyframes pulse {
          0% {
            opacity: 0.6;
          }
          100% {
            opacity: 1;
          }
        }
        @media (prefers-reduced-motion: reduce) {
          .light-stick {
            animation: none;
          }
        }
      `}</style>
    </div>
  );
}
