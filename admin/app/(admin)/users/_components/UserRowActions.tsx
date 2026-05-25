'use client';

// 정지/해제 액션 — status에 따라 노출 버튼 분기.

import { useState, useTransition } from 'react';

import { suspendUser, unsuspendUser } from '../_actions/actions';

type Props = {
  userId: string;
  displayName: string;
  status: 'active' | 'pending' | 'suspended';
};

export function UserRowActions({ userId, displayName, status }: Props) {
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [showSuspend, setShowSuspend] = useState(false);
  const [reason, setReason] = useState('');

  function onUnsuspend() {
    setError(null);
    if (!confirm(`'${displayName}' 정지를 해제하시겠습니까?`)) return;
    startTransition(async () => {
      const result = await unsuspendUser(userId);
      if (!result.ok) setError(result.error);
    });
  }

  function onSuspendSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    const trimmed = reason.trim();
    if (!trimmed) {
      setError('정지 사유를 입력해주세요.');
      return;
    }
    startTransition(async () => {
      const result = await suspendUser(userId, trimmed);
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setShowSuspend(false);
      setReason('');
    });
  }

  return (
    <div className="space-y-1">
      <div className="flex gap-2">
        {status === 'suspended' ? (
          <button
            type="button"
            disabled={pending}
            onClick={onUnsuspend}
            className="rounded border border-green-300 px-3 py-1 text-xs font-medium text-green-700 hover:bg-green-50 disabled:opacity-60"
          >
            해제
          </button>
        ) : (
          <button
            type="button"
            disabled={pending}
            onClick={() => setShowSuspend(true)}
            className="rounded border border-red-300 px-3 py-1 text-xs font-medium text-red-700 hover:bg-red-50 disabled:opacity-60"
          >
            정지
          </button>
        )}
      </div>

      {showSuspend && (
        <form
          onSubmit={onSuspendSubmit}
          className="mt-2 space-y-2 rounded border bg-neutral-50 p-2"
        >
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="정지 사유"
            rows={2}
            maxLength={500}
            className="w-full rounded border px-2 py-1 text-xs"
          />
          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={() => {
                setShowSuspend(false);
                setReason('');
                setError(null);
              }}
              className="rounded border bg-white px-2 py-1 text-xs"
            >
              취소
            </button>
            <button
              type="submit"
              disabled={pending}
              className="rounded bg-red-600 px-2 py-1 text-xs text-white disabled:opacity-60"
            >
              {pending ? '처리 중…' : '정지 확정'}
            </button>
          </div>
        </form>
      )}

      {error && <p className="text-[11px] text-red-600">{error}</p>}
    </div>
  );
}
