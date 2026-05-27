"""storage buckets + RLS — avatars / idol-thumbnails.

Revision ID: 0002_storage_rls
Revises: 0001_initial
Create Date: 2026-05-27

dev DB 에는 이미 asyncpg 직접 실행으로 적용된 상태 (profile / chat_room 작업 중).
본 마이그레이션은 staging/prod 환경 재현용 캡처.

전제:
- Supabase Postgres 환경 — `storage.buckets`, `storage.objects` 테이블이 이미 존재.
- 로컬 plain Postgres 에서는 storage 스키마 없어 실패할 수 있음 (CI 에서 skip).
"""

from __future__ import annotations

from collections.abc import Sequence

from alembic import op

# revision identifiers
revision: str = "0002_storage_rls"
down_revision: str | Sequence[str] | None = "0001_initial"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# =============================================================================
# upgrade
# =============================================================================


def upgrade() -> None:
    # -------------------------------------------------------------------------
    # 1. 버킷 2개 — private + 5MB + image/jpeg|png 제한
    # -------------------------------------------------------------------------
    op.execute(
        """
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES
            ('avatars',          'avatars',          false, 5242880, ARRAY['image/jpeg', 'image/png']),
            ('idol-thumbnails',  'idol-thumbnails',  false, 5242880, ARRAY['image/jpeg', 'image/png'])
        ON CONFLICT (id) DO UPDATE
          SET public             = EXCLUDED.public,
              file_size_limit    = EXCLUDED.file_size_limit,
              allowed_mime_types = EXCLUDED.allowed_mime_types;
        """
    )

    # -------------------------------------------------------------------------
    # 2. avatars 정책 (4) — 본인 폴더 INSERT/UPDATE/DELETE + authenticated SELECT
    # -------------------------------------------------------------------------
    op.execute(
        """
        DROP POLICY IF EXISTS "avatars_own_insert"          ON storage.objects;
        DROP POLICY IF EXISTS "avatars_own_update"          ON storage.objects;
        DROP POLICY IF EXISTS "avatars_own_delete"          ON storage.objects;
        DROP POLICY IF EXISTS "avatars_authenticated_select" ON storage.objects;

        CREATE POLICY "avatars_own_insert" ON storage.objects
          FOR INSERT TO authenticated
          WITH CHECK (
            bucket_id = 'avatars'
            AND (storage.foldername(name))[1] = (select auth.uid()::text)
          );

        CREATE POLICY "avatars_own_update" ON storage.objects
          FOR UPDATE TO authenticated
          USING (
            bucket_id = 'avatars'
            AND (storage.foldername(name))[1] = (select auth.uid()::text)
          );

        CREATE POLICY "avatars_own_delete" ON storage.objects
          FOR DELETE TO authenticated
          USING (
            bucket_id = 'avatars'
            AND (storage.foldername(name))[1] = (select auth.uid()::text)
          );

        CREATE POLICY "avatars_authenticated_select" ON storage.objects
          FOR SELECT TO authenticated
          USING (bucket_id = 'avatars');
        """
    )

    # -------------------------------------------------------------------------
    # 3. idol-thumbnails 정책 (4) — 활성 아이돌만 자기 폴더 쓰기
    # -------------------------------------------------------------------------
    op.execute(
        """
        DROP POLICY IF EXISTS "idol_thumbnails_own_insert"          ON storage.objects;
        DROP POLICY IF EXISTS "idol_thumbnails_own_update"          ON storage.objects;
        DROP POLICY IF EXISTS "idol_thumbnails_own_delete"          ON storage.objects;
        DROP POLICY IF EXISTS "idol_thumbnails_authenticated_select" ON storage.objects;

        CREATE POLICY "idol_thumbnails_own_insert" ON storage.objects
          FOR INSERT TO authenticated
          WITH CHECK (
            bucket_id = 'idol-thumbnails'
            AND (storage.foldername(name))[1] = (select auth.uid()::text)
            AND EXISTS (
              SELECT 1 FROM public.profiles
              WHERE id = auth.uid()
                AND role = 'idol'
                AND status = 'active'
            )
          );

        CREATE POLICY "idol_thumbnails_own_update" ON storage.objects
          FOR UPDATE TO authenticated
          USING (
            bucket_id = 'idol-thumbnails'
            AND (storage.foldername(name))[1] = (select auth.uid()::text)
            AND EXISTS (
              SELECT 1 FROM public.profiles
              WHERE id = auth.uid()
                AND role = 'idol'
                AND status = 'active'
            )
          );

        CREATE POLICY "idol_thumbnails_own_delete" ON storage.objects
          FOR DELETE TO authenticated
          USING (
            bucket_id = 'idol-thumbnails'
            AND (storage.foldername(name))[1] = (select auth.uid()::text)
          );

        CREATE POLICY "idol_thumbnails_authenticated_select" ON storage.objects
          FOR SELECT TO authenticated
          USING (bucket_id = 'idol-thumbnails');
        """
    )


# =============================================================================
# downgrade
# =============================================================================


def downgrade() -> None:
    op.execute(
        """
        DROP POLICY IF EXISTS "avatars_own_insert"           ON storage.objects;
        DROP POLICY IF EXISTS "avatars_own_update"           ON storage.objects;
        DROP POLICY IF EXISTS "avatars_own_delete"           ON storage.objects;
        DROP POLICY IF EXISTS "avatars_authenticated_select" ON storage.objects;

        DROP POLICY IF EXISTS "idol_thumbnails_own_insert"           ON storage.objects;
        DROP POLICY IF EXISTS "idol_thumbnails_own_update"           ON storage.objects;
        DROP POLICY IF EXISTS "idol_thumbnails_own_delete"           ON storage.objects;
        DROP POLICY IF EXISTS "idol_thumbnails_authenticated_select" ON storage.objects;

        DELETE FROM storage.buckets WHERE id IN ('avatars', 'idol-thumbnails');
        """
    )
