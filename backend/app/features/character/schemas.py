"""F-042/F-043 character — Pydantic 스키마."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.shared.enums import CharacterActionType


class CharacterStateResponse(BaseModel):
    """GET /character/{idol_id}/state 응답.

    DB row 없으면 service가 default 값 채워서 반환 (DB INSERT는 첫 action 시).
    """

    idol_id: UUID
    current_action: CharacterActionType
    hunger: int
    happiness: int
    energy: int
    # PR-G2 — 드래그 위치(flame world 좌표). 미설정이면 null → 모바일이 기본 위치 사용.
    position_x: float | None
    position_y: float | None
    # 가구 배치 {kind: {x, y, w}}. 미설정이면 null → 모바일 기본 배치.
    furniture_layout: dict[str, "FurniturePlacement"] | None
    updated_at: datetime


class ActionRequest(BaseModel):
    """POST /character/{idol_id}/actions 요청.

    `action` = 어떤 행동을 트리거. service가 current_action 업데이트 + 로그 INSERT.
    """

    action: CharacterActionType


class PositionRequest(BaseModel):
    """POST /character/{idol_id}/position 요청 (PR-G2).

    flame world 좌표(logical). 드래그 종료 시 모바일이 호출.
    """

    x: float
    y: float


class FurniturePlacement(BaseModel):
    """가구 1개의 배치 — flame world 좌표(logical) + 표시 폭 + 편집 조정값.

    bm/dist는 구버전 데이터에 없을 수 있어 optional. JSONB라 마이그레이션 불필요.
    """

    x: float
    y: float
    w: float
    bm: float | None = None  # z-order 기준선 비율 (앞/뒤 경계)
    dist: float | None = None  # 상호작용 거리 (logical px)
    visible: bool | None = None  # 방에 배치 여부 (넣기/빼기)


class FurnitureLayoutRequest(BaseModel):
    """POST /character/{idol_id}/furniture 요청 (가구 편집).

    {kind: {x, y, w}} 맵 통째로 저장. 아이돌 본인만 호출 가능.
    """

    layout: dict[str, FurniturePlacement]


class ActionLogSummary(BaseModel):
    """행동 로그 요약. POST 응답으로 새 row 반환."""

    id: UUID
    idol_id: UUID
    action: CharacterActionType
    performed_by: UUID | None
    performed_at: datetime


class ActionResponse(BaseModel):
    """POST /character/{idol_id}/actions 응답."""

    log: ActionLogSummary
    state: CharacterStateResponse
