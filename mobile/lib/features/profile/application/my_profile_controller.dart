/// 자기 profile 상태 + 액션 (편집 / 업로드 / 탈퇴).
///
/// 액션 후엔 항상 refetch — UI는 새 데이터를 자연스럽게 반영.
library;

import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/profile_repository.dart';
import '../domain/profile_models.dart';

part 'my_profile_controller.g.dart';

@riverpod
class MyProfileController extends _$MyProfileController {
  @override
  Future<MyProfile> build() async {
    return ref.watch(profileRepositoryProvider).fetchMyProfile();
  }

  Future<void> updateFan(FanProfileEdit input) async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.updateFanProfile(input);
      return repo.fetchMyProfile();
    });
  }

  Future<void> updateIdol(IdolProfileEdit input) async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.updateIdolProfile(input);
      return repo.fetchMyProfile();
    });
  }

  Future<void> uploadAvatar(Uint8List bytes) async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.uploadAvatar(bytes);
      return repo.fetchMyProfile();
    });
  }

  Future<void> uploadThumbnail(Uint8List bytes) async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.uploadThumbnail(bytes);
      return repo.fetchMyProfile();
    });
  }

  /// soft delete + Supabase signOut. 호출자가 후속 라우팅 (`/auth/landing`) 처리.
  Future<void> softDeleteAndSignOut() async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.softDeleteAccount();
    // signOut은 supabase 직접 호출 — features/auth에 wrapper가 있지만
    // 본 액션은 백엔드 /auth/logout 없이 supabase만 종료.
    await repo.supabase.auth.signOut();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
