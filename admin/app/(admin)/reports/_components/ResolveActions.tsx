'use client';

// 신고 처리 액션 버튼 한 묶음. 4개 액션 + note dialog.

import { useState, useTransition } from 'react';

import { resolveReport, type ResolutionAction } from '../_actions/actions';

type Props = {
  reportId: string;
};

const ACTIONS: { key: ResolutionAction; label: string; tone: 'neutral' | 'warn' | 'danger' }[] = [
  { key: 'dismissed', label: '무시', tone: 'neutral' },
  { key: 'message_deleted', label: '메시지 삭제', tone: 'warn' },
  { key: 'warned', label: '경고', tone: 'warn' },
  { key: 'suspended', label: '정지', tone: 'danger' },
];

const TONE_CLASS: Record<'neutral' | 'warn' | 'danger', string> = {
  neutral: 'border bg-white text-neutral-700 hover:bg-neutral-100',
  warn: 'border border-amber-300 bg-amber-50 text-amber-800 hover:bg-amber-100',
  danger: 'border border-red-300 bg-red-50 text-red-700 hover:bg-red-100',
};

export function ResolveActions({ reportId }: Props) {
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<ResolutionAction | null>(null);
  const [note, setNote] = useState('');

  function onClick(action: ResolutionAction) {
    setError(null);
    setNote('');
    setSelected(action);
  }

  function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (selected === null) return;
    setError(null);

    const label = ACTIONS.find((a) => a.key === selected)?.label ?? selected;
    if (!confirm(`'${label}' 처리하시겠습니까? 되돌릴 수 없습니다.`)) return;

    startTransition(async () => {
      const result = await resolveReport(reportId, selected, note);
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setSelected(null);
      setNote('');
    });
  }

  return (
    <div className="space-y-1">
      <div className="flex flex-wrap gap-1">
        {ACTIONS.map((a) => (
          <button
            key={a.key}
            type="button"
            disabled={pending}
            onClick={() => onClick(a.key)}
            className={`rounded px-2 py-1 text-xs font-medium disabled:opacity-60 ${TONE_CLASS[a.tone]}`}
          >
            {a.label}
          </button>
        ))}
      </div>

      {selected !== null && (
        <form
          onSubmit={onSubmit}
          className="mt-2 space-y-2 rounded border bg-neutral-50 p-2"
        >
          <div className="text-xs text-neutral-600">
            {ACTIONS.find((a) => a.key === selected)?.label} 메모 (선택, 500자 이하)
          </div>
          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="처리 사유 / 메모"
            rows={2}
            maxLength={500}
            className="w-full rounded border px-2 py-1 text-xs"
          />
          <div className="flex gap-2">
            <button
              type="submit"
              disabled={pending}
              className="rounded bg-neutral-900 px-3 py-1 text-xs font-medium text-white disabled:opacity-60"
            >
              {pending ? '처리 중…' : '확정'}
            </button>
            <button
              type="button"
              disabled={pending}
              onClick={() => {
                setSelected(null);
                setNote('');
                setError(null);
              }}
              className="rounded border bg-white px-3 py-1 text-xs font-medium text-neutral-700 hover:bg-neutral-100 disabled:opacity-60"
            >
              취소
            </button>
          </div>
        </form>
      )}

      {error && (
        <div className="text-xs text-red-700">{error}</div>
      )}
    </div>
  );
}
