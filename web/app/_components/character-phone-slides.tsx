"use client";

/**
 * 랜딩 페이지 Character 섹션의 우측 비주얼.
 *
 * 핸드폰 mockup 안에 실제 모바일 앱 캐릭터 6종을 슬라이드로 보여줌.
 * - 방 배경 PNG 풀스크린
 * - 캐릭터 6종 (idle/happy/sad/sing/eat/sleep) auto-rotate 페이드
 * - 호흡 scale 애니메이션 (CSS keyframe loop)
 * - 하단 채팅 mockup 카드 (반투명, 실제 채팅창 분위기)
 * - 우측 액션 도트 인디케이터
 *
 * 실제 시뮬 캡처가 아닌 mock — 디자인 의도 (느낌)만 살림.
 */

import { useEffect, useState } from "react";

type Action = "idle" | "happy" | "sad" | "sing" | "eat" | "sleep";

const ACTIONS: { key: Action; label: string; line: string; breatheMs: number }[] = [
  { key: "idle", label: "기본", line: "오늘 하루 어땠어?", breatheMs: 2800 },
  { key: "happy", label: "기쁨", line: "와 진짜 신난다!", breatheMs: 2400 },
  { key: "sing", label: "노래", line: "♪ 한 소절 들려줄게", breatheMs: 2200 },
  { key: "sad", label: "슬픔", line: "조금 보고 싶었어…", breatheMs: 3200 },
  { key: "eat", label: "식사", line: "맛있는 거 먹는 중", breatheMs: 3400 },
  { key: "sleep", label: "수면", line: "곧 잘 시간이야…", breatheMs: 4200 },
];

const ROTATE_MS = 3200;

export function CharacterPhoneSlides() {
  const [active, setActive] = useState(0);

  useEffect(() => {
    const t = setInterval(() => {
      setActive((i) => (i + 1) % ACTIONS.length);
    }, ROTATE_MS);
    return () => clearInterval(t);
  }, []);

  const current = ACTIONS[active];

  return (
    <div className="relative mx-auto w-full max-w-[320px]">
      {/* 핸드폰 외곽 frame */}
      <div className="relative aspect-[9/19] overflow-hidden rounded-[44px] border-[10px] border-black bg-black shadow-2xl shadow-black/50">
        {/* 노치 */}
        <div
          aria-hidden
          className="absolute left-1/2 top-2 z-20 h-6 w-28 -translate-x-1/2 rounded-full bg-black"
        />

        {/* 방 배경 */}
        <div className="absolute inset-0">
          <img
            src="/character/room_background.png"
            alt=""
            aria-hidden
            className="h-full w-full object-cover"
            style={{ imageRendering: "pixelated" }}
          />
        </div>

        {/* 상단 페이드 (status bar 영역 자연스럽게) */}
        <div
          aria-hidden
          className="absolute inset-x-0 top-0 z-10 h-16 bg-gradient-to-b from-black/40 to-transparent"
        />

        {/* 상단 가짜 status bar */}
        <div className="absolute inset-x-0 top-1.5 z-20 flex items-center justify-between px-7 text-[10px] font-medium text-white/90">
          <span>9:41</span>
          <span className="opacity-70">●●●</span>
        </div>

        {/* 헤더 (아이돌 이름) */}
        <div className="absolute inset-x-0 top-9 z-20 flex items-center gap-2 px-4">
          <div className="h-8 w-8 rounded-full border-2 border-pink-400 bg-purple-300/80" />
          <span className="text-sm font-semibold text-white drop-shadow">
            똥쟁이
          </span>
          <span className="ml-auto text-white/70">⋮</span>
        </div>

        {/* 캐릭터 슬라이드 — 모두 같은 위치에 stacked, opacity 토글 */}
        <div className="absolute inset-x-0" style={{ top: "20%", bottom: "40%" }}>
          {ACTIONS.map((a, i) => (
            <img
              key={a.key}
              src={`/character/character_${a.key}.png`}
              alt={a.label}
              className="absolute left-1/2 h-full -translate-x-1/2 object-contain transition-opacity duration-700 ease-out"
              style={{
                opacity: i === active ? 1 : 0,
                imageRendering: "pixelated",
                animation: `breathe ${current.breatheMs}ms ease-in-out infinite alternate`,
              }}
            />
          ))}
        </div>

        {/* 하단 채팅 카드 mockup */}
        <div
          className="absolute inset-x-0 bottom-0 z-10 backdrop-blur-md"
          style={{
            top: "60%",
            background: "rgba(22, 22, 29, 0.28)",
            borderTop: "1px solid rgba(199, 112, 255, 0.3)",
          }}
        >
          {/* 드래그 핸들 */}
          <div className="flex justify-center pt-2 pb-1">
            <div className="h-1 w-10 rounded-full bg-white/40" />
          </div>

          {/* 가짜 메시지 (현재 액션에 따라 한 줄 변화) */}
          <div className="space-y-2 px-4 pt-2">
            <div className="flex items-start gap-2">
              <div className="h-6 w-6 shrink-0 rounded-full border border-pink-400 bg-purple-300/80" />
              <div
                key={current.key}
                className="rounded-2xl rounded-tl-md bg-white/[0.06] px-3 py-1.5 text-[11px] text-white/90 backdrop-blur transition-opacity duration-700"
              >
                {current.line}
              </div>
            </div>
          </div>

          {/* 입력창 */}
          <div className="absolute inset-x-0 bottom-2 flex items-center gap-2 px-3">
            <div className="h-7 w-7 rounded-full border border-white/20 bg-white/5" />
            <div className="flex-1 rounded-full border border-white/10 bg-white/5 px-3 py-1.5 text-[10px] text-white/40">
              메시지 입력
            </div>
            <div className="h-7 w-7 rounded-full border border-white/20 bg-white/5" />
          </div>
        </div>

        {/* 우측 액션 인디케이터 — 진행 표시 */}
        <div className="absolute right-2 top-1/2 z-30 flex -translate-y-1/2 flex-col gap-1.5">
          {ACTIONS.map((a, i) => (
            <span
              key={a.key}
              className="h-1.5 w-1.5 rounded-full transition-all duration-500"
              style={{
                background: i === active ? "#FF3DA1" : "rgba(255,255,255,0.25)",
                transform: i === active ? "scale(1.4)" : "scale(1)",
              }}
              aria-hidden
            />
          ))}
        </div>
      </div>

      {/* 슬라이드 라벨 (frame 아래) */}
      <div className="mt-5 flex items-center justify-center gap-3 text-sm">
        <span className="font-semibold text-fg">{current.label}</span>
        <span className="text-fg-faint">
          {active + 1} / {ACTIONS.length}
        </span>
      </div>

      {/* breathe keyframe (Tailwind 4 inline) */}
      <style jsx>{`
        @keyframes breathe {
          0% {
            transform: translateX(-50%) scale(1);
          }
          100% {
            transform: translateX(-50%) scale(1.018);
          }
        }
      `}</style>
    </div>
  );
}
