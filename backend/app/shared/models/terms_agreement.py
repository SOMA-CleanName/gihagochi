# OWNER: auth (F-034 약관/개인정보 동의)
"""terms_agreements — 약관/개인정보/마케팅 동의 이력 (버전별).

(user_id, type, version) unique. 약관 버전 업데이트 시 재동의 row 추가.
"""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base
from app.shared.enums import AgreementType


class TermsAgreement(Base):
    __tablename__ = "terms_agreements"

    id: Mapped[UUID] = mapped_column(
        Uuid, primary_key=True, server_default=text("gen_random_uuid()")
    )
    user_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="RESTRICT"), nullable=False
    )
    type: Mapped[AgreementType] = mapped_column(
        SAEnum(
            AgreementType,
            name="agreement_type",
            create_type=False,
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
    )
    version: Mapped[str] = mapped_column(nullable=False)
    agreed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
