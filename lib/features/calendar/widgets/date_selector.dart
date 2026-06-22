import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:void_of_course/themes.dart';

class DateSelector extends StatefulWidget {
  final TextEditingController dateController;
  final VoidCallback showCalendar;
  final VoidCallback onNextDay;
  final VoidCallback onPreviousDay;
  final VoidCallback onResetToToday;
  final DateTime selectedDate;
  final bool isRetrogradeCardVisible;

  const DateSelector({
    super.key,
    required this.dateController,
    required this.showCalendar,
    required this.onNextDay,
    required this.onPreviousDay,
    required this.onResetToToday,
    required this.selectedDate,
    required this.isRetrogradeCardVisible,
  });

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  bool _isPrevPressed = false;
  bool _isNextPressed = false;
  bool _isResetPressed = false;

  bool get _isToday {
    final now = DateTime.now();
    return widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    final showResetButton = widget.isRetrogradeCardVisible;

    // 수성/금성이 보일 때는 가로 공간 확보를 위해 버튼 크기를 살짝 줄이고, 여백을 줄임
    // 수성/금성이 꺼져 있을 때는 원래 크기로 돌려줌
    final navSize =
        showResetButton ? (isCompact ? 54.0 : 60.0) : (isCompact ? 60.0 : 60.0);
    final navIconSize =
        showResetButton ? (isCompact ? 32.0 : 38.0) : (isCompact ? 38.0 : 50.0);
    final dateSize = isCompact ? 15.0 : 17.0;
    final calIconSize =
        showResetButton ? (isCompact ? 15.0 : 17.0) : (isCompact ? 16.0 : 18.0);
    final containerPadding = isCompact ? 10.0 : 12.0;

    // 외각 상하 여백
    // 수성/금성이 보일 때는 극단적으로 압축(3.0), 꺼져 있을 때는 원래 크기(containerPadding)
    final verticalPadding = showResetButton ? 3.0 : containerPadding;

    // 날짜 박스 상하 여백
    // 수성/금성이 보일 때는 18.0 : 20.0, 꺼져 있을 때는 원래 크기(20.0 : 20.0)
    final middleVerticalPadding =
        showResetButton ? (isCompact ? 18.0 : 20.0) : (isCompact ? 20.0 : 20.0);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: containerPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Themes.cardGradient(isDark),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [Themes.cardShadow(isDark)],
      ),
      child: Row(
        children: [
          // 이전 날짜 버튼
          _buildNavButton(
            context,
            Icons.chevron_left_rounded,
            widget.onPreviousDay,
            isDark,
            isPrev: true,
            buttonSize: navSize,
            iconSize: navIconSize,
          ),
          const SizedBox(width: 6),
          // 날짜 표시 영역
          Expanded(
            child: GestureDetector(
              onTap: widget.showCalendar,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: middleVerticalPadding,
                  horizontal: 1,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: calIconSize,
                      color:
                          _isToday
                              ? Themes.gold
                              : (isDark ? Themes.gold : Themes.midnightBlue),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.dateController.text,
                          style: TextStyle(
                            color:
                                _isToday
                                    ? Themes.gold
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                            fontSize: dateSize,
                            fontWeight:
                                _isToday ? FontWeight.w700 : FontWeight.w600,
                            letterSpacing: 1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // 다음 날짜 버튼
          _buildNavButton(
            context,
            Icons.chevron_right_rounded,
            widget.onNextDay,
            isDark,
            isPrev: false,
            buttonSize: navSize,
            iconSize: navIconSize,
          ),
          if (showResetButton) ...[
            const SizedBox(width: 6),
            // 오늘로 이동 (새로고침/리셋) 버튼
            _buildResetButton(context, isDark, navSize, navIconSize),
          ],
        ],
      ),
    );
  }

  Widget _buildResetButton(
    BuildContext context,
    bool isDark,
    double buttonSize,
    double iconSize,
  ) {
    final active = !_isToday;
    final isPressed = _isResetPressed;

    return Opacity(
      opacity: active ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !active,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isResetPressed = true),
          onTapUp: (_) => setState(() => _isResetPressed = false),
          onTapCancel: () => setState(() => _isResetPressed = false),
          child: AnimatedScale(
            scale: isPressed ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color:
                    active
                        ? (isDark
                            ? Themes.gold.withValues(alpha: 0.1)
                            : Themes.midnightBlue.withValues(alpha: 0.05))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.02)),
                borderRadius: BorderRadius.circular(12),
                border:
                    active
                        ? Border.all(
                          color: isDark ? Themes.gold : Themes.midnightBlue,
                          width: 1.5,
                        )
                        : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onResetToToday,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: (isDark ? Themes.gold : Themes.midnightBlue)
                      .withValues(alpha: 0.3),
                  child: Center(
                    child: Icon(
                      Icons.refresh_rounded,
                      size: iconSize * 0.85,
                      color:
                          active
                              ? (isDark ? Themes.gold : Themes.midnightBlue)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    bool isDark, {
    required bool isPrev,
    required double buttonSize,
    required double iconSize,
  }) {
    final isPressed = isPrev ? _isPrevPressed : _isNextPressed;

    return GestureDetector(
      onTapDown:
          (_) => setState(() {
            if (isPrev) {
              _isPrevPressed = true;
            } else {
              _isNextPressed = true;
            }
          }),
      onTapUp:
          (_) => setState(() {
            if (isPrev) {
              _isPrevPressed = false;
            } else {
              _isNextPressed = false;
            }
          }),
      child: AnimatedScale(
        scale: isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: (isDark ? Themes.gold : Themes.midnightBlue)
                .withValues(alpha: 0.3),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: isDark ? Themes.gold : Themes.midnightBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
