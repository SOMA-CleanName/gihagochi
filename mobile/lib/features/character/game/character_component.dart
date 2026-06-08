/// PR-D/E/F/G1/M — CharacterComponent (Sprite + 액션 swap + 호흡 + 랜덤 + 탭 + 드래그 + lift/shadow).
///
/// `feature-specs/character.md` v2:
/// - PR-D: 액션 PNG 6종 sprite swap 메커니즘
/// - PR-E: 호흡 (Y sine wave) + 랜덤 액션 스케줄러
/// - PR-F: 탭 인터랙션 (onTap callback)
/// - PR-G1: 드래그 인터랙션 (로컬만, 백엔드 위치 저장은 PR-G2 별도)
/// - PR-M (UX polish): 드래그 시 들림(lift) + 그림자 + 떨어지는 애니메이션
///
/// 백엔드 state ↔ setAction 동기는 RoomCanvas의 ref.listen.
library;

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart';

import '../domain/character_action.dart';

class CharacterComponent extends SpriteComponent
    with HasGameReference, TapCallbacks, DragCallbacks {
  CharacterComponent({
    required this.targetWidth,
    this.onTap,
    super.position,
    super.anchor,
  });

  final double targetWidth;

  /// PR-F — 캐릭터 탭 시 호출. 모먼트 트리거 + 백엔드 액션 호출은 외부 책임.
  /// null이면 탭 무시.
  final VoidCallback? onTap;
  CharacterActionType _action = CharacterActionType.idle;
  final Map<CharacterActionType, Sprite> _sprites = {};

  /// PNG 원본 비율 (height / width). 디자이너가 PNG 교체 시 갱신.
  /// sad만 다른 비율(941×1672) — 액션별 height 자동 계산해 stretch 방지.
  static const Map<CharacterActionType, double> _aspect = {
    CharacterActionType.idle: 1846 / 853,
    CharacterActionType.happy: 1846 / 853,
    CharacterActionType.sad: 1672 / 941,
    CharacterActionType.sing: 1846 / 853,
    CharacterActionType.eat: 1846 / 853,
    CharacterActionType.sleep: 1846 / 853,
  };

  static const Map<CharacterActionType, String> _file = {
    CharacterActionType.idle: 'character_idle.png',
    CharacterActionType.happy: 'character_happy.png',
    CharacterActionType.sad: 'character_sad.png',
    CharacterActionType.sing: 'character_sing.png',
    CharacterActionType.eat: 'character_eat.png',
    CharacterActionType.sleep: 'character_sleep.png',
  };

  // ── PR-E: 호흡 ─────────────────────────────────────────────
  /// 호흡 진폭 (logical px). viewport 800의 0.25% — 발이 미세하게 위아래.
  /// 기존 PR-3 implicit 호흡(scale ±1.8%)을 Y sine wave로 변환 (character.md v2 명시).
  static const double _breatheAmplitude = 2;

  /// 액션별 호흡 주기 (ms). 기존 PR-3 정책 그대로:
  /// sleep 천천히, sing 빠르게, 그 외 보통.
  static const Map<CharacterActionType, int> _breatheMs = {
    CharacterActionType.idle: 2800,
    CharacterActionType.happy: 2400,
    CharacterActionType.sad: 3200,
    CharacterActionType.sing: 2200,
    CharacterActionType.eat: 3400,
    CharacterActionType.sleep: 4200,
  };

  /// 호흡 base Y — onLoad에서 1회 init, 드래그 종료 시 새 위치로 갱신.
  /// PR-G2(백엔드 위치 저장) 진입 시 fetch한 저장 위치도 본 변수에 반영.
  late double _baseY;
  double _elapsed = 0;

  /// PR-G1 — 드래그 중 호흡 일시정지 (자유 위치 유지).
  bool _isDragging = false;

  // ── PR-M/N: 드래그 lift + 그림자 + 원근법 ─────────────────
  /// 들림 높이 (logical px). drag 시작 시 캐릭터를 이만큼 위로 올림.
  static const double _liftHeight = 24;

  /// 떨어지는 애니메이션 시간.
  static const double _settleDurationSec = 0.18;

  /// 현재 들려있는 높이 (0 = 바닥, _liftHeight = 들림 상태).
  /// drag 중에는 _liftHeight, drag 끝나면 0으로 애니메이션.
  double _liftOffset = 0;

  /// 그림자 컴포넌트 — drag 시작 시 parent에 add, drag 끝 + 안착 후 remove.
  late final CircleComponent _shadow;

  /// PR-N — 그림자 y 보정. 캐릭터 PNG 안 실제 발 위치가 PNG bottom(anchor)보다
  /// 약간 위에 있어서 그림자가 너무 아래로 빠짐 → 위로 끌어올림.
  /// 양수 = 위로 (logical px). 검증 후 미세 조정.
  static const double _shadowFootOffset = -16;

  // ── PR-N: 원근법 ────────────────────────────────────────────
  /// 가장 앞쪽(max scale) 기준 y. onLoad에서 초기 발 위치로 init.
  /// 사용자가 캐릭터를 뒤로 끌면 (position.y < _perspectiveOriginY) scale 작아짐.
  late final double _perspectiveOriginY;

  /// 원근 거리 범위 (logical px). originY에서 이만큼 뒤로 가면 minScale.
  static const double _perspectiveRange = 220;
  static const double _perspectiveMaxScale = 1.0;
  static const double _perspectiveMinScale = 0.55;

  // ── PR-E: 랜덤 액션 스케줄러 ──────────────────────────────
  /// 다음 랜덤 액션 발화 시각 (_elapsed 기준). 5~12s 사이 랜덤.
  double _nextActionAt = 0;

  /// idle 가중치 — 50%면 절반은 idle 유지, 안정적 분포.
  static const double _idleProbability = 0.5;

  /// 랜덤 액션 간격 (초). [_minDelay, _maxDelay] 사이.
  static const double _minDelay = 5;
  static const double _maxDelay = 12;

  final Random _rng = Random();

  CharacterActionType get currentAction => _action;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    for (final action in CharacterActionType.values) {
      final img = await game.images.load(_file[action]!);
      _sprites[action] = Sprite(img);
    }

    _baseY = position.y;
    _perspectiveOriginY = position.y;
    _applyAction(_action);
    paint = Paint()..filterQuality = FilterQuality.none;
    _scheduleNextAction();

    // PR-M — 그림자 컴포넌트 미리 생성 (drag 시작 시 parent에 add).
    // 타원 효과를 위해 scale y 작게 (가로 길게, 세로 짧게).
    _shadow = CircleComponent(
      radius: 60,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0x4D000000), // black 30%
      // 방 배경(-10)보다 위, 캐릭터(0)보다 아래.
      priority: -1,
    )..scale = Vector2(1.0, 0.25);
  }

  /// PR-N — 원근법 + 그림자 scale 동기.
  /// position.y가 _perspectiveOriginY보다 작아질수록(뒤로) scale 작아짐.
  /// 매 frame 호출 — 호흡으로 미세 변동되지만 시각적 무관(0.4% 정도).
  void _applyPerspectiveScale() {
    final delta = _perspectiveOriginY - position.y;
    final t = (delta / _perspectiveRange).clamp(0.0, 1.0);
    final s = _perspectiveMaxScale -
        (_perspectiveMaxScale - _perspectiveMinScale) * t;
    scale = Vector2.all(s);
    // 그림자도 같이 작아짐. 본래 scale.y는 0.25(타원) 유지.
    _shadow.scale = Vector2(s, 0.25 * s);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    // PR-G1 — 드래그 중엔 자유 위치 유지 + 호흡 일시정지 + 액션 스케줄러 멈춤.
    // PR-N — 드래그 중에도 원근법은 적용 (사용자가 뒤로 끌면 작아지는 시각 효과).
    if (_isDragging) {
      _applyPerspectiveScale();
      return;
    }

    // 호흡 — Y sine wave (character.md v2 명시).
    final periodSec = _breatheMs[_action]! / 1000;
    final wave = sin(_elapsed * 2 * pi / periodSec);
    position.y = _baseY + wave * _breatheAmplitude;

    // PR-N — 원근법 매 frame 적용 (호흡 + 드래그 + settle 애니메이션 중에도).
    _applyPerspectiveScale();

    // 랜덤 액션 스케줄러.
    if (_elapsed >= _nextActionAt) {
      _triggerRandomAction();
      _scheduleNextAction();
    }
  }

  void _scheduleNextAction() {
    final delay = _minDelay + _rng.nextDouble() * (_maxDelay - _minDelay);
    _nextActionAt = _elapsed + delay;
  }

  void _triggerRandomAction() {
    if (_rng.nextDouble() < _idleProbability) {
      setAction(CharacterActionType.idle);
      return;
    }
    // 나머지 5종 동등 분포 (현재 액션과 같아도 setAction이 early return).
    const others = [
      CharacterActionType.happy,
      CharacterActionType.sad,
      CharacterActionType.sing,
      CharacterActionType.eat,
      CharacterActionType.sleep,
    ];
    setAction(others[_rng.nextInt(others.length)]);
  }

  /// 액션 전환 — sprite + size 동기 갱신.
  /// PR-F에서 백엔드 state 변경 시 본 메서드 호출.
  void setAction(CharacterActionType next) {
    if (next == _action) return;
    _action = next;
    _applyAction(next);
  }

  void _applyAction(CharacterActionType action) {
    // Defensive — onLoad 끝나기 전에 setAction 호출되면 sprite null. 다음 적용에서 따라감.
    final s = _sprites[action];
    if (s == null) return;
    sprite = s;
    size = Vector2(targetWidth, targetWidth * _aspect[action]!);
  }

  // ── PR-F: 탭 인터랙션 ─────────────────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    onTap?.call();
  }

  // ── PR-G1/M/N: 드래그 + 들림/그림자/안착/원근법 ──────────
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;

    // PR-M — 들림 효과 + 그림자 표시.
    // 그림자는 캐릭터 실제 발 위치 = position.y + _liftOffset + _shadowFootOffset (PR-N PNG 보정).
    _liftOffset = _liftHeight;
    position.y -= _liftHeight;
    _shadow.position = Vector2(
      position.x,
      position.y + _liftOffset + _shadowFootOffset,
    );
    parent?.add(_shadow);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    // PR-M/N — 그림자도 따라감 (캐릭터 실제 발 위치).
    _shadow.position = Vector2(
      position.x,
      position.y + _liftOffset + _shadowFootOffset,
    );
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;

    // PR-M — 들림 풀기: 떨어지는 애니메이션 (easeIn = 가속).
    // landingY = 현재 그림자가 표시된 발 위치. 캐릭터(position)가 그림자 자리로 떨어짐.
    final landingY = position.y + _liftOffset;
    add(
      MoveToEffect(
        Vector2(position.x, landingY),
        EffectController(
          duration: _settleDurationSec,
          curve: Curves.easeIn,
        ),
        onComplete: () {
          _liftOffset = 0;
          _baseY = position.y;
          if (_shadow.parent != null) {
            _shadow.removeFromParent();
          }
        },
      ),
    );
    // PR-G2: 백엔드 POST /character/{idol}/position 호출 (마이그레이션 동반, 별도 PR).
  }
}
