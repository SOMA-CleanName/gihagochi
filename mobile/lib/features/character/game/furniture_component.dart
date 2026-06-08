/// PR-H (placeholder) — 가구 컴포넌트.
///
/// `feature-specs/character.md` v2 "PR-H" 일부.
/// 본격 가구 PNG 미준비 → 색 사각형 placeholder로 메커니즘만 검증.
/// PNG 교체는 v2 (PR-V2-D 가구 본격 확장 시 또는 별도 트랙).
///
/// 위치 기반 상호작용:
/// - RoomWorld가 매 frame 캐릭터 ↔ 각 가구 거리 측정
/// - 임계값 이내 도달 시 actionWhenNear 트리거 (CharacterComponent.setAction)
library;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../domain/character_action.dart';

enum FurnitureKind { bed, desk, chair }

class FurnitureComponent extends RectangleComponent {
  FurnitureComponent({
    required this.kind,
    required this.actionWhenNear,
    required Vector2 super.size,
    super.position,
    super.anchor,
  }) : super(paint: Paint()..color = _colorFor(kind));

  /// 가구 종류 (PNG 교체 시 분기 키).
  final FurnitureKind kind;

  /// 캐릭터가 본 가구 근처에 도달했을 때 트리거할 액션.
  /// 정책 (자체 결정): bed=sleep / desk=eat / chair=sing.
  final CharacterActionType actionWhenNear;

  /// 디자인 시스템 네온 톤 — 본격 PNG 들어오면 색 무관 (sprite로 교체).
  static Color _colorFor(FurnitureKind kind) => switch (kind) {
        FurnitureKind.bed => const Color(0xFFFFB6E0), // pink
        FurnitureKind.desk => const Color(0xFF7BF6FF), // cyan
        FurnitureKind.chair => const Color(0xFFD9B5FF), // purple
      };
}
