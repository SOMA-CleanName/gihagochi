/// PR-D/E/F/G1/M~P + 좌표계 재설계 — CharacterComponent
/// (Sprite + 액션 swap + 호흡 + 랜덤 + 탭 + 드래그 + lift/shadow/원근).
///
/// 좌표 모델 (single source of truth):
/// - (_groundX, _groundY): 캐릭터 발이 닿는 "논리 바닥" 위치. 드래그로만 변경 + 경계 clamp.
/// - _liftOffset: 시각 들림 (0~_liftHeight). 드래그 시작 = _liftHeight, 끝나면 0으로 감쇠.
/// - _breatheOffset: 호흡 sine 시각 오프셋.
/// 매 프레임 position = (_groundX, _groundY - _liftOffset + _breatheOffset) 로 파생.
/// scale·그림자는 _groundY 에만 의존 → 들 때와 놓을 때 크기·발 위치가 완전 일관.
/// anchor = bottomCenter 전제 → 액션별 PNG height 달라도 발(=position.y)은 고정 = 하단 정렬.
///
/// 백엔드 state ↔ setAction 동기는 RoomCanvas의 ref.listen.
library;

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../data/character_cache.dart';
import '../domain/character_action.dart';

class CharacterComponent extends SpriteComponent
    with HasGameReference, TapCallbacks, DragCallbacks {
  CharacterComponent({
    required this.targetWidth,
    required this.minGround,
    required this.maxGround,
    this.onTap,
    this.onPositionChanged,
    this.loadCached,
    super.position,
    super.anchor,
  });

  /// PR-G2 — onLoad에서 호출. 캐시된 위치/액션 있으면 즉시 복원 (서버 fetch 대기 X).
  final Future<CachedCharacter?> Function()? loadCached;

  final double targetWidth;

  /// 발 (_groundX, _groundY)이 움직일 수 있는 경계 (logical world 좌표).
  /// 맵이 한정적이라 이 범위 밖으로 못 나감. 실기기 확인 후 RoomWorld 상수로 조정.
  final Vector2 minGround;
  final Vector2 maxGround;

  /// PR-F — 캐릭터 탭 시 호출. 모먼트 트리거 + 백엔드 액션 호출은 외부 책임.
  /// null이면 탭 무시.
  final VoidCallback? onTap;

  /// PR-G2 — 드래그 종료 시 호출(논리 바닥 좌표). 백엔드 위치 저장은 외부 책임.
  final void Function(double x, double y)? onPositionChanged;
  CharacterActionType _action = CharacterActionType.idle;
  final Map<CharacterActionType, Sprite> _sprites = {};

  /// PNG 원본 비율 (height / width). 실제 PNG 사이즈로 측정. 교체 시 갱신.
  /// 액션별 height 자동 계산해 stretch 방지.
  static const Map<CharacterActionType, double> _aspect = {
    CharacterActionType.idle: 1844 / 853,
    CharacterActionType.happy: 1846 / 852,
    CharacterActionType.sad: 1672 / 941,
    CharacterActionType.sing: 1846 / 852,
    CharacterActionType.eat: 1843 / 853,
    CharacterActionType.sleep: 1846 / 852,
  };

  /// 액션별 발바닥 여백 비율 = (PNG height − 캐릭터 불투명 bottom) / PNG height.
  /// 캐릭터 발이 PNG 맨 아래보다 이 비율만큼 위에 떠 있음 (alpha>128 측정).
  /// 이 값으로 position을 보정해 "시각적 발바닥"을 _groundY(바닥)에 정합.
  /// → 액션이 바뀌어도 바닥 위치 일정 (서있든 앉았든 동일). PNG 교체 시 재측정.
  static const Map<CharacterActionType, double> _footRatio = {
    CharacterActionType.idle: 0.229,
    CharacterActionType.happy: 0.249,
    CharacterActionType.sad: 0.192,
    CharacterActionType.sing: 0.250,
    CharacterActionType.eat: 0.324,
    CharacterActionType.sleep: 0.350,
  };

  static const Map<CharacterActionType, String> _file = {
    CharacterActionType.idle: 'character_idle.png',
    CharacterActionType.happy: 'character_happy.png',
    CharacterActionType.sad: 'character_sad.png',
    CharacterActionType.sing: 'character_sing.png',
    CharacterActionType.eat: 'character_eat.png',
    CharacterActionType.sleep: 'character_sleep.png',
  };

  // ── 좌표 모델 (source of truth) ────────────────────────────
  /// 발이 닿는 논리 바닥. 생성자 position으로 lazy init (부모 update가 onLoad보다
  /// 먼저 groundPosition을 읽어도 안전), 이후 드래그로만 변경.
  late double _groundX = position.x;
  late double _groundY = position.y;

  // ── PR-E: 호흡 ─────────────────────────────────────────────
  /// 호흡 진폭 (scale 비율). 발 고정한 채 세로로 미세하게 늘었다 줄었다 (숨쉬는 느낌).
  /// y 위치는 흔들지 않음 — 둥둥 뜨는 느낌 방지.
  static const double _breatheScaleAmp = 0.018;

  /// 액션별 호흡 주기 (ms). sleep 천천히, sing 빠르게, 그 외 보통.
  static const Map<CharacterActionType, int> _breatheMs = {
    CharacterActionType.idle: 2800,
    CharacterActionType.happy: 2400,
    CharacterActionType.sad: 3200,
    CharacterActionType.sing: 2200,
    CharacterActionType.eat: 3400,
    CharacterActionType.sleep: 4200,
  };

  double _elapsed = 0;

  /// 드래그 중 — 호흡·랜덤 액션 일시정지, 위치 자유.
  bool _isDragging = false;

  /// 손가락으로 누르고 있음 (tap down ~ up). 드래그가 아니어도 들어올림.
  bool _isHeld = false;

  // ── PR-M~P: 드래그 lift + 그림자 + 원근법 ─────────────────
  /// 들림 높이 (logical px). drag 중 캐릭터를 이만큼 위로 시각 이동.
  static const double _liftHeight = 24;

  /// 착지(들림 풀림) 시간 (초). _liftOffset이 _liftHeight→0 까지 걸리는 시간.
  static const double _settleDurationSec = 0.18;

  /// 현재 들림 시각 오프셋 (0 = 바닥, _liftHeight = 완전히 들림).
  double _liftOffset = 0;

  /// 그림자 — onLoad에서 항상 표시 (서있을 때도). _groundY(시각적 발바닥)에 고정.
  late final CircleComponent _shadow;

  // ── 원근법 ──────────────────────────────────────────────────
  /// 가장 앞쪽(maxScale) 기준 발 y = 발 하한(maxGround.y, 채팅창 최저선).
  /// 초기/복원 위치와 무관하게 고정 → 원근 기준 안정. 뒤로(작은 y) 갈수록 scale 작아짐.
  late final double _perspectiveOriginY = maxGround.y;

  /// 원근 거리 범위 (logical px). originY에서 이만큼 뒤로 가면 minScale.
  static const double _perspectiveRange = 220;
  static const double _perspectiveMaxScale = 1.0;
  static const double _perspectiveMinScale = 0.55;

  /// viewport 반폭 (logical). CameraComponent fixedResolution 480 → 240.
  /// 좌우 한계를 원근 scale에 맞춰 넓힐 때 화면 끝 기준값.
  static const double _halfViewportX = 240;

  CharacterActionType get currentAction => _action;

  /// 캐릭터 발이 닿는 논리 바닥 위치 (lift·호흡·footRatio 보정 전).
  /// 가구 근접 판정 등 "캐릭터가 실제 어디 서있나"는 position 대신 이걸 사용.
  Vector2 get groundPosition => Vector2(_groundX, _groundY);

  /// PR-G2 — 저장 위치 복원. animate면 현재 위치에서 부드럽게 이동(등장 후 점프 방지).
  Vector2? _moveTarget;
  void setGroundPosition(double x, double y, {bool animate = false}) {
    final cy = y.clamp(minGround.y, maxGround.y);
    final xl = _xLimitForGround(cy);
    final cx = x.clamp(-xl, xl);
    if (animate) {
      _moveTarget = Vector2(cx, cy);
    } else {
      _groundX = cx;
      _groundY = cy;
      _moveTarget = null;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    for (final action in CharacterActionType.values) {
      final img = await game.images.load(_file[action]!);
      _sprites[action] = Sprite(img);
    }

    // PR-G2 — 캐시된 위치/액션 즉시 복원 (서버 응답 대기 없이 진입 즉시 정확한 모습).
    final cached = await loadCached?.call();
    if (cached != null) {
      _groundX = cached.x.clamp(minGround.x, maxGround.x);
      _groundY = cached.y.clamp(minGround.y, maxGround.y);
      _action = cached.action;
    }

    _applyAction(_action);
    paint = Paint()..filterQuality = FilterQuality.none;

    // 타원 그림자 — 가로 길게, 세로 짧게(0.25). 매 프레임 scale/위치 갱신됨.
    // 항상 표시 (서있을 때도) — 캐릭터 발밑 바닥에 고정.
    _shadow = CircleComponent(
      radius: 60,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0x4D000000), // black 30%
      // 방 배경(-10)보다 위, 캐릭터(0)보다 아래.
      priority: -1,
    );

    // PR-G2 — 이미지 로드 직후 등장 (위치 fetch를 기다리지 않음 → 5초 빈방 방지).
    // 복원은 setGroundPosition(animate:true)로 부드럽게 이동하므로 점프도 없음.
    opacity = 0;
    reveal();
  }

  /// PR-G2 — 첫 위치 확정 후 캐릭터+그림자 등장 (페이드인). 점프 깜빡임 방지.
  bool _revealed = false;
  void reveal() {
    if (_revealed) return;
    _revealed = true;
    if (_shadow.parent == null) parent?.add(_shadow);
    add(OpacityEffect.to(1, EffectController(duration: 0.25)));
  }

  /// 원근법 scale — _groundY 에만 의존 (lift·호흡 무관).
  /// → 드래그 중 ↔ 착지 후 크기 완전 일관 (들었을 때와 놓았을 때 같음).
  double _scaleForGround([double? groundY]) {
    final y = groundY ?? _groundY;
    final delta = _perspectiveOriginY - y;
    final t = (delta / _perspectiveRange).clamp(0.0, 1.0);
    return _perspectiveMaxScale -
        (_perspectiveMaxScale - _perspectiveMinScale) * t;
  }

  /// 원근 보정 좌우 한계 — 뒤(작은 scale)일수록 캐릭터가 작아지므로
  /// 화면 끝까지 갈 수 있게 |x| 한계를 넓힘. 앞쪽(maxGround.x)보다 작아지진 않음.
  double _xLimitForGround(double groundY) {
    final s = _scaleForGround(groundY);
    return max(maxGround.x, _halfViewportX - targetWidth * s / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    // PR-G2 — 복원 위치로 부드럽게 이동 (드래그/누르는 중엔 멈춤).
    final target = _moveTarget;
    if (target != null && !_isDragging && !_isHeld) {
      final k = (dt * 8).clamp(0.0, 1.0);
      _groundX += (target.x - _groundX) * k;
      _groundY += (target.y - _groundY) * k;
      if ((target.x - _groundX).abs() < 0.5 && (target.y - _groundY).abs() < 0.5) {
        _groundX = target.x;
        _groundY = target.y;
        _moveTarget = null;
      }
    }

    // 들림 — 누르거나 드래그하는 동안 떠오르고, 떼면 착지. 부드럽게 보간.
    // position을 직접 옮기지 않으므로 호흡과 충돌하지 않음. 그림자는 항상 유지.
    final holding = _isHeld || _isDragging;
    final liftTarget = holding ? _liftHeight : 0.0;
    if (_liftOffset != liftTarget) {
      final step = _liftHeight * dt / _settleDurationSec;
      _liftOffset = (_liftOffset < liftTarget)
          ? min(_liftOffset + step, liftTarget)
          : max(_liftOffset - step, liftTarget);
    }

    // 호흡 — 세로 미세 scale (발 고정, 머리만 살짝). y 위치는 안 흔듦. 누르는 중 멈춤.
    var breatheScale = 1.0;
    if (!holding) {
      final periodSec = _breatheMs[_action]! / 1000;
      breatheScale = 1 + sin(_elapsed * 2 * pi / periodSec) * _breatheScaleAmp;
    }

    // scale·position·그림자를 source of truth에서 파생.
    // baseScale = 원근만, s = 원근 × 호흡. footLift가 s를 반영하므로 호흡해도 발 고정.
    final baseScale = _scaleForGround();
    final s = baseScale * breatheScale;
    scale = Vector2.all(s);

    // 시각적 발바닥(footRatio 보정)을 _groundY 에 정합 → 액션 바뀌어도 바닥 일정.
    // anchor bottomCenter 기준 position.y = PNG bottom 이므로, 발이 위로 뜬 만큼 더해줌.
    final footLift = size.y * s * _footRatio[_action]!;
    position = Vector2(_groundX, _groundY - _liftOffset + footLift);

    // 그림자 — 들림·액션·호흡과 무관하게 _groundY(시각적 발바닥)에 고정. 원근 scale만 반영.
    _shadow
      ..position = Vector2(_groundX, _groundY)
      ..scale = Vector2(baseScale, 0.25 * baseScale);

    // z-order — 발 y를 priority로 → 가구(priority=바닥선)와 y-sort 되어 앞뒤 자동.
    // 발이 가구 바닥보다 아래(앞)면 priority 큼 → 가구 앞에 그려짐.
    priority = _groundY.round();
    _shadow.priority = priority - 1;
  }

  /// 액션 전환 — sprite + size 동기 갱신.
  /// PR-F에서 백엔드 state 변경 시 본 메서드 호출.
  void setAction(CharacterActionType next) {
    if (next == _action) return;
    _action = next;
    _applyAction(next);
  }

  void _applyAction(CharacterActionType action) {
    // Defensive — onLoad 끝나기 전 setAction 호출되면 sprite null. 다음 적용에서 따라감.
    final s = _sprites[action];
    if (s == null) return;
    sprite = s;
    // anchor bottomCenter → size.y 바뀌어도 발(position.y) 고정 = 하단 정렬 유지.
    size = Vector2(targetWidth, targetWidth * _aspect[action]!);
  }

  // ── PR-F: 탭/누르기 인터랙션 ──────────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    // 누르는 즉시 들어올림 (드래그 없이 길게 눌러도 떠 있음). 착지는 onTapUp.
    _isHeld = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isHeld = false;
    onTap?.call();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    // 드래그로 전환되면 tap cancel — 들림은 _isDragging이 이어받음.
    _isHeld = false;
  }

  // ── PR-G1/M~P: 드래그 + 들림/그림자/착지/원근법 ────────────
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    // 들림은 update()가 _liftHeight로 부드럽게 올림. 그림자는 항상 표시 중.
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // localDelta는 캐릭터 scale 좌표계 기준 → 부모(World) 좌표로 변환(* scale)해야
    // 손가락 이동과 1:1 정합. 원근으로 작아진 상태에서 과이동하던 오차 제거.
    _groundY = (_groundY + event.localDelta.y * scale.y)
        .clamp(minGround.y, maxGround.y);
    final xl = _xLimitForGround(_groundY);
    _groundX = (_groundX + event.localDelta.x * scale.x).clamp(-xl, xl);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
    // update()가 _liftOffset을 0으로 감쇠 → 발이 그림자(=_groundY) 중앙으로 안착.
    // PR-G2 — 드래그 종료 시에만 위치 저장 (백엔드 호출은 외부 책임).
    onPositionChanged?.call(_groundX, _groundY);
  }
}
