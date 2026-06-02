import 'dart:async';
import 'package:flutter/material.dart';
import 'package:void_of_course/themes.dart';

/// 배너 광고 영역(네비게이션 바 위)에서 올라왔다가, 같은 자리에서 아래로 내려가며 사라짐.
class AppSnackBar {
  static OverlayEntry? _entry;
  static Completer<void>? _dismissCompleter;
  static _SnackBarOverlayState? _activeState;

  static double _bottomInset(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    const navBarHeight = kBottomNavigationBarHeight;
    const bannerHeight = 45.0;
    return bottomSafe + navBarHeight + bannerHeight + 10;
  }

  static ({Color background, Color text}) _colorsForTheme(
    Brightness brightness,
  ) {
    if (brightness == Brightness.dark) {
      return (background: const Color(0xFFF0EDE5), text: Themes.midnightBlue);
    }
    return (background: const Color(0xFF1A1A2E), text: Colors.white);
  }

  static Future<void> show(
    BuildContext context, {
    required String message,
    // 스낵바가 화면에 '머무르는' 전체 시간입니다.
    Duration duration = const Duration(seconds: 2),
  }) async {
    if (!context.mounted) return;

    await dismiss();

    if (!context.mounted) return;

    final overlay = Overlay.of(context);
    final brightness = Theme.of(context).brightness;
    final colors = _colorsForTheme(brightness);
    final bottom = _bottomInset(context);

    _dismissCompleter = Completer<void>();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return _SnackBarOverlay(
          message: message,
          bottom: bottom,
          backgroundColor: colors.background,
          textColor: colors.text,
          displayDuration: duration, // 머무르는 시간을 넘겨줍니다.
          onRemove: () {
            if (_entry == entry) {
              _entry = null;
              _activeState = null;
            }
            entry.remove();
            if (_dismissCompleter != null && !_dismissCompleter!.isCompleted) {
              _dismissCompleter!.complete();
            }
          },
          onStateCreated: (state) => _activeState = state,
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);
    await _dismissCompleter!.future;
  }

  static Future<void> dismiss() async {
    final state = _activeState;
    if (state != null && state.mounted) {
      await state.dismissAnimated();
      return;
    }
    _entry?.remove();
    _entry = null;
    _activeState = null;
    if (_dismissCompleter != null && !_dismissCompleter!.isCompleted) {
      _dismissCompleter!.complete();
    }
  }
}

class _SnackBarOverlay extends StatefulWidget {
  final String message;
  final double bottom;
  final Color backgroundColor;
  final Color textColor;
  final Duration displayDuration; // 이름 변경: 화면 유지 시간
  final VoidCallback onRemove;
  final void Function(_SnackBarOverlayState state) onStateCreated;

  const _SnackBarOverlay({
    required this.message,
    required this.bottom,
    required this.backgroundColor,
    required this.textColor,
    required this.displayDuration,
    required this.onRemove,
    required this.onStateCreated,
  });

  @override
  State<_SnackBarOverlay> createState() => _SnackBarOverlayState();
}

class _SnackBarOverlayState extends State<_SnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    // [변경포인트 1] 나타나고 사라지는 애니메이션 자체의 속도를 250ms(0.25초)로 고정하여
    // 반응 속도를 대폭 끌어올렸습니다. 스르륵 열리는 맛은 유지하되 매우 빠릿해집니다.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // [변경포인트 2] 커브 조건을 변경하여 나타날 때는 끝이 부드러운 easeOut,
    // 사라질 때는 시작이 부드러운 easeIn 계열을 적용해 '스르륵 빠릿하게' 움직이도록 제어합니다.
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fade = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(curve);

    _runLifecycle();
  }

  Future<void> _runLifecycle() async {
    // 1. 0.25초 동안 빠르게 스르륵 올라옴
    await _controller.forward();
    if (!mounted) return;

    // 2. 사용자가 지정한 duration(기본 2초) 동안 화면에 머무름
    await Future.delayed(widget.displayDuration);
    if (!mounted) return;

    // 3. 다시 0.25초 동안 빠르게 스르륵 내려감
    await dismissAnimated();
  }

  Future<void> dismissAnimated() async {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    if (_controller.status == AnimationStatus.forward ||
        _controller.value > 0) {
      await _controller.reverse();
    }
    if (mounted) {
      widget.onRemove();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: widget.bottom,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: dismissAnimated,
              onVerticalDragUpdate: (details) {
                // 아래로 스와이프하면 닫히도록 설정
                if (details.primaryDelta! > 3) {
                  dismissAnimated();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: TextStyle(color: widget.textColor, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
