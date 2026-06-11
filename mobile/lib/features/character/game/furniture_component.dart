/// PR-H — 가구 컴포넌트 (sprite 기반) + 편집(드래그/리사이즈).
///
/// `feature-specs/character.md` v2 "PR-H".
/// 위치 기반 상호작용:
/// - RoomWorld가 매 frame 캐릭터 ↔ 각 가구 거리 측정
/// - 임계값 이내 도달 시 actionWhenNear 트리거 (CharacterComponent.setAction)
///
/// 편집 모드(디버그 + 아이돌 본인): editable=true면 드래그 이동 + 탭 선택.
/// 크기는 RoomCanvas의 슬라이더가 setTargetWidth로 조절 (핀치는 추후).
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';

import '../domain/character_action.dart';
import 'encore_character_game.dart';

enum FurnitureKind { bed, desk, chair, standmic, mirror }

class FurnitureComponent extends SpriteComponent
    with HasGameReference<EncoreCharacterGame>, DragCallbacks, TapCallbacks {
  FurnitureComponent({
    required this.kind,
    required this.actionWhenNear,
    required this.assetFile,
    required this.targetWidth,
    this.bottomMargin = 0,
    this.interactionDistance = 130,
    this.onSelected,
    super.position,
    super.anchor,
  });

  /// 가구 종류.
  final FurnitureKind kind;

  /// 캐릭터가 본 가구 근처에 도달했을 때 트리거할 액션.
  final CharacterActionType actionWhenNear;

  /// 에셋 파일명 (assets/character/ 기준).
  final String assetFile;

  /// 화면 표시 폭 (logical). height는 PNG 원본 비율로 자동.
  double targetWidth;

  /// PNG 바닥 여백 비율 (불투명 영역이 PNG 맨 아래보다 위에 있는 정도).
  /// z-order 기준선(시각적 바닥) 계산에 사용. anchor center 전제.
  /// 가변 — 편집모드에서 앞/뒤 경계 미세조정.
  double bottomMargin;

  /// 캐릭터가 이 거리(logical px) 안에 들어오면 actionWhenNear 트리거.
  /// 가변 — 편집모드에서 가구별 조정.
  double interactionDistance;

  /// 편집 모드 — true면 드래그 이동 + 탭 선택 가능.
  bool editable = false;

  /// 방에 배치 여부 (편집모드에서 넣기/빼기). false면 RoomWorld가 월드에서 제거.
  bool visible = true;

  /// 첫 진입(캐시 없음) 시 true → opacity 0으로 시작, 배치 확정 후 reveal()로 fade-in.
  /// 캐시 있으면 false → 즉시 올바른 위치로 표시(기본위치 깜빡임 방지).
  bool startHidden = false;

  /// 알파 hit-test용 픽셀(RGBA). onLoad에서 1회 추출 → 투명 여백 탭 무시에 사용.
  ByteData? _pixels;
  int _imgW = 0;
  int _imgH = 0;

  /// 편집 모드에서 탭 선택 시 호출 (RoomCanvas가 슬라이더 표시 + 선택 가구 추적).
  void Function(FurnitureComponent)? onSelected;

  /// z-order/근접 판정의 기준이 되는 시각적 바닥 y (world 좌표).
  /// anchor center → position.y + size.y/2 가 PNG 바닥, 여백만큼 위로 보정.
  double get baseY => position.y + size.y * (0.5 - bottomMargin);

  @override
  Future<void> onLoad() async {
    final img = await game.images.load(assetFile);
    sprite = Sprite(img);
    size = Vector2(targetWidth, targetWidth * img.height / img.width);
    _imgW = img.width;
    _imgH = img.height;
    if (startHidden) opacity = 0;
    _syncPriority();
    // 알파 hit-test 픽셀은 백그라운드 추출 — onLoad를 블로킹하지 않아 가구가 즉시 표시됨.
    // (편집모드 탭은 진입 직후가 아니라 준비 완료 후라 타이밍 문제 없음.)
    unawaited(img.toByteData().then((bd) => _pixels = bd));
  }

  /// 바닥선 y를 priority로 — 캐릭터(priority=발y)와 y-sort 되어 앞뒤 자동 결정.
  void _syncPriority() {
    priority = baseY.round();
  }

  /// 편집 — 위치 설정 (저장된 배치 적용 / 드래그).
  void setWorldPosition(double x, double y) {
    position = Vector2(x, y);
    _syncPriority();
  }

  /// 편집 — 크기 설정 (슬라이더). height는 PNG 비율 유지.
  void setTargetWidth(double w) {
    targetWidth = w;
    final s = sprite;
    if (s != null) {
      size = Vector2(w, w * s.image.height / s.image.width);
    }
    _syncPriority();
  }

  /// 편집 — z-order 기준선(앞/뒤 경계) 비율 조정. baseY → priority 재계산.
  void setBottomMargin(double m) {
    bottomMargin = m;
    _syncPriority();
  }

  /// 편집 — 상호작용 거리 조정.
  void setInteractionDistance(double d) {
    interactionDistance = d;
  }

  /// 배치 확정 후 fade-in (startHidden으로 숨겨졌던 첫 진입 가구 표시).
  void reveal() {
    if (opacity >= 1) return;
    add(OpacityEffect.to(1, EffectController(duration: 0.2)));
  }

  /// hit-test — 편집모드일 때만, 그리고 불투명 픽셀일 때만 true.
  /// 1) 편집모드 아니면 제외 → 캐릭터 탭이 가구에 안 막힘.
  /// 2) 편집모드여도 PNG 투명(알파≈0) 여백 탭은 무시 → 가구 실루엣만 선택.
  @override
  bool containsLocalPoint(Vector2 point) {
    if (!editable) return false;
    if (!super.containsLocalPoint(point)) return false;
    final px = _pixels;
    if (px == null || _imgW == 0) return true;
    final ix = (point.x / size.x * _imgW).floor().clamp(0, _imgW - 1);
    final iy = (point.y / size.y * _imgH).floor().clamp(0, _imgH - 1);
    final offset = (iy * _imgW + ix) * 4 + 3; // alpha 바이트
    if (offset < 0 || offset >= px.lengthInBytes) return true;
    return px.getUint8(offset) > 16;
  }

  // ── 편집 인터랙션 (editable일 때만) ───────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    if (editable) onSelected?.call(this);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!editable) return;
    // 가구는 scale 1 (원근 미적용) → localDelta == world delta.
    position += event.localDelta;
    _syncPriority();
    onSelected?.call(this); // 드래그 중인 가구를 선택 상태로 유지
  }
}
