"""Postgres ENUM 타입과 1:1 매칭되는 Python Enum.

마이그레이션 `0001_initial.py`의 9개 ENUM과 동기. 새 값 추가 시 양쪽 모두 수정.

SQLAlchemy 모델에서 사용 패턴:
    from sqlalchemy import Enum as SAEnum
    from app.shared.enums import UserRole

    role: Mapped[UserRole] = mapped_column(
        SAEnum(UserRole, name="user_role", create_type=False),
        # create_type=False: 타입은 마이그레이션이 이미 만들었음
    )
"""

from enum import StrEnum


class UserRole(StrEnum):
    FAN = "fan"
    IDOL = "idol"
    ADMIN = "admin"


class UserStatus(StrEnum):
    PENDING = "pending"
    ACTIVE = "active"
    SUSPENDED = "suspended"


class MessageType(StrEnum):
    IDOL_TO_FANS = "idol_to_fans"
    FAN_TO_IDOL = "fan_to_idol"
    IDOL_REPLY = "idol_reply"


class MediaType(StrEnum):
    TEXT = "text"
    PHOTO = "photo"
    VOICE = "voice"


class ReportStatus(StrEnum):
    PENDING = "pending"
    HANDLED = "handled"


class ReportAction(StrEnum):
    DISMISSED = "dismissed"
    MESSAGE_DELETED = "message_deleted"
    WARNED = "warned"
    SUSPENDED = "suspended"


class SignupApplicationStatus(StrEnum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    WITHDRAWN = "withdrawn"


class AgreementType(StrEnum):
    TOS = "tos"
    PRIVACY = "privacy"
    MARKETING = "marketing"


class DevicePlatform(StrEnum):
    IOS = "ios"
    ANDROID = "android"


class CharacterActionType(StrEnum):
    """F-042 캐릭터 상태/행동. mobile features/character/domain의 enum과 동일 이름."""

    IDLE = "idle"
    HAPPY = "happy"
    SAD = "sad"
    SING = "sing"
    EAT = "eat"
    SLEEP = "sleep"
