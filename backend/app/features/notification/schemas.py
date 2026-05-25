"""F-029 / F-031 notification — Pydantic 스키마."""

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field, model_validator

from app.shared.enums import DevicePlatform

# 푸시 종류. 발송 측 슬라이스(chat_message 등)가 is_notification_enabled 호출 시 사용.
NotificationKind = Literal["new_message", "idol_reply", "marketing"]


# ============================================================
# device_tokens
# ============================================================


class DeviceTokenRegisterRequest(BaseModel):
    """POST /notification/device-tokens 요청."""

    token: str = Field(min_length=1, max_length=4096)  # FCM 토큰은 ~152~163자, 여유 둠
    platform: DevicePlatform


class DeviceTokenResponse(BaseModel):
    """device_tokens 단건 응답."""

    id: UUID
    user_id: UUID
    platform: DevicePlatform
    token: str
    created_at: datetime
    last_used_at: datetime


# ============================================================
# notification_prefs
# ============================================================


class NotificationPrefsResponse(BaseModel):
    """GET / PATCH /notification/prefs 응답."""

    new_message_enabled: bool
    idol_reply_enabled: bool
    marketing_enabled: bool
    updated_at: datetime


class NotificationPrefsPatchRequest(BaseModel):
    """PATCH /notification/prefs 요청. 1개 이상 필드 필수."""

    new_message_enabled: bool | None = None
    idol_reply_enabled: bool | None = None
    marketing_enabled: bool | None = None

    @model_validator(mode="after")
    def _require_at_least_one(self) -> "NotificationPrefsPatchRequest":
        if (
            self.new_message_enabled is None
            and self.idol_reply_enabled is None
            and self.marketing_enabled is None
        ):
            raise ValueError("변경할 항목이 없습니다.")
        return self
