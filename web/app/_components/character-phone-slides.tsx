"use client";

/**
 * 랜딩 Character 섹션 우측 비주얼 — 핸드폰 mockup + 캐릭터 6종 슬라이드.
 *
 * - 6종 액션마다 (idle/happy/sad/sing/eat/sleep) 한 세트의 채팅 (팬↔아이돌)
 * - auto-rotate 4s, 사용자 swipe(터치/마우스 드래그) 시 5초 일시정지
 * - dot 인디케이터 클릭으로 직접 이동
 * - CSS keyframe 호흡 scale (액션별 duration 2.2~4.2s)
 *
 * 시연용 mock — 디자인 의도(느낌)만 살림.
 */

import { useEffect, useRef, useState } from "react";

type Action = "idle" | "happy" | "sad" | "sing" | "eat" | "sleep";

type ChatLine = { from: "fan" | "idol"; text: string };

const IDOL_NAME = "호시노 아이";

const ACTIONS: {
  key: Action;
  label: string;
  breatheMs: number;
  chat: ChatLine[];
}[] = [
  {
    key: "idle",
    label: "기본",
    breatheMs: 2800,
    chat: [
      { from: "fan", text: "오늘 하루 어땠어요?" },
      { from: "idol", text: "잘 보냈어요. 같이 있어줘서 고마워요." },
    ],
  },
  {
    key: "happy",
    label: "기쁨",
    breatheMs: 2400,
    chat: [
      { from: "idol", text: "방금 좋은 소식 들었어요!" },
      { from: "fan", text: "와 진짜? 축하해요 ✨" },
    ],
  },
  {
    key: "sing",
    label: "노래",
    breatheMs: 2200,
    chat: [
      { from: "fan", text: "신곡 한 소절만…?" },
      { from: "idol", text: "♪ 그대만이 나의 빛…" },
    ],
  },
  {
    key: "sad",
    label: "슬픔",
    breatheMs: 3200,
    chat: [
      { from: "idol", text: "오늘은 조금 지쳤어요." },
      { from: "fan", text: "괜찮아요. 푹 쉬어요 🤍" },
    ],
  },
  {
    key: "eat",
    label: "식사",
    breatheMs: 3400,
    chat: [
      { from: "fan", text: "밥 챙겨 먹었어요?" },
      { from: "idol", text: "지금 도시락 먹는 중! 맛있어요 🍱" },
    ],
  },
  {
    key: "sleep",
    label: "수면",
    breatheMs: 4200,
    chat: [
      { from: "idol", text: "이제 자러 갈게요…" },
      { from: "fan", text: "잘 자요. 좋은 꿈 꿔요 🌙" },
    ],
  },
];

const ROTATE_MS = 4000;
const RESUME_AFTER_INTERACTION_MS = 5000;
const SWIPE_THRESHOLD_PX = 40;

