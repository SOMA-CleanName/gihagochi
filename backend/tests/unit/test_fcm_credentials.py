"""FCM 자격증명 로딩 단위 테스트.

`_load_credentials_dict` 헬퍼만 검증 — firebase_admin 초기화는 안 함.
"""

import json
from pathlib import Path

from app.core.config import Settings
from app.core.fcm import _load_credentials_dict


def _make_settings(**overrides) -> Settings:
    """필수 필드 더미값으로 채운 Settings 인스턴스."""
    base: dict = {
        "database_url": "postgresql://test:test@localhost:5432/test",
        "supabase_url": "https://test.supabase.co",
        "supabase_anon_key": "test-anon",
        "supabase_service_role_key": "test-service",
        "supabase_jwt_secret": "test-jwt",
    }
    base.update(overrides)
    return Settings(**base)  # type: ignore[call-arg]


def test_returns_none_when_nothing_set() -> None:
    settings = _make_settings()
    assert _load_credentials_dict(settings) is None


def test_loads_from_json_string() -> None:
    payload = {"type": "service_account", "project_id": "p1"}
    settings = _make_settings(fcm_service_account_json=json.dumps(payload))
    assert _load_credentials_dict(settings) == payload


def test_returns_none_when_json_malformed() -> None:
    settings = _make_settings(fcm_service_account_json="not json")
    assert _load_credentials_dict(settings) is None


def test_loads_from_file_when_json_unset(tmp_path: Path) -> None:
    payload = {"type": "service_account", "project_id": "p2"}
    file = tmp_path / "fcm.json"
    file.write_text(json.dumps(payload), encoding="utf-8")
    settings = _make_settings(fcm_service_account_path=file)
    assert _load_credentials_dict(settings) == payload


def test_returns_none_when_file_missing(tmp_path: Path) -> None:
    settings = _make_settings(fcm_service_account_path=tmp_path / "missing.json")
    assert _load_credentials_dict(settings) is None


def test_json_takes_priority_over_path(tmp_path: Path) -> None:
    """둘 다 설정되면 JSON 우선."""
    json_payload = {"source": "json"}
    file_payload = {"source": "file"}
    file = tmp_path / "fcm.json"
    file.write_text(json.dumps(file_payload), encoding="utf-8")

    settings = _make_settings(
        fcm_service_account_json=json.dumps(json_payload),
        fcm_service_account_path=file,
    )
    assert _load_credentials_dict(settings) == json_payload
