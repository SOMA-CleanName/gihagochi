/// F-039 + F-040 — 캐릭터 방 + 정적 캐릭터 + 드래그 가능한 채팅 오버레이.
///
/// chat_room의 `chatRoomCharacterSlotProvider`가 본 위젯으로 override되어
/// 채팅방 풀스크린에 표시됨.
///
/// 레이아웃:
/// - 방 배경 + 캐릭터 = 풀스크린 (Positioned.fill, 자르지 않음)
/// - 채팅창 = Positioned(top: 동적, bottom: 0) — 채팅창만 위/아래 드래그
/// - 채팅창 top 범위 = [chatTopMin (화면×0.20), chatTopMax (화면×0.60)]
/// - 채팅창은 반투명 + blur → 뒤 방 배경 은은하게 비침
library;

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../chat_message/application/chat_messages_controller.dart';
import '../../chat_message/domain/chat_item.dart';
import '../../chat_message/domain/message.dart';
import '../../chat_message/presentation/message_input.dart';
import '../../chat_message/presentation/message_list.dart';
import '../application/character_moment_controller.dart';
import '../application/character_state_controller.dart';
import '../data/character_cache.dart';
import '../data/character_repository.dart';
import '../domain/character_action.dart';
import '../domain/character_moment.dart';
import '../domain/message_action.dart';
import '../game/encore_character_game.dart';
import '../game/furniture_component.dart';
import '../game/room_world.dart';
import 'widgets/moment_card.dart';

// ── 드래그 범위 상수 (조정 가능) ──────────────────
/// 채팅창 최대로 올렸을 때 — 화면 상단에서 이 비율 위치까지 올라감.
/// 작을수록 위로 더 올라감(채팅창 커짐). AppBar 아래.
const double chatTopMinRatio = 0.20;

/// 채팅창 최대로 내렸을 때 — 화면 상단에서 이 비율 위치까지 내려감.
/// 클수록 아래로 더 내려감(채팅창 작아짐, 캐릭터 영역 커짐).
const double chatTopMaxRatio = 0.60;

/// drag end 시 snap 임계 속도 (px/s). 이 이상이면 방향대로 snap.
const double _snapVelocityThreshold = 400;

class RoomCanvas extends ConsumerWidget {
  const RoomCanvas({super.key, required this.idolId});

  final String idolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _RoomCanvasInner(idolId: idolId);
  }
}

class _RoomCanvasInner extends ConsumerStatefulWidget {
  const _RoomCanvasInner({required this.idolId});
  final String idolId;

  @override
  ConsumerState<_RoomCanvasInner> createState() => _RoomCanvasInnerState();
}

