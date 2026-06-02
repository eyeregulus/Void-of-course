import 'package:flutter/material.dart';
import 'package:void_of_course/themes.dart';

class ResetDateButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ResetDateButton({super.key, required this.onPressed});

  @override
  State<ResetDateButton> createState() => _ResetDateButtonState();
}

class _ResetDateButtonState extends State<ResetDateButton> {
  bool _isPressed = false;


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;
    final buttonSize = isCompact ? 70.0 : 70.0;
    final iconSize = isCompact ? 45.0 : 45.0;

    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Themes.gold, const Color(0xFFB8960C)]
                    : [Themes.midnightBlue, const Color(0xFF1A252F)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Themes.gold : Themes.midnightBlue)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(buttonSize / 2),
                splashColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(
                    Icons.refresh_rounded,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
