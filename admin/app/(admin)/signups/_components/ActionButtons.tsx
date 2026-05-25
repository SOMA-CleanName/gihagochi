'use client';

// 승인/반려 액션 버튼 한 묶음. RejectDialog는 같은 컴포넌트 안에서 상태로 토글.

import { useState, useTransition } from 'react';

import { approveApplication, rejectApplication } from '../_actions/actions';

type Props = {
  applicationId: string;
  stageName: string;
};

export function ActionButtons({ applicationId, stageName }: Props) {
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [showReject, setShowReject] = useState(false);
  const [reason, setReason] = useState('');

  function onApprove() {
    setError(null);
    if (!confirm(`'${stageName}' 신청을 승인하시겠습니까?`)) return;
    startTransition(async () => {
      const result = await approveApplication(applicationId);
      if (!result.ok) setError(result.error);
    });
  }

  function onRejectSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    const trimmed = reason.trim();
    if (!trimmed) {
      setError('반려 사유를 입력해주세요.');
      return;
    }
    startTransition(async () => {
      const result = await rejectApplication(applicationId, trimmed);
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setShowReject(false);
      setReason('');
    });
  }

  return (
    <div className="space-y-1">
      <div className="flex gap-2">
        <button
          type="button"
          disabled={pending}
          onClick={onApprove}
          className="rounded bg-neutral-900 px-3 py-1 text-xs font-medium text-white disabled:opacity-60"
        >
          승인
        </button>
        <button
          type="button"
          disabled={pending}
          onClick={() => setShowReject(true)}
          className="rounded border border-red-300 px-3 py-1 text-xs font-medium text-red-700 hover:bg-red-50 disabled:opacity-60"
        >
          반려
        </button>
      </div>

      {showReject && (
        <form
          onSubmit={onRejectSubmit}
          className="mt-2 space-y-2 rounded border bg-neutral-50 p-2"
        >
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="반려 사유"
            rows={2}
            maxLength={500}
            className="w-full rounded border px-2 py-1 text-xs"
          />
          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={() => {
                setShowReject(false);
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
              {pending ? '처리 중…' : '반려 확정'}
            </button>
          </div>
        </form>
      )}

      {error && (
        <p className="text-[11px] text-red-600">{error}</p>
      )}
    </div>
  );
}