class _RoomCanvasInnerState extends ConsumerState<_RoomCanvasInner>
    with SingleTickerProviderStateMixin {
  /// 0.0 = 채팅창 가장 아래(top=maxRatio, 캐릭터 영역 최대)
  /// 1.0 = 채팅창 가장 위(top=minRatio, 채팅 영역 최대)
  late final AnimationController _expand;
  bool _isDragging = false;

  /// PR-G2 — 저장된 위치를 최초 1회만 복원 (이후 드래그 저장으로 인한 재호출 무시).
  bool _positionRestored = false;

  /// PR-G2 — 위치/액션 로컬 캐시 (진입 즉시 복원).
  final CharacterCache _cache = CharacterCache();

  /// 가구 편집 모드 (디버그 + 아이돌 본인만). 저장된 배치 최초 1회 적용 플래그.
  bool _editMode = false;
  bool _furnitureRestored = false;
  FurnitureComponent? _selectedFurniture;

  /// 메시지 반응 — 진입 후 새로 도착한 아이돌 메시지에만 1회 반응 (중복·과거 방지).
  String? _lastReactedMessageId;
  bool _reactionInitialized = false;

  /// 편집 가능 여부 = 디버그 빌드 + 로그인 사용자가 이 아이돌 본인.
  bool get _canEdit {
    if (!kDebugMode) return false;
    final me = ref.read(supabaseProvider).auth.currentUser?.id;
    return me != null && me == widget.idolId;
  }

  /// PR-B 시범 — flame 게임 인스턴스 보존 (매 rebuild 재생성 방지).
  /// PR-I에서 RoomCanvas 자체 정리 시 _game 라이프사이클은 새 위젯으로 이관.
  late final EncoreCharacterGame _game;

  @override
  void initState() {
    super.initState();
    // 기본 = 중간보다 약간 아래 (캐릭터 영역 더 보임).
    _expand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 0.0, // 초기 = 가장 내림 (캐릭터 영역 최대)
    );
    _game = EncoreCharacterGame(
      onCharacterTap: _handleCharacterTap,
      onPositionSaved: _handlePositionSaved,
      loadCached: () => _cache.read(widget.idolId),
      loadCachedFurniture: () => _cache.readFurniture(widget.idolId),
      onFurnitureSelected: _handleFurnitureSelected,
    );
  }

  void _handleFurnitureSelected(FurnitureComponent f) {
    if (!_editMode) return;
    if (_selectedFurniture != f) setState(() => _selectedFurniture = f);
  }

  void _toggleEdit() {
    final world = _game.world;
    if (world is! RoomWorld) return;
    setState(() {
      _editMode = !_editMode;
      _selectedFurniture = null;
      world.setEditMode(_editMode);
    });
  }

  /// 편집 종료 + 배치 저장 (아이돌 본인만 서버 허용). 로컬은 즉시 반영돼 있음.
  Future<void> _saveFurnitureAndExit() async {
    final world = _game.world;
    if (world is RoomWorld) {
      final layout = world.currentFurnitureLayout();
      // 로컬 캐시 즉시 갱신 → 다음 진입 시 서버 대기 없이 복원(깜빡임 방지).
      unawaited(_cache.writeFurniture(widget.idolId, layout));
      final repo = ref.read(characterRepositoryProvider);
      unawaited(
        repo.saveFurniture(widget.idolId, layout).then(
          (_) {},
          onError: (_, __) {},
        ),
      );
      world.setEditMode(false);
    }
    setState(() {
      _editMode = false;
      _selectedFurniture = null;
    });
  }

  void _onFurnitureSizeChanged(double w) {
    final f = _selectedFurniture;
    if (f == null) return;
    f.setTargetWidth(w);
    setState(() {}); // 슬라이더 값 반영
  }

  /// 앞/뒤 z-order 기준선 조정 (값 ↑ = 바닥선 위로 = 캐릭터가 더 앞에 옴).
  void _onFurnitureBottomMarginChanged(double m) {
    final f = _selectedFurniture;
    if (f == null) return;
    f.setBottomMargin(m);
    setState(() {});
  }

  /// 가구별 상호작용 거리 조정 (캐릭터가 이 거리 안에 오면 액션 트리거).
  void _onFurnitureDistanceChanged(double d) {
    final f = _selectedFurniture;
    if (f == null) return;
    f.setInteractionDistance(d);
    setState(() {});
  }

  /// 가구 넣기/빼기 토글.
  void _toggleFurnitureVisible(FurnitureKind kind) {
    final world = _game.world;
    if (world is! RoomWorld) return;
    final on = world.furnitureVisibility()[kind] ?? true;
    world.setFurnitureVisible(kind, !on);
    // 빼는 가구가 선택돼 있었다면 선택 해제.
    if (on && _selectedFurniture?.kind == kind) _selectedFurniture = null;
    setState(() {});
  }

  Map<FurnitureKind, bool> _furnitureVisibility() {
    final world = _game.world;
    return world is RoomWorld ? world.furnitureVisibility() : const {};
  }

  /// 메시지 리스트에서 가장 최근 아이돌 broadcast 메시지 (없으면 null).
  Message? _latestIdolMessage(List<ChatItem> items) {
    for (final item in items.reversed) {
      if (item is ConfirmedItem) {
        final m = item.message;
        if (m.senderId == widget.idolId &&
            (m.type == MessageType.idolToFans ||
                m.type == MessageType.idolReply)) {
          return m;
        }
      }
    }
    return null;
  }

  /// PR-G2 — 드래그 종료 시 위치 저장. 실패해도 로컬 위치는 유지(스낵바 X — 조용히).
  /// 1) 로컬 캐시 낙관적 갱신(서버 응답 X) → 다음 진입 즉시 복원
  /// 2) keepAlive dio repository로 직접 fire-and-forget (화면 바로 나가도 진행)
  void _handlePositionSaved(double x, double y) {
    if (!mounted) return;
    final action = ref
            .read(characterStateControllerProvider(widget.idolId))
            .value
            ?.currentAction ??
        CharacterActionType.idle;
    unawaited(_cache.write(widget.idolId, x, y, action));
    final repo = ref.read(characterRepositoryProvider);
    unawaited(
      repo.savePosition(widget.idolId, x, y).then(
        (_) {},
        onError: (_, __) {}, // 저장 실패는 조용히 무시 (다음 드래그에서 재시도)
      ),
    );
  }

  /// PR-F — flame 캐릭터 탭 시 호출.
  /// 1) haptic
  /// 2) 모먼트 카드 (tap kind)
  /// 3) 백엔드 액션 트리거 (happy) — 응답 시 state 변경 → ref.listen이 character.setAction(happy)
  void _handleCharacterTap() {
    HapticFeedback.lightImpact();
    ref
        .read(characterMomentControllerProvider(widget.idolId).notifier)
        .show(CharacterMomentKind.tap);
    unawaited(
      ref
          .read(characterStateControllerProvider(widget.idolId).notifier)
          .trigger(CharacterActionType.happy),
    );
  }

  @override
  void dispose() {
    _expand.dispose();
    super.dispose();
  }

  double _chatTopFor(double screenH, double v) {
    // v=1이면 minRatio (위), v=0이면 maxRatio (아래)
    return lerpDouble(
      screenH * chatTopMaxRatio,
      screenH * chatTopMinRatio,
      v,
    )!;
  }

  double get _range {
    final h = MediaQuery.of(context).size.height;
    return h * (chatTopMaxRatio - chatTopMinRatio);
  }

  void _onDragStart(DragStartDetails _) {
    _expand.stop();
    setState(() => _isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_range <= 0) return;
    // 핸들 위로 끄는 건 dy<0 → 채팅창 위로(value 증가)
    // 아래로 끄는 건 dy>0 → 채팅창 아래로(value 감소)
    _expand.value =
        (_expand.value - details.delta.dy / _range).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    final v = details.velocity.pixelsPerSecond.dy;
    // 빠른 플릭만 방향대로 끝까지 snap. 천천히 놓으면 그 위치에 그대로 멈춤(중간 정지 가능).
    if (v.abs() > _snapVelocityThreshold) {
      _expand.animateTo(v < 0 ? 1.0 : 0.0, curve: Curves.easeOutCubic);
    }
  }

  void _onHandleTap() {
    final target = _expand.value > 0.5 ? 0.0 : 1.0;
    _expand.animateTo(target, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    // PR-F — 백엔드 state 변경 시 flame character sprite 동기.
    // 트리거 경로: 탭 / PR-2 디버그 메뉴 / cron / AI(v2) 모두 동일하게 흘러옴.
    ref.listen(characterStateControllerProvider(widget.idolId), (prev, next) {
      next.whenData((state) {
        final world = _game.world;
        if (world is RoomWorld) {
          world.character.setAction(state.currentAction);
          // PR-G2 — 첫 응답에 저장 위치로 부드럽게 이동 (캐릭터는 이미 등장해 있음).
          if (!_positionRestored) {
            _positionRestored = true;
            if (state.positionX != null && state.positionY != null) {
              world.character.setGroundPosition(
                state.positionX!,
                state.positionY!,
                animate: true,
              );
            }
          }
          // 가구 배치 최초 1회 복원 (아이돌별, 모든 팬 공유).
          if (!_furnitureRestored) {
            _furnitureRestored = true;
            final layout = state.furnitureLayout;
            if (layout != null) {
              // 서버 값으로 위치/크기는 복원하되, 캐시(로컬 저장값)는 덮지 않음.
              // 서버가 구버전이라 bm/dist가 비어도 캐시의 정상값이 초기화되지 않게.
              world.applyFurnitureLayout(layout);
            } else {
              // 저장된 배치 없음 — 숨겨둔 기본배치 fade-in.
              world.revealFurniture();
            }
          }
        }
      });
    });

    // 아이돌 메시지 도착 → 키워드 분석 → 캐릭터 반응(가구로 이동/액션). 진입 후 새 메시지만.
    ref.listen(chatMessagesControllerProvider(widget.idolId), (prev, next) {
      next.whenData((items) {
        final msg = _latestIdolMessage(items);
        if (!_reactionInitialized) {
          _reactionInitialized = true;
          _lastReactedMessageId = msg?.id; // 진입 시점 마지막 메시지엔 반응 안 함
          return;
        }
        if (msg == null || msg.id == _lastReactedMessageId) return;
        _lastReactedMessageId = msg.id;
        final action = analyzeMessageAction(msg.content ?? '');
        if (action == null) return;
        final world = _game.world;
        if (world is RoomWorld) world.reactToAction(action);
      });
    });

    // 채팅 카드(MessageList 포함)는 _expand 애니메이션·드래그 중 재빌드되면 안 됨
    // (이미지 리로드·깜빡임 방지). AnimatedBuilder의 child로 고정 → 위치(top)만 갱신.
    final chatCard = _ChatCard(
      idolId: widget.idolId,
      isDragging: _isDragging,
      onDragStart: _onDragStart,
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
      onHandleTap: _onHandleTap,
    );

    return AnimatedBuilder(
      animation: _expand,
      child: chatCard,
      builder: (context, child) {
        final screenH = MediaQuery.of(context).size.height;
        final chatTop = _chatTopFor(screenH, _expand.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: flame GameWidget — 방 + 캐릭터 화면 풀스크린.
            // AppBar 뒤(extendBodyBehindAppBar) + 채팅창 영역까지 전체 채움.
            // 채팅창은 반투명 overlay라 GameWidget 비침. character.md v2 영역 1 명세.
            Positioned.fill(
              child: GameWidget(game: _game),
            ),
            // Layer 2: 채팅창 — top만 동적, bottom=0. child로 고정돼 재빌드 안 됨.
            Positioned(
              top: chatTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: child!,
            ),
            // Layer 3 (F-044): 모먼트 카드 — 별도 Consumer로 구독해 moment 변화가
            // MessageList를 재빌드하지 않게 격리. chatTop 따라 함께 이동.
            Positioned(
              left: 0,
              right: 0,
              top: chatTop - _momentCardLift,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Consumer(
                  builder: (context, ref, _) {
                    final moment = ref.watch(
                      characterMomentControllerProvider(widget.idolId),
                    );
                    return MomentCard(moment: moment);
                  },
                ),
              ),
            ),
            // Layer 4 (디버그 편집): 가구 편집 토글 버튼 — 디버그 + 아이돌 본인만.
            if (_canEdit)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                right: 8,
                child: FloatingActionButton.small(
                  heroTag: 'furniture-edit',
                  backgroundColor: _editMode
                      ? AppColors.primary
                      : AppColors.surface.withValues(alpha: 0.85),
                  onPressed: _editMode ? _saveFurnitureAndExit : _toggleEdit,
                  child: Icon(_editMode ? Icons.check : Icons.edit_outlined),
                ),
              ),
            // Layer 5 (디버그 편집): 선택 가구 크기 슬라이더 패널.
            if (_editMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _FurnitureEditPanel(
                  selected: _selectedFurniture,
                  visibility: _furnitureVisibility(),
                  onToggleVisible: _toggleFurnitureVisible,
                  onSizeChanged: _onFurnitureSizeChanged,
                  onBottomMarginChanged: _onFurnitureBottomMarginChanged,
                  onDistanceChanged: _onFurnitureDistanceChanged,
                  onCancel: _toggleEdit,
                  onSave: _saveFurnitureAndExit,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 디버그 가구 편집 패널 — 선택 가구 크기 슬라이더 + 저장/취소.
class _FurnitureEditPanel extends StatelessWidget {
  const _FurnitureEditPanel({
    required this.selected,
    required this.visibility,
    required this.onToggleVisible,
    required this.onSizeChanged,
    required this.onBottomMarginChanged,
    required this.onDistanceChanged,
    required this.onCancel,
    required this.onSave,
  });

  final FurnitureComponent? selected;
  final Map<FurnitureKind, bool> visibility;
  final ValueChanged<FurnitureKind> onToggleVisible;
  final ValueChanged<double> onSizeChanged;
  final ValueChanged<double> onBottomMarginChanged;
  final ValueChanged<double> onDistanceChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final f = selected;
    return Material(
      color: AppColors.surface.withValues(alpha: 0.95),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      f == null
                          ? '가구를 탭해서 선택 → 드래그 이동 / 슬라이더 조정'
                          : f.kind.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(onPressed: onCancel, child: const Text('취소')),
                  TextButton(onPressed: onSave, child: const Text('저장')),
                ],
              ),
              // 가구 넣기/빼기 — 켜진 칩 = 방에 배치됨.
              if (visibility.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: visibility.entries
                      .map(
                        (e) => FilterChip(
                          label: Text(e.key.name),
                          selected: e.value,
                          onSelected: (_) => onToggleVisible(e.key),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              if (f != null) ...[
                _EditSlider(
                  label: '크기',
                  value: f.targetWidth,
                  min: 40,
                  max: 360,
                  display: f.targetWidth.round().toString(),
                  onChanged: onSizeChanged,
                ),
                _EditSlider(
                  label: '앞뒤선',
                  value: f.bottomMargin,
                  min: 0,
                  max: 0.6,
                  display: f.bottomMargin.toStringAsFixed(2),
                  onChanged: onBottomMarginChanged,
                ),
                _EditSlider(
                  label: '상호작용',
                  value: f.interactionDistance,
                  min: 30,
                  max: 280,
                  display: f.interactionDistance.round().toString(),
                  onChanged: onDistanceChanged,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 편집 패널 슬라이더 1줄 (라벨 + Slider + 현재값).
class _EditSlider extends StatelessWidget {
  const _EditSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label, style: style)),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            value: value.clamp(min, max),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(display, style: style, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

/// 채팅 카드 top 위로 카드 본체가 띄워질 거리.
const double _momentCardLift = 56;

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.idolId,
    required this.isDragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onHandleTap,
  });

  final String idolId;
  final bool isDragging;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onHandleTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadius.xl),
        topRight: Radius.circular(AppRadius.xl),
      ),
      child: BackdropFilter(
        // 채팅창이 최저점 위로 올라온 경계 영역의 부드러운 전환을 위해 blur는 유지.
        filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // 극도로 투명 + blur — 뒤 방 배경/캐릭터가 거의 그대로 비침 (character.md v2 영역 1).
            color: AppColors.surface.withValues(alpha: 0.1),
            border: Border(
              top: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // 진짜 드래그 핸들 — onVerticalDrag + onTap.
              _DragHandle(
                isDragging: isDragging,
                onDragStart: onDragStart,
                onDragUpdate: onDragUpdate,
                onDragEnd: onDragEnd,
                onTap: onHandleTap,
              ),
              Expanded(child: MessageList(idolId: idolId)),
              // 입력란 배경을 화면 바닥(네브바/홈 인디케이터 영역 포함)까지 솔리드로 확장.
              // MessageInput 내부 SafeArea(bottom)를 removePadding으로 무력화하고,
              // 동일 inset을 직접 padding으로 줘 컨텐츠는 네브바 위, 배경은 바닥까지.
              ColoredBox(
                color: AppColors.surface,
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                    child: MessageInput(idolId: idolId),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.isDragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
  });

  final bool isDragging;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: onDragStart,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      onTap: onTap,
      child: SizedBox(
        height: 28,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isDragging ? 56 : 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDragging
                  ? AppColors.primary.withValues(alpha: 0.85)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
