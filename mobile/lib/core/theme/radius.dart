/// 반경 토큰 — 모서리 둥글기.
///
/// `BorderRadius.circular(AppRadius.md)` 패턴.
library;

import 'package:flutter/widgets.dart';

class AppRadius {
  AppRadius._();

  /// 0 — 직각.
  static const double none = 0;

  /// 4 — 작은 chip / badge.
  static const double xs = 4;

  /// 8 — 버튼 / 입력 필드 / 작은 카드 기본.
  static const double sm = 8;

  /// 12 — 카드 / BottomSheet 기본.
  static const double md = 12;

  /// 16 — 큰 카드 / 모달 손잡이.
  static const double lg = 16;

  /// 20 — 채팅 버블.
  static const double xl = 20;

  /// 24 — 입력창 pill, FAB extended.
  static const double xxl = 24;

  /// 9999 — 완전 원형 (avatar, dot).
  static const double full = 9999;
}

/// 자주 쓰는 BorderRadius (const) — 객체 재사용.
class AppBorderRadius {
  AppBorderRadius._();

  static const xs = BorderRadius.all(Radius.circular(AppRadius.xs));
  static const sm = BorderRadius.all(Radius.circular(AppRadius.sm));
  static const md = BorderRadius.all(Radius.circular(AppRadius.md));
  static const lg = BorderRadius.all(Radius.circular(AppRadius.lg));
  static const xl = BorderRadius.all(Radius.circular(AppRadius.xl));
  static const xxl = BorderRadius.all(Radius.circular(AppRadius.xxl));

  /// 채팅 버블 — 내 메시지 (오른쪽 아래 살짝 직각).
  static const bubbleMine = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.lg),
    topRight: Radius.circular(AppRadius.lg),
    bottomLeft: Radius.circular(AppRadius.lg),
    bottomRight: Radius.circular(AppRadius.xs),
  );

  /// 채팅 버블 — 상대 메시지 (왼쪽 위 살짝 직각).
  static const bubbleOther = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.xs),
    topRight: Radius.circular(AppRadius.lg),
    bottomLeft: Radius.circular(AppRadius.lg),
    bottomRight: Radius.circular(AppRadius.lg),
  );
}
