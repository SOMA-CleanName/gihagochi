/// flame 게임 본체 — `EncoreCharacterGame extends FlameGame`.
///
/// `feature-specs/character.md` v2 "영역 1. Rendering Engine" 결정사항:
/// - logical canvas: 480×800 (도트 게임 저해상도 표준)
/// - filterQuality.none 전제 (도트 그리드 유지)
/// - 60fps 게임 루프 (flame 기본)
///
/// PR 경계:
/// - PR-B: 빈 게임 + GameWidget 임베드 시범 (머지됨)
/// - PR-C (본 PR): RoomWorld 골격 + 방 배경 SpriteComponent
/// - PR-D: CharacterComponent + 액션 PNG 6종
/// - PR-E~H: 호흡 / 인터랙션 / 가구
/// - PR-I: 기존 LayeredAvatar / Stack 합성 정리
library;

import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../data/character_cache.dart';
import 'furniture_component.dart';
import 'room_world.dart';

class EncoreCharacterGame extends FlameGame {
  EncoreCharacterGame({
    this.onCharacterTap,
    this.onPositionSaved,
    this.loadCached,
    this.onFurnitureSelected,
  })  : super(
          world: RoomWorld(),
          camera: CameraComponent.withFixedResolution(
            width: 480,
            height: 800,
          ),
        ) {
    // 본 슬라이스 에셋만 사용 — 다른 슬라이스 영향 없게 게임 인스턴스 한정.
    images.prefix = 'assets/character/';
  }

  /// PR-F — 캐릭터 탭 시 외부(RoomCanvas)가 받아 처리할 callback.
  /// RoomWorld.onLoad에서 character.onTap에 주입. flame 자체는 Riverpod 모름 — callback 패턴.
  final VoidCallback? onCharacterTap;

  /// PR-G2 — 드래그 종료 시 위치(논리 바닥 좌표)를 외부가 받아 백엔드 저장.
  final void Function(double x, double y)? onPositionSaved;

  /// PR-G2 — 캐릭터 onLoad에서 호출할 로컬 캐시 로더 (진입 즉시 위치/액션 복원).
  final Future<CachedCharacter?> Function()? loadCached;

  /// 편집 모드 — 가구 탭/드래그 선택 시 외부(RoomCanvas)가 받아 슬라이더 표시.
  final void Function(FurnitureComponent)? onFurnitureSelected;

  /// 방 배경 PNG 로딩 전 잠깐 보이는 색.
  /// 본격 캐릭터/방 에셋 들어오면 의미 사라짐 (RoomWorld가 덮음).
  @override
  Color backgroundColor() => const Color(0xFF1A0F2E);
}
