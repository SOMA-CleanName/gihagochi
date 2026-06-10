/// PR-C/D/H — flame World 골격 + 방 배경 + 캐릭터 + 가구.
///
/// `feature-specs/character.md` v2:
/// - PR-C: RoomWorld 골격 + 방 배경 SpriteComponent
/// - PR-D: CharacterComponent 추가
/// - PR-H (placeholder): FurnitureComponent 3개 + 위치 기반 상호작용
///
/// 기존 `presentation/widgets/room_background.dart`(PR-1)는 PR-I-part1에서 정리됨.
library;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../domain/character_action.dart';
import 'character_component.dart';
import 'encore_character_game.dart';
import 'furniture_component.dart';

/// 방 배경 PNG 원본 사이즈 (853×1844, 9:19).
/// logical viewport(480×800)에 cover-fit으로 폭 480 맞추고 높이는 비율 유지.
/// 결과 높이 = 480 × (1844 / 853) ≈ 1037 → viewport 800보다 큼 → 상하 잘림 (의도).
const double _bgAspect = 1844 / 853;

/// 캐릭터 디스플레이 정책 (PR-D / PR-M ux polish 조정).
/// 풀스크린 GameWidget(PR-M)이라 viewport 480×800이 화면 전체에 fit.
/// 채팅창이 화면 60% bottom부터 시작 (chatTopMaxRatio) → viewport y=80 라인.
/// 캐릭터 발이 채팅창 라인 약간 위에 오게 _characterFootY=120.
/// targetWidth 줄여서 머리가 viewport top 안 들어오게.
const double _characterWidth = 220;

/// 채팅창 최저선 = viewport 하단 60% ≈ y +80. 캐릭터 발 하한 = 여기(가장 앞·가장 큼).
/// 초기 위치도 여기로 두어 원근 origin(maxScale)과 일치. 채팅창선 정합은 실기 확인 후 조정.
const double _characterFootY = 80;

/// 캐릭터 발(_groundX/Y)이 이동 가능한 경계 (logical world 좌표, 원점=화면 중앙).
/// 맵이 한정적이라 이 범위 밖으로 못 나감. 실기기 확인 후 조정.
/// - X: 좌우 ±130 (viewport ±240 안, 머리·몸 화면 밖 안 나가게)
/// - minY = -140: 가장 뒤(작아짐) 한계. maxY(80) − minY = 220 = 원근 range와 정합 → 여기서 minScale.
/// - maxY = 80: 가장 앞 한계 = 채팅창 최저선. 발이 채팅창 위로 못 내려감.
const double _characterMoveX = 130;
const double _characterMinFootY = -140;
const double _characterMaxFootY = 80;

/// PR-H / PR-M — 가구 ↔ 캐릭터 상호작용 임계 거리 (logical px).
/// 캐릭터 사이즈 줄어서 임계도 조정. viewport 480의 ~27%.
const double _interactionDistance = 130;

class RoomWorld extends World with HasGameReference<EncoreCharacterGame> {
  /// 외부(RoomCanvas)에서 character.setAction(...) 호출 가능.
  /// PR-F: characterStateController 변화 → ref.listen → character.setAction.
  late final CharacterComponent character;

  /// PR-H — 가구 placeholder 3개. PNG 교체 시 sprite로 swap.
  final List<FurnitureComponent> _furniture = [];

  /// 직전 frame의 근접 가구 액션 — 같은 가구 옆에 머무를 때 setAction 반복 호출 방지.
  CharacterActionType? _lastNearbyAction;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 가구 없는 빈 방 배경 (room_empty.png). 853×1844, 9:19.
    final bgImage = await game.images.load('room_empty.png');
    add(
      SpriteComponent(
        sprite: Sprite(bgImage),
        size: Vector2(480, 480 * _bgAspect),
        anchor: Anchor.center,
        position: Vector2.zero(),
        paint: Paint()..filterQuality = FilterQuality.none,
        // 가장 아래 — 모든 y-sort 대상(가구/캐릭터/그림자)보다 뒤.
        priority: -10000,
      ),
    );

