"""initial schema — 10 tables + ENUMs + RLS + broadcast trigger.

Revision ID: 0001_initial
Revises:
Create Date: 2026-05-16

Phase 1.3 — _workspace/schema/{tables.sql, rls-policies.sql} 를 한 마이그레이션으로 통합.

전제:
- Supabase Postgres 환경. `auth.users` 와 `realtime.broadcast_changes` 가 이미 존재.
- 로컬 plain Postgres 에서는 broadcast trigger 부분에서 실패할 수 있음 (Realtime 미설치).
"""
from __future__ import annotations

from collections.abc import Sequence

from alembic import op

# revision identifiers
revision: str = "0001_initial"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# =============================================================================
# upgrade
# =============================================================================

def upgrade() -> None:
    # -------------------------------------------------------------------------
    # 0. 확장
    # -------------------------------------------------------------------------
    op.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto;")

    # -------------------------------------------------------------------------
    # 1. ENUM 타입
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TYPE user_role AS ENUM ('fan', 'idol', 'admin');
        CREATE TYPE user_status AS ENUM ('pending', 'active', 'suspended');
        CREATE TYPE message_type AS ENUM ('idol_to_fans', 'fan_to_idol', 'idol_reply');
        CREATE TYPE media_type AS ENUM ('text', 'photo', 'voice');
        CREATE TYPE report_status AS ENUM ('pending', 'handled');
        CREATE TYPE report_action AS ENUM ('dismissed', 'message_deleted', 'warned', 'suspended');
        CREATE TYPE signup_application_status AS ENUM ('pending', 'approved', 'rejected', 'withdrawn');
        CREATE TYPE agreement_type AS ENUM ('tos', 'privacy', 'marketing');
        CREATE TYPE device_platform AS ENUM ('ios', 'android');
        """
    )

    # -------------------------------------------------------------------------
    # 2. 공용 트리거 함수 (updated_at 자동 갱신)
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
        BEGIN
          NEW.updated_at = NOW();
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        """
    )

    # -------------------------------------------------------------------------
    # 3. profiles
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE profiles (
          id              uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
          role            user_role   NOT NULL DEFAULT 'fan',
          status          user_status NOT NULL DEFAULT 'pending',
          display_name    text        NOT NULL,
          avatar_url      text,
          suspended_at    timestamptz,
          suspend_reason  text,
          deleted_at      timestamptz,
          created_at      timestamptz NOT NULL DEFAULT NOW(),
          updated_at      timestamptz NOT NULL DEFAULT NOW(),
          CONSTRAINT profiles_suspend_consistency
            CHECK ((suspended_at IS NULL AND suspend_reason IS NULL)
                OR (suspended_at IS NOT NULL))
        );

        CREATE TRIGGER tg_profiles_updated_at
          BEFORE UPDATE ON profiles
          FOR EACH ROW EXECUTE FUNCTION set_updated_at();

        CREATE INDEX idx_profiles_role_status
          ON profiles(role, status)
          WHERE deleted_at IS NULL;
        """
    )

    # -------------------------------------------------------------------------
    # 4. idol_signup_applications
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE idol_signup_applications (
          id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id           uuid NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
          stage_name        text NOT NULL,
          bio               text,
          application_note  text,
          status            signup_application_status NOT NULL DEFAULT 'pending',
          handled_by        uuid REFERENCES profiles(id) ON DELETE RESTRICT,
          handled_at        timestamptz,
          rejection_reason  text,
          created_at        timestamptz NOT NULL DEFAULT NOW(),
          updated_at        timestamptz NOT NULL DEFAULT NOW(),
          CONSTRAINT apps_handled_consistency
            CHECK (
              (status = 'pending'  AND handled_by IS NULL AND handled_at IS NULL)
              OR
              (status <> 'pending' AND handled_by IS NOT NULL AND handled_at IS NOT NULL)
            ),
          CONSTRAINT apps_rejected_reason_required
            CHECK (status <> 'rejected' OR rejection_reason IS NOT NULL)
        );

        CREATE TRIGGER tg_idol_apps_updated_at
          BEFORE UPDATE ON idol_signup_applications
          FOR EACH ROW EXECUTE FUNCTION set_updated_at();

        CREATE UNIQUE INDEX idx_idol_apps_one_pending_per_user
          ON idol_signup_applications(user_id)
          WHERE status = 'pending';

        CREATE INDEX idx_idol_apps_queue
          ON idol_signup_applications(status, created_at);
        """
    )

    # -------------------------------------------------------------------------
    # 5. idol_profiles
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE idol_profiles (
          id                     uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
          signup_application_id  uuid NOT NULL REFERENCES idol_signup_applications(id) ON DELETE RESTRICT,
          stage_name             text NOT NULL UNIQUE,
          bio                    text,
          thumbnail_url          text,
          activated_at           timestamptz NOT NULL DEFAULT NOW(),
          created_at             timestamptz NOT NULL DEFAULT NOW(),
          updated_at             timestamptz NOT NULL DEFAULT NOW()
        );

        CREATE TRIGGER tg_idol_profiles_updated_at
          BEFORE UPDATE ON idol_profiles
          FOR EACH ROW EXECUTE FUNCTION set_updated_at();

        CREATE INDEX idx_idol_profiles_activated_at
          ON idol_profiles(activated_at DESC);
        """
    )

    # -------------------------------------------------------------------------
    # 6. subscriptions
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE subscriptions (
          fan_id            uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          idol_id           uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          subscribed_at     timestamptz NOT NULL DEFAULT NOW(),
          unsubscribed_at   timestamptz,
          last_read_at      timestamptz NOT NULL DEFAULT NOW(),
          PRIMARY KEY (fan_id, idol_id),
          CONSTRAINT subs_no_self CHECK (fan_id <> idol_id)
        );

        CREATE INDEX idx_subscriptions_active_by_fan
          ON subscriptions(fan_id)
          WHERE unsubscribed_at IS NULL;

        CREATE INDEX idx_subscriptions_active_by_idol
          ON subscriptions(idol_id)
          WHERE unsubscribed_at IS NULL;
        """
    )

    # -------------------------------------------------------------------------
    # 7. messages
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE messages (
          id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          client_message_id  uuid,
          type               message_type NOT NULL,
          sender_id          uuid NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
          idol_id            uuid NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
          recipient_id       uuid REFERENCES profiles(id) ON DELETE RESTRICT,
          parent_message_id  uuid REFERENCES messages(id) ON DELETE SET NULL,
          content            text,
          media_type         media_type NOT NULL DEFAULT 'text',
          media_url          text,
          created_at         timestamptz NOT NULL DEFAULT NOW(),
          edited_at          timestamptz,
          deleted_at         timestamptz,

          CONSTRAINT messages_type_consistency CHECK (
            (type = 'idol_to_fans'
              AND recipient_id IS NULL
              AND parent_message_id IS NULL)
            OR
            (type = 'fan_to_idol'
              AND recipient_id = idol_id
              AND parent_message_id IS NULL)
            OR
            (type = 'idol_reply'
              AND recipient_id IS NULL
              AND parent_message_id IS NOT NULL)
          ),

          CONSTRAINT messages_media_consistency CHECK (
            (media_type = 'text'  AND media_url IS NULL     AND content IS NOT NULL)
            OR
            (media_type IN ('photo', 'voice') AND media_url IS NOT NULL)
          )
        );

        CREATE INDEX idx_messages_room_history
          ON messages(idol_id, created_at DESC)
          WHERE deleted_at IS NULL;

        CREATE INDEX idx_messages_fan_to_idol
          ON messages(recipient_id, created_at DESC)
          WHERE type = 'fan_to_idol' AND deleted_at IS NULL;

        CREATE INDEX idx_messages_parent
          ON messages(parent_message_id)
          WHERE parent_message_id IS NOT NULL;

        CREATE UNIQUE INDEX idx_messages_idempotency
          ON messages(sender_id, client_message_id)
          WHERE client_message_id IS NOT NULL;
        """
    )

    # -------------------------------------------------------------------------
    # 8. message_reads
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE message_reads (
          message_id  uuid NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
          fan_id      uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          read_at     timestamptz NOT NULL DEFAULT NOW(),
          PRIMARY KEY (message_id, fan_id)
        );

        CREATE INDEX idx_message_reads_by_fan
          ON message_reads(fan_id, read_at DESC);
        """
    )

    # -------------------------------------------------------------------------
    # 9. reports
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE reports (
          id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          reporter_id        uuid NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
          message_id         uuid NOT NULL REFERENCES messages(id) ON DELETE RESTRICT,
          reason             text NOT NULL,
          status             report_status NOT NULL DEFAULT 'pending',
          resolution_action  report_action,
          resolution_note    text,
          handled_by         uuid REFERENCES profiles(id) ON DELETE RESTRICT,
          handled_at         timestamptz,
          created_at         timestamptz NOT NULL DEFAULT NOW(),

          CONSTRAINT reports_handled_consistency CHECK (
            (status = 'pending'
              AND resolution_action IS NULL
              AND handled_by IS NULL
              AND handled_at IS NULL)
            OR
            (status = 'handled'
              AND resolution_action IS NOT NULL
              AND handled_by IS NOT NULL
              AND handled_at IS NOT NULL)
          ),

          CONSTRAINT reports_no_duplicate UNIQUE (message_id, reporter_id)
        );

        CREATE INDEX idx_reports_queue
          ON reports(status, created_at)
          WHERE status = 'pending';

        CREATE INDEX idx_reports_by_message
          ON reports(message_id);
        """
    )

    # -------------------------------------------------------------------------
    # 10. device_tokens
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE device_tokens (
          id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id       uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          platform      device_platform NOT NULL,
          token         text NOT NULL UNIQUE,
          created_at    timestamptz NOT NULL DEFAULT NOW(),
          last_used_at  timestamptz NOT NULL DEFAULT NOW()
        );

        CREATE INDEX idx_device_tokens_by_user
          ON device_tokens(user_id);
        """
    )

    # -------------------------------------------------------------------------
    # 11. notification_prefs
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE notification_prefs (
          user_id              uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
          new_message_enabled  boolean NOT NULL DEFAULT TRUE,
          idol_reply_enabled   boolean NOT NULL DEFAULT TRUE,
          marketing_enabled    boolean NOT NULL DEFAULT FALSE,
          updated_at           timestamptz NOT NULL DEFAULT NOW()
        );

        CREATE TRIGGER tg_notif_prefs_updated_at
          BEFORE UPDATE ON notification_prefs
          FOR EACH ROW EXECUTE FUNCTION set_updated_at();
        """
    )

    # -------------------------------------------------------------------------
    # 12. terms_agreements
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE TABLE terms_agreements (
          id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
          type        agreement_type NOT NULL,
          version     text NOT NULL,
          agreed_at   timestamptz NOT NULL DEFAULT NOW(),
          CONSTRAINT terms_agreements_no_duplicate UNIQUE (user_id, type, version)
        );

        CREATE INDEX idx_terms_agreements_by_user
          ON terms_agreements(user_id, type, agreed_at DESC);
        """
    )

    # -------------------------------------------------------------------------
    # 13. RLS 헬퍼 함수
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE OR REPLACE FUNCTION is_admin() RETURNS boolean
          LANGUAGE sql
          SECURITY DEFINER
          STABLE
          SET search_path = public
        AS $$
          SELECT EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
              AND role = 'admin'
              AND status = 'active'
              AND deleted_at IS NULL
          );
        $$;

        CREATE OR REPLACE FUNCTION is_active_idol(p_user_id uuid) RETURNS boolean
          LANGUAGE sql
          SECURITY DEFINER
          STABLE
          SET search_path = public
        AS $$
          SELECT EXISTS (
            SELECT 1 FROM profiles p
            JOIN idol_profiles ip ON ip.id = p.id
            WHERE p.id = p_user_id
              AND p.role = 'idol'
              AND p.status = 'active'
              AND p.deleted_at IS NULL
          );
        $$;

        CREATE OR REPLACE FUNCTION is_subscribed_to(p_idol_id uuid) RETURNS boolean
          LANGUAGE sql
          SECURITY DEFINER
          STABLE
          SET search_path = public
        AS $$
          SELECT EXISTS (
            SELECT 1 FROM subscriptions
            WHERE fan_id = auth.uid()
              AND idol_id = p_idol_id
              AND unsubscribed_at IS NULL
          );
        $$;
        """
    )

    # -------------------------------------------------------------------------
    # 14. RLS 활성화
    # -------------------------------------------------------------------------
    op.execute(
        """
        ALTER TABLE profiles                  ENABLE ROW LEVEL SECURITY;
        ALTER TABLE idol_signup_applications  ENABLE ROW LEVEL SECURITY;
        ALTER TABLE idol_profiles             ENABLE ROW LEVEL SECURITY;
        ALTER TABLE subscriptions             ENABLE ROW LEVEL SECURITY;
        ALTER TABLE messages                  ENABLE ROW LEVEL SECURITY;
        ALTER TABLE message_reads             ENABLE ROW LEVEL SECURITY;
        ALTER TABLE reports                   ENABLE ROW LEVEL SECURITY;
        ALTER TABLE device_tokens             ENABLE ROW LEVEL SECURITY;
        ALTER TABLE notification_prefs        ENABLE ROW LEVEL SECURITY;
        ALTER TABLE terms_agreements          ENABLE ROW LEVEL SECURITY;
        """
    )

    # -------------------------------------------------------------------------
    # 15. RLS 정책 — profiles
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE POLICY profiles_select_visible ON profiles FOR SELECT TO authenticated
        USING (
          id = auth.uid()
          OR is_admin()
          OR (deleted_at IS NULL)
        );

        CREATE POLICY profiles_insert_self ON profiles FOR INSERT TO authenticated
        WITH CHECK (id = auth.uid());

        CREATE POLICY profiles_update_self ON profiles FOR UPDATE TO authenticated
        USING (id = auth.uid() AND deleted_at IS NULL)
        WITH CHECK (id = auth.uid());

        CREATE POLICY profiles_update_admin ON profiles FOR UPDATE TO authenticated
        USING (is_admin()) WITH CHECK (is_admin());

        CREATE POLICY profiles_delete_admin ON profiles FOR DELETE TO authenticated
        USING (is_admin());
        """
    )

    # -------------------------------------------------------------------------
    # 16. RLS 정책 — idol_signup_applications
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE POLICY apps_select_self ON idol_signup_applications FOR SELECT TO authenticated
        USING (user_id = auth.uid() OR is_admin());

        CREATE POLICY apps_insert_self ON idol_signup_applications FOR INSERT TO authenticated
        WITH CHECK (
          user_id = auth.uid()
          AND status = 'pending'
          AND handled_by IS NULL
          AND handled_at IS NULL
        );

        CREATE POLICY apps_update_withdraw ON idol_signup_applications FOR UPDATE TO authenticated
        USING (user_id = auth.uid() AND status = 'pending')
        WITH CHECK (user_id = auth.uid() AND status = 'withdrawn');

        CREATE POLICY apps_update_admin ON idol_signup_applications FOR UPDATE TO authenticated
        USING (is_admin()) WITH CHECK (is_admin());

        CREATE POLICY apps_delete_admin ON idol_signup_applications FOR DELETE TO authenticated
        USING (is_admin());
        """
    )

    # -------------------------------------------------------------------------
    # 17. RLS 정책 — idol_profiles
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE POLICY idol_profiles_select_all ON idol_profiles FOR SELECT TO authenticated
        USING (true);

        CREATE POLICY idol_profiles_insert_admin ON idol_profiles FOR INSERT TO authenticated
        WITH CHECK (is_admin());

        CREATE POLICY idol_profiles_update_self ON idol_profiles FOR UPDATE TO authenticated
        USING (id = auth.uid()) WITH CHECK (id = auth.uid());

        CREATE POLICY idol_profiles_update_admin ON idol_profiles FOR UPDATE TO authenticated
        USING (is_admin()) WITH CHECK (is_admin());

        CREATE POLICY idol_profiles_delete_admin ON idol_profiles FOR DELETE TO authenticated
        USING (is_admin());
        """
    )

    # -------------------------------------------------------------------------
    # 18. RLS 정책 — subscriptions
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE POLICY subs_select_visible ON subscriptions FOR SELECT TO authenticated
        USING (
          fan_id = auth.uid()
          OR idol_id = auth.uid()
          OR is_admin()
        );

        CREATE POLICY subs_insert_self ON subscriptions FOR INSERT TO authenticated
        WITH CHECK (
          fan_id = auth.uid()
          AND unsubscribed_at IS NULL
          AND is_active_idol(idol_id)
        );

        CREATE POLICY subs_update_self ON subscriptions FOR UPDATE TO authenticated
        USING (fan_id = auth.uid()) WITH CHECK (fan_id = auth.uid());

        CREATE POLICY subs_delete_self ON subscriptions FOR DELETE TO authenticated
        USING (fan_id = auth.uid() OR is_admin());
        """
    )

    # -------------------------------------------------------------------------
    # 19. RLS 정책 — messages
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE POLICY messages_select_visible ON messages FOR SELECT TO authenticated
        USING (
          sender_id = auth.uid()
          OR
          (
            type IN ('idol_to_fans', 'idol_reply')
            AND is_subscribed_to(idol_id)
          )
          OR
          (
            type = 'fan_to_idol'
            AND idol_id = auth.uid()
          )
          OR is_admin()
        );

        CREATE POLICY messages_insert_idol ON messages FOR INSERT TO authenticated
        WITH CHECK (
          sender_id = auth.uid()
          AND idol_id = auth.uid()
          AND type IN ('idol_to_fans', 'idol_reply')
          AND recipient_id IS NULL
          AND is_active_idol(auth.uid())
          AND (
            type <> 'idol_reply'
            OR EXISTS (
              SELECT 1 FROM messages parent
              WHERE parent.id = parent_message_id
                AND parent.idol_id = auth.uid()
                AND parent.type = 'fan_to_idol'
            )
          )
        );

        CREATE POLICY messages_insert_fan ON messages FOR INSERT TO authenticated
        WITH CHECK (
          sender_id = auth.uid()
          AND type = 'fan_to_idol'
          AND recipient_id = idol_id
          AND parent_message_id IS NULL
          AND is_subscribed_to(idol_id)
        );

        CREATE POLICY messages_update_self ON messages FOR UPDATE TO authenticated
        USING (sender_id = auth.uid() AND deleted_at IS NULL)
        WITH CHECK (sender_id = auth.uid());

        CREATE POLICY messages_update_admin ON messages FOR UPDATE TO authenticated
        USING (is_admin()) WITH CHECK (is_admin());

        CREATE POLICY messages_delete_admin ON messages FOR DELETE TO authenticated
        USING (is_admin());
        """
    )

    # -------------------------------------------------------------------------
    # 20. RLS 정책 — message_reads
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE POLICY reads_select_visible ON message_reads FOR SELECT TO authenticated
        USING (
          fan_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM messages m
            WHERE m.id = message_reads.message_id AND m.idol_id = auth.uid()
          )
          OR is_admin()
        );

        CREATE POLICY reads_insert_self ON message_reads FOR INSERT TO authenticated
        WITH CHECK (
          fan_id = auth.uid()
          AND EXISTS (
            SELECT 1 FROM messages m
            WHERE m.id = message_id
              AND m.type IN ('idol_to_fans', 'idol_reply')
              AND is_subscribed_to(m.idol_id)
          )
        );

        CREATE POLICY reads_delete_self ON message_reads FOR DELETE TO authenticated
        USING (fan_id = auth.uid() OR is_admin());
        """
    )

    # -------------------------------------------------------------------------
    # 21. RLS 정책 — reports
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE POLICY reports_select_self ON reports FOR SELECT TO authenticated
        USING (reporter_id = auth.uid() OR is_admin());

        CREATE POLICY reports_insert_self ON reports FOR INSERT TO authenticated
        WITH CHECK (
          reporter_id = auth.uid()
          AND status = 'pending'
          AND resolution_action IS NULL
          AND handled_by IS NULL
        );

        CREATE POLICY reports_update_admin ON reports FOR UPDATE TO authenticated
        USING (is_admin()) WITH CHECK (is_admin());

        CREATE POLICY reports_delete_admin ON reports FOR DELETE TO authenticated
        USING (is_admin());
        """
    )

    # -------------------------------------------------------------------------
    # 22. RLS 정책 — device_tokens / notification_prefs / terms_agreements
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE POLICY tokens_select_self ON device_tokens FOR SELECT TO authenticated
        USING (user_id = auth.uid() OR is_admin());

        CREATE POLICY tokens_insert_self ON device_tokens FOR INSERT TO authenticated
        WITH CHECK (user_id = auth.uid());

        CREATE POLICY tokens_update_self ON device_tokens FOR UPDATE TO authenticated
        USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

        CREATE POLICY tokens_delete_self ON device_tokens FOR DELETE TO authenticated
        USING (user_id = auth.uid() OR is_admin());

        CREATE POLICY notif_prefs_select_self ON notification_prefs FOR SELECT TO authenticated
        USING (user_id = auth.uid() OR is_admin());

        CREATE POLICY notif_prefs_insert_self ON notification_prefs FOR INSERT TO authenticated
        WITH CHECK (user_id = auth.uid());

        CREATE POLICY notif_prefs_update_self ON notification_prefs FOR UPDATE TO authenticated
        USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

        CREATE POLICY notif_prefs_delete_admin ON notification_prefs FOR DELETE TO authenticated
        USING (is_admin());

        CREATE POLICY terms_select_self ON terms_agreements FOR SELECT TO authenticated
        USING (user_id = auth.uid() OR is_admin());

        CREATE POLICY terms_insert_self ON terms_agreements FOR INSERT TO authenticated
        WITH CHECK (user_id = auth.uid());
        """
    )

    # -------------------------------------------------------------------------
    # 23. messages broadcast 트리거 (Realtime extension 필요)
    # -------------------------------------------------------------------------
    op.execute(
        """
        CREATE OR REPLACE FUNCTION broadcast_message_change() RETURNS TRIGGER AS $$
        DECLARE
          v_topic text;
          v_idol  uuid;
        BEGIN
          v_idol := COALESCE(NEW.idol_id, OLD.idol_id);
          v_topic := 'idol:' || v_idol::text;

          PERFORM realtime.broadcast_changes(
            v_topic,
            TG_OP,
            TG_OP,
            TG_TABLE_NAME,
            TG_TABLE_SCHEMA,
            NEW,
            OLD
          );

          RETURN COALESCE(NEW, OLD);
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;

        CREATE TRIGGER tg_messages_broadcast
          AFTER INSERT OR UPDATE OR DELETE ON messages
          FOR EACH ROW EXECUTE FUNCTION broadcast_message_change();
        """
    )


# =============================================================================
# downgrade — 역순으로 정리
# =============================================================================

def downgrade() -> None:
    # 1) broadcast trigger / function
    op.execute("DROP TRIGGER IF EXISTS tg_messages_broadcast ON messages;")
    op.execute("DROP FUNCTION IF EXISTS broadcast_message_change();")

    # 2) 테이블 (역 의존 순서). 정책/트리거/인덱스는 cascade 로 정리됨.
    op.execute("DROP TABLE IF EXISTS terms_agreements CASCADE;")
    op.execute("DROP TABLE IF EXISTS notification_prefs CASCADE;")
    op.execute("DROP TABLE IF EXISTS device_tokens CASCADE;")
    op.execute("DROP TABLE IF EXISTS reports CASCADE;")
    op.execute("DROP TABLE IF EXISTS message_reads CASCADE;")
    op.execute("DROP TABLE IF EXISTS messages CASCADE;")
    op.execute("DROP TABLE IF EXISTS subscriptions CASCADE;")
    op.execute("DROP TABLE IF EXISTS idol_profiles CASCADE;")
    op.execute("DROP TABLE IF EXISTS idol_signup_applications CASCADE;")
    op.execute("DROP TABLE IF EXISTS profiles CASCADE;")

    # 3) RLS 헬퍼 함수
    op.execute("DROP FUNCTION IF EXISTS is_subscribed_to(uuid);")
    op.execute("DROP FUNCTION IF EXISTS is_active_idol(uuid);")
    op.execute("DROP FUNCTION IF EXISTS is_admin();")

    # 4) 공용 트리거 함수
    op.execute("DROP FUNCTION IF EXISTS set_updated_at();")

    # 5) ENUM 타입
    op.execute(
        """
        DROP TYPE IF EXISTS device_platform;
        DROP TYPE IF EXISTS agreement_type;
        DROP TYPE IF EXISTS signup_application_status;
        DROP TYPE IF EXISTS report_action;
        DROP TYPE IF EXISTS report_status;
        DROP TYPE IF EXISTS media_type;
        DROP TYPE IF EXISTS message_type;
        DROP TYPE IF EXISTS user_status;
        DROP TYPE IF EXISTS user_role;
        """
    )

    # 6) pgcrypto 는 공유 가능성 있어 의도적으로 남김
