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
import '../domain/furniture_placement.dart';
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

class RoomWorld extends World with HasGameReference<EncoreCharacterGame> {
  /// 외부(RoomCanvas)에서 character.setAction(...) 호출 가능.
  /// PR-F: characterStateController 변화 → ref.listen → character.setAction.
  late final CharacterComponent character;

  /// PR-H — 가구 placeholder 3개. PNG 교체 시 sprite로 swap.
  final List<FurnitureComponent> _furniture = [];

  /// 직전 frame의 근접 가구 액션 — 같은 가구 옆에 머무를 때 setAction 반복 호출 방지.
  CharacterActionType? _lastNearbyAction;

  /// 편집 모드 — true면 가구 드래그/선택 가능 + 근접 액션 트리거 멈춤.
  bool _editMode = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 가구 없는 빈 방 배경 (room_empty.png). 853×1844, 9:19.
    final bgImage = await game.images.load('room.png');
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
    // 가구 배치 — 저장된 로컬 캐시 있으면 생성 시점부터 반영(서버 대기 없이 깜빡임 0).
    final cached = await game.loadCachedFurniture?.call();
    FurnitureComponent build(
      FurnitureKind kind,
      CharacterActionType action,
      String asset,
      double w,
      double bm,
      Vector2 pos,
    ) {
      final p = cached?[kind.name];
      return FurnitureComponent(
        kind: kind,
        actionWhenNear: action,
        assetFile: asset,
        targetWidth: p?.w ?? w,
        bottomMargin: p?.bm ?? bm,
        interactionDistance: p?.dist ?? 130,
        position: p != null ? Vector2(p.x, p.y) : pos,
        anchor: Anchor.center,
      )..startHidden = cached == null;
    }

    _furniture.addAll([
      build(FurnitureKind.bed, CharacterActionType.sleep, 'furniture_bed.png',
          210, 0.247, Vector2(115, -50)),
      build(FurnitureKind.desk, CharacterActionType.eat, 'furniture_desk.png',
          200, 0.293, Vector2(-120, -55)),
      build(FurnitureKind.standmic, CharacterActionType.sing,
          'furniture_standmic.png', 95, 0.049, Vector2(150, 35)),
      build(FurnitureKind.chair, CharacterActionType.happy,
          'furniture_chair.png', 120, 0.188, Vector2(-30, 35)),
    ]);
    for (final f in _furniture) {
      f.onSelected = game.onFurnitureSelected;
      // 캐시에서 뺀 가구(visible=false)는 방에 안 넣음.
      if (cached?[f.kind.name]?.visible == false) {
        f.visible = false;
      } else {
        add(f);
      }
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
    // 편집 중엔 가구 근접 액션을 멈춤 (드래그로 위치 바꾸는 중 오발화 방지).
    if (!_editMode) _checkFurnitureProximity();
  }

  /// 편집 모드 토글 — 모든 가구 드래그/선택 가능 여부.
  void setEditMode(bool on) {
    _editMode = on;
    for (final f in _furniture) {
      f.editable = on;
    }
  }

  /// 편집 — 가구 넣기/빼기. 빼면 월드에서 제거(렌더·상호작용 X), 넣으면 다시 추가.
  void setFurnitureVisible(FurnitureKind kind, bool visible) {
    for (final f in _furniture) {
      if (f.kind != kind) continue;
      f.visible = visible;
      if (visible && f.parent == null) {
        add(f);
      } else if (!visible && f.parent != null) {
        f.removeFromParent();
      }
    }
  }

  /// 가구별 표시 상태 (편집 UI 토글용).
  Map<FurnitureKind, bool> furnitureVisibility() => {
        for (final f in _furniture) f.kind: f.visible,
      };

  /// 메시지 반응 — 액션에 해당하는 가구로 캐릭터를 보냄(도착하면 proximity가 액션 부여).
  /// 가구 없는 액션(sad 등)은 이동 없이 제자리에서 직접 setAction.
  void reactToAction(CharacterActionType action) {
    final pos = _furniturePositionForAction(action);
    if (pos != null) {
      character.setGroundPosition(pos.x, pos.y, animate: true);
    } else {
      character.setAction(action);
    }
  }

  /// 액션과 매칭되는 보이는 가구의 위치 (없으면 null).
  Vector2? _furniturePositionForAction(CharacterActionType action) {
    for (final f in _furniture) {
      if (f.visible && f.actionWhenNear == action) return f.position.clone();
    }
    return null;
  }

  /// 저장된 배치 적용 (GET state furniture_layout). 가구 kind.name 키 매칭.
  void applyFurnitureLayout(Map<String, FurniturePlacement> layout) {
    for (final f in _furniture) {
      final p = layout[f.kind.name];
      if (p != null) {
        f.setWorldPosition(p.x, p.y);
        f.setTargetWidth(p.w);
        // bm/dist는 구버전 데이터에 없으면 null → 코드 기본값(생성 시 지정) 유지.
        if (p.bm != null) f.setBottomMargin(p.bm!);
        if (p.dist != null) f.setInteractionDistance(p.dist!);
        if (p.visible != null) setFurnitureVisible(f.kind, p.visible!);
      }
      f.reveal(); // 숨겨져 있었으면 fade-in
    }
  }

  /// 저장된 배치가 없을 때 — 기본배치 그대로 fade-in (첫 진입).
  void revealFurniture() {
    for (final f in _furniture) {
      f.reveal();
    }
  }

  /// 현재 배치 수집 (저장용).
  Map<String, FurniturePlacement> currentFurnitureLayout() => {
    for (final f in _furniture)
      f.kind.name: FurniturePlacement(
        x: f.position.x,
        y: f.position.y,
        w: f.targetWidth,
        bm: f.bottomMargin,
        dist: f.interactionDistance,
        visible: f.visible,
      ),
  };

  /// PR-H — 캐릭터가 가구 임계 거리 안에 들어오면 가구 액션 트리거.
  /// 임계 밖으로 벗어나면 _lastNearbyAction reset → 다음 진입 시 다시 발화.
  /// MVP: 가장 가까운 가구 1개만 평가. 동일 액션 연속 호출은 setAction early return.
  void _checkFurnitureProximity() {
    if (_furniture.isEmpty) return;

    final pos = character.groundPosition;
    FurnitureComponent? nearest;
    double minDist = double.infinity;
    for (final f in _furniture) {
      if (!f.visible) continue; // 뺀 가구는 상호작용 제외
      final dist = pos.distanceTo(f.position);
      if (dist < minDist) {
        minDist = dist;
        nearest = f;
      }
    }

    if (nearest != null && minDist < nearest.interactionDistance) {
      final action = nearest.actionWhenNear;
      if (action != _lastNearbyAction) {
        _lastNearbyAction = action;
        character.setAction(action);
      }
    } else if (_lastNearbyAction != null) {
      // 가구에서 멀어지면 기본 idle로 복귀 (자동 랜덤 액션 없음).
      _lastNearbyAction = null;
      character.setAction(CharacterActionType.idle);
    }
  }
}