    // PR-H — 실제 가구 sprite. anchor center, targetWidth/position은 실기 확인 후 조정.
    // priority -5: 방 배경 위, 캐릭터(0)·그림자(-1) 아래 → 캐릭터가 항상 가구 앞.
    // 가구-액션 매핑: bed=sleep / desk=eat / standmic=sing / chair=happy.
    // (mirror는 배경 글로우라 보류. 매핑은 사용자 확정 후 조정.)
    // bottomMargin = PNG 불투명 영역의 바닥 여백 비율(실측) → z-order 기준선 보정.
    _furniture.addAll([
      FurnitureComponent(
        kind: FurnitureKind.bed,
        actionWhenNear: CharacterActionType.sleep,
        assetFile: 'furniture_bed.png',
        targetWidth: 210,
        bottomMargin: 0.247,
        position: Vector2(115, -50),
        anchor: Anchor.center,
      ),
      FurnitureComponent(
        kind: FurnitureKind.desk,
        actionWhenNear: CharacterActionType.eat,
        assetFile: 'furniture_desk.png',
        targetWidth: 200,
        bottomMargin: 0.293,
        position: Vector2(-120, -55),
        anchor: Anchor.center,
      ),
      FurnitureComponent(
        kind: FurnitureKind.standmic,
        actionWhenNear: CharacterActionType.sing,
        assetFile: 'furniture_standmic.png',
        targetWidth: 95,
        bottomMargin: 0.049,
        position: Vector2(150, 35),
        anchor: Anchor.center,
      ),
      FurnitureComponent(
        kind: FurnitureKind.chair,
        actionWhenNear: CharacterActionType.happy,
        assetFile: 'furniture_chair.png',
        targetWidth: 120,
        bottomMargin: 0.188,
        position: Vector2(-30, 35),
        anchor: Anchor.center,
      ),
    ]);
    for (final f in _furniture) {
      add(f);
    }

    character = CharacterComponent(
      targetWidth: _characterWidth,
      anchor: Anchor.bottomCenter,
      position: Vector2(0, _characterFootY),
      minGround: Vector2(-_characterMoveX, _characterMinFootY),
      maxGround: Vector2(_characterMoveX, _characterMaxFootY),
      // PR-F: 게임 생성 시 주입된 callback 전달. 탭 → 모먼트 + 백엔드 + haptic은 RoomCanvas 책임.
      onTap: game.onCharacterTap,
      // PR-G2: 드래그 종료 위치 저장도 RoomCanvas 책임.
      onPositionChanged: game.onPositionSaved,
      // PR-G2: 로컬 캐시 로더 — 진입 즉시 위치/액션 복원.
      loadCached: game.loadCached,
    );
    add(character);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _checkFurnitureProximity();
  }

  /// PR-H — 캐릭터가 가구 임계 거리 안에 들어오면 가구 액션 트리거.
  /// 임계 밖으로 벗어나면 _lastNearbyAction reset → 다음 진입 시 다시 발화.
  /// MVP: 가장 가까운 가구 1개만 평가. 동일 액션 연속 호출은 setAction early return.
  void _checkFurnitureProximity() {
    if (_furniture.isEmpty) return;

    final pos = character.groundPosition;
    FurnitureComponent? nearest;
    double minDist = double.infinity;
    for (final f in _furniture) {
      final dist = pos.distanceTo(f.position);
      if (dist < minDist) {
        minDist = dist;
        nearest = f;
      }
    }

    if (nearest != null && minDist < _interactionDistance) {
      final action = nearest.actionWhenNear;
      if (action != _lastNearbyAction) {
        _lastNearbyAction = action;
        character.setAction(action);
      }
    } else {
      _lastNearbyAction = null;
    }
  }
}
