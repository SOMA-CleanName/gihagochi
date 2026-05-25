/// F-007 / F-028 / F-030 / F-032 — profile 도메인 모델.
///
/// MyProfile = 자기 profiles row + (role=idol일 때) idol_profiles join.
/// UserRole / UserStatus enum은 auth가 정의한 것을 재사용 (둘 다 DB ENUM과 1:1).
//
// freezed 3 + redirected constructor에 @JsonKey 붙이면 invalid_annotation_target
// 경고가 뜨지만 generator는 정상 처리.
// ignore_for_file: invalid_annotation_target
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../auth/domain/auth_models.dart' show UserRole, UserStatus;

part 'profile_models.freezed.dart';
part 'profile_models.g.dart';

/// 아이돌 전용 확장 필드 (idol_profiles row).
@freezed
abstract class IdolDetail with _$IdolDetail {
  const factory IdolDetail({
    @JsonKey(name: 'stage_name') required String stageName,
    String? bio,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _IdolDetail;

  factory IdolDetail.fromJson(Map<String, dynamic> json) =>
      _$IdolDetailFromJson(json);
}

/// 자기 프로필 — profiles row + (role=idol & active일 때) idol_profiles join.
///
/// 다른 사용자의 profile 표시는 본 모델 X (해당 도메인에서 별도 정의).
@freezed
abstract class MyProfile with _$MyProfile {
  const factory MyProfile({
    required String id,
    required UserRole role,
    required UserStatus status,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    IdolDetail? idol,
  }) = _MyProfile;

  factory MyProfile.fromJson(Map<String, dynamic> json) =>
      _$MyProfileFromJson(json);
}

/// 팬 프로필 편집 입력. avatar는 별도 업로드 액션 — 본 모델은 텍스트 필드만.
@freezed
abstract class FanProfileEdit with _$FanProfileEdit {
  const factory FanProfileEdit({
    @JsonKey(name: 'display_name') required String displayName,
  }) = _FanProfileEdit;

  factory FanProfileEdit.fromJson(Map<String, dynamic> json) =>
      _$FanProfileEditFromJson(json);
}

/// 아이돌 프로필 편집 입력. thumbnail은 별도 업로드 액션.
@freezed
abstract class IdolProfileEdit with _$IdolProfileEdit {
  const factory IdolProfileEdit({
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'stage_name') required String stageName,
    String? bio,
  }) = _IdolProfileEdit;

  factory IdolProfileEdit.fromJson(Map<String, dynamic> json) =>
      _$IdolProfileEditFromJson(json);
}