export function CharacterPhoneSlides() {
  const [active, setActive] = useState(0);
  const [paused, setPaused] = useState(false);
  const resumeTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // auto rotate
  useEffect(() => {
    if (paused) return;
    const t = setInterval(() => {
      setActive((i) => (i + 1) % ACTIONS.length);
    }, ROTATE_MS);
    return () => clearInterval(t);
  }, [paused]);

  const pauseForInteraction = () => {
    setPaused(true);
    if (resumeTimer.current) clearTimeout(resumeTimer.current);
    resumeTimer.current = setTimeout(
      () => setPaused(false),
      RESUME_AFTER_INTERACTION_MS,
    );
  };

  const go = (delta: number) => {
    setActive((i) => (i + delta + ACTIONS.length) % ACTIONS.length);
    pauseForInteraction();
  };

  const jumpTo = (i: number) => {
    setActive(i);
    pauseForInteraction();
  };

  // pointer drag — touch + mouse 통합. 가로 우세일 때만 슬라이드.
  // 세로 우세면 페이지 스크롤로 통과 (touch-action: pan-y).
  const dragStart = useRef<{ x: number; y: number } | null>(null);
  const onPointerDown = (e: React.PointerEvent) => {
    dragStart.current = { x: e.clientX, y: e.clientY };
  };
  const onPointerUp = (e: React.PointerEvent) => {
    if (!dragStart.current) return;
    const dx = e.clientX - dragStart.current.x;
    const dy = e.clientY - dragStart.current.y;
    dragStart.current = null;
    // 세로 움직임이 더 크면 swipe 아님 (스크롤 의도)
    if (Math.abs(dy) > Math.abs(dx)) return;
    if (Math.abs(dx) < SWIPE_THRESHOLD_PX) return;
    go(dx < 0 ? +1 : -1);
  };
  const onPointerCancel = () => {
    dragStart.current = null;
  };

  useEffect(() => {
    return () => {
      if (resumeTimer.current) clearTimeout(resumeTimer.current);
    };
  }, []);

  const current = ACTIONS[active];

  return (
    <div className="relative mx-auto w-full max-w-[320px] select-none">
      {/* 핸드폰 외곽 — 드래그 영역.
          touch-action: pan-y — 세로 스크롤은 브라우저, 가로 swipe만 본 컴포넌트가 처리. */}
      <div
        className="relative aspect-[9/19] cursor-grab overflow-hidden rounded-[44px] border-[10px] border-black bg-black shadow-2xl shadow-black/50 active:cursor-grabbing"
        style={{ touchAction: "pan-y" }}
        onPointerDown={onPointerDown}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerCancel}
        role="region"
        aria-label="캐릭터 액션 슬라이드 (좌우로 드래그)"
      >
        {/* 노치 */}
        <div
          aria-hidden
          className="absolute left-1/2 top-2 z-20 h-6 w-28 -translate-x-1/2 rounded-full bg-black"
        />

        {/* 방 배경 */}
        <div className="absolute inset-0">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/character/room_background.png"
            alt=""
            aria-hidden
            className="h-full w-full object-cover"
            style={{ imageRendering: "pixelated" }}
            draggable={false}
          />
        </div>

        {/* 상단 그라데이션 */}
        <div
          aria-hidden
          className="absolute inset-x-0 top-0 z-10 h-16 bg-gradient-to-b from-black/40 to-transparent"
        />

        {/* status bar */}
        <div className="absolute inset-x-0 top-1.5 z-20 flex items-center justify-between px-7 text-[10px] font-medium text-white/90">
          <span>9:41</span>
          <span className="opacity-70">●●●</span>
        </div>

        {/* 헤더 */}
        <div className="absolute inset-x-0 top-9 z-20 flex items-center gap-2 px-4">
          <div className="h-8 w-8 rounded-full border-2 border-pink-400 bg-gradient-to-br from-purple-300/80 to-pink-300/60" />
          <span className="text-sm font-semibold text-white drop-shadow">
            {IDOL_NAME}
          </span>
          <span className="ml-auto text-white/70">⋮</span>
        </div>

        {/* 캐릭터 슬라이드 */}
        <div className="absolute inset-x-0" style={{ top: "18%", bottom: "44%" }}>
          {ACTIONS.map((a, i) => (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              key={a.key}
              src={`/character/character_${a.key}.png`}
              alt={a.label}
              className="absolute left-1/2 h-full object-contain transition-opacity duration-700 ease-out"
              style={{
                opacity: i === active ? 1 : 0,
                imageRendering: "pixelated",
                animation: `breathe ${current.breatheMs}ms ease-in-out infinite alternate`,
              }}
              draggable={false}
            />
          ))}
        </div>

        {/* 채팅 mockup (액션별 2턴 fan↔idol) */}
        <div
          className="absolute inset-x-0 bottom-0 z-10 backdrop-blur-md"
          style={{
            top: "56%",
            background: "rgba(22, 22, 29, 0.32)",
            borderTop: "1px solid rgba(199, 112, 255, 0.35)",
          }}
        >
          <div className="flex justify-center pt-2 pb-1">
            <div className="h-1 w-10 rounded-full bg-white/40" />
          </div>

          <div
            key={current.key}
            className="space-y-1.5 px-3 pt-2 transition-opacity duration-500"
          >
            {current.chat.map((line, idx) => (
              <ChatBubble key={`${current.key}-${idx}`} line={line} />
            ))}
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

        {/* dot 인디케이터 */}
        <div className="absolute right-2 top-1/2 z-30 flex -translate-y-1/2 flex-col gap-1.5">
          {ACTIONS.map((a, i) => (
            <button
              key={a.key}
              type="button"
              onClick={() => jumpTo(i)}
              className="h-1.5 w-1.5 rounded-full transition-all duration-500 focus:outline-none"
              style={{
                background: i === active ? "#FF3DA1" : "rgba(255,255,255,0.25)",
                transform: i === active ? "scale(1.4)" : "scale(1)",
              }}
              aria-label={`${a.label}으로 이동`}
            />
          ))}
        </div>
      </div>

      {/* 라벨 + 좌우 버튼 (mobile에서 드래그 어려운 사용자 fallback) */}
      <div className="mt-5 flex items-center justify-center gap-4">
        <button
          type="button"
          onClick={() => go(-1)}
          aria-label="이전"
          className="flex h-8 w-8 items-center justify-center rounded-full border border-outline-soft text-fg-muted transition hover:border-pink-400 hover:text-fg"
        >
          ‹
        </button>
        <div className="min-w-[6rem] text-center text-sm">
          <span className="font-semibold text-fg">{current.label}</span>{" "}
          <span className="text-fg-faint">
            {active + 1} / {ACTIONS.length}
          </span>
        </div>
        <button
          type="button"
          onClick={() => go(+1)}
          aria-label="다음"
          className="flex h-8 w-8 items-center justify-center rounded-full border border-outline-soft text-fg-muted transition hover:border-pink-400 hover:text-fg"
        >
          ›
        </button>
      </div>

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

function ChatBubble({ line }: { line: ChatLine }) {
  const isIdol = line.from === "idol";
  return (
    <div
      className={`flex items-end gap-1.5 ${
        isIdol ? "justify-start" : "justify-end"
      }`}
    >
      {isIdol && (
        <div className="h-5 w-5 shrink-0 rounded-full border border-pink-400 bg-gradient-to-br from-purple-300/80 to-pink-300/60" />
      )}
      <div
        className={`max-w-[78%] px-2.5 py-1.5 text-[11px] leading-snug ${
          isIdol
            ? "rounded-2xl rounded-tl-md bg-white/[0.08] text-white/95"
            : "rounded-2xl rounded-tr-md text-white"
        }`}
        style={
          isIdol
            ? undefined
            : {
                background:
                  "linear-gradient(135deg, rgba(199,112,255,0.55), rgba(255,61,161,0.45))",
              }
        }
      >
        {line.text}
      </div>
    </div>
  );
}
