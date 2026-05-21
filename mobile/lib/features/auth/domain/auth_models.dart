/// F-001~F-006 auth — 도메인 모델.
///
/// 백엔드 schemas.py와 wire-compat (snake_case 키 그대로 매핑).
/// Freezed + json_serializable로 직렬화. 빌드: `dart run build_runner build`.
//
// freezed 3 + redirected constructor에 @JsonKey 붙이면 invalid_annotation_target
// 경고가 뜨지만 generator는 정상 처리. 알려진 freezed 동작이라 파일 단위로 무시.
// ignore_for_file: invalid_annotation_target
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// 사용자 역할. 백엔드 user_role ENUM과 1:1.
enum UserRole {
  @JsonValue('fan')
  fan,
  @JsonValue('idol')
  idol,
  @JsonValue('admin')
  admin,
}

/// 사용자 활성화 상태. 백엔드 user_status ENUM과 1:1.
enum UserStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('active')
  active,
  @JsonValue('suspended')
  suspended,
}

/// 아이돌 신청 상태. signup_application_status ENUM과 1:1.
enum SignupApplicationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('withdrawn')
  withdrawn,
}

// ── 응답 모델 ────────────────────────────────

@freezed
abstract class ProfileSummary with _$ProfileSummary {
  const factory ProfileSummary({
    required String id,
    required UserRole role,
    required UserStatus status,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _ProfileSummary;

  factory ProfileSummary.fromJson(Map<String, dynamic> json) =>
      _$ProfileSummaryFromJson(json);
}

@freezed
abstract class IdolApplicationSummary with _$IdolApplicationSummary {
  const factory IdolApplicationSummary({
    required String id,
    required SignupApplicationStatus status,
    @JsonKey(name: 'stage_name') required String stageName,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'rejection_reason') String? rejectionReason,
  }) = _IdolApplicationSummary;

  factory IdolApplicationSummary.fromJson(Map<String, dynamic> json) =>
      _$IdolApplicationSummaryFromJson(json);
}

@freezed
abstract class MeResponse with _$MeResponse {
  const factory MeResponse({
    required ProfileSummary profile,
    @JsonKey(name: 'latest_idol_application')
    IdolApplicationSummary? latestIdolApplication,
  }) = _MeResponse;

  factory MeResponse.fromJson(Map<String, dynamic> json) =>
      _$MeResponseFromJson(json);
}

@freezed
abstract class SignupResponse with _$SignupResponse {
  const factory SignupResponse({
    required ProfileSummary profile,
    @JsonKey(name: 'idol_application') IdolApplicationSummary? idolApplication,
  }) = _SignupResponse;

  factory SignupResponse.fromJson(Map<String, dynamic> json) =>
      _$SignupResponseFromJson(json);
}

@freezed
abstract class TermsCurrent with _$TermsCurrent {
  const factory TermsCurrent({
    required String tos,
    required String privacy,
    required String marketing,
  }) = _TermsCurrent;

  factory TermsCurrent.fromJson(Map<String, dynamic> json) =>
      _$TermsCurrentFromJson(json);
}

// ── 요청 모델 ────────────────────────────────

/// 가입 시 약관 동의 1건. agreed 기본 true — 클라가 false 주면 백엔드가 400.
@freezed
abstract class AgreementInput with _$AgreementInput {
  const factory AgreementInput({
    required String version,
    @Default(true) bool agreed,
  }) = _AgreementInput;

  factory AgreementInput.fromJson(Map<String, dynamic> json) =>
      _$AgreementInputFromJson(json);
}

@freezed
abstract class AgreementsInput with _$AgreementsInput {
  const factory AgreementsInput({
    required AgreementInput tos,
    required AgreementInput privacy,
    AgreementInput? marketing,
  }) = _AgreementsInput;

  factory AgreementsInput.fromJson(Map<String, dynamic> json) =>
      _$AgreementsInputFromJson(json);
}

/// 가입 타입 — 옵션 C. JSON 키 "as".
enum SignupAs {
  @JsonValue('fan')
  fan,
  @JsonValue('idol')
  idol,
}

@freezed
abstract class SignupRequest with _$SignupRequest {
  const factory SignupRequest({
    // JSON 키는 "as" (Python 예약어 회피용 백엔드 alias와 일치).
    @JsonKey(name: 'as') required SignupAs signupAs,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'stage_name') String? stageName,
    String? bio,
    @JsonKey(name: 'application_note') String? applicationNote,
    required AgreementsInput agreements,
  }) = _SignupRequest;

  factory SignupRequest.fromJson(Map<String, dynamic> json) =>
      _$SignupRequestFromJson(json);
}
