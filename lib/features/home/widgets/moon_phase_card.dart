import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:void_of_course/core/astro/astro_state.dart';
import 'package:void_of_course/core/astro/astro_calculator.dart';
import 'package:void_of_course/core/utils/timezone_provider.dart';
import 'package:void_of_course/themes.dart';

class MoonPhaseCard extends StatelessWidget {
  final AstroState provider;

  const MoonPhaseCard({super.key, required this.provider});

  static final _dateFormat = DateFormat('MM/dd HH:mm');
  static final _calculator = AstroCalculator();

  @override
  Widget build(BuildContext context) {
    final tzProvider = Provider.of<TimezoneProvider>(context);
    final phaseStartTime =
        provider.moonPhaseStartTime != null
            ? tzProvider.convert(provider.moonPhaseStartTime!)
            : null;
    final phaseEndTime =
        provider.moonPhaseEndTime != null
            ? tzProvider.convert(provider.moonPhaseEndTime!)
            : null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = theme.textTheme.bodyLarge?.color;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;
    final iconSize = isCompact ? 66.0 : 82.0;
    final emojiSize = isCompact ? 48.0 : 60.0;
    final cardPadding = isCompact ? 10.0 : 12.0;
    final iconGap = isCompact ? 12.0 : 16.0;
    final titleSize = isCompact ? 15.0 : 17.0;
    final phaseNameSize = isCompact ? 16.0 : 18.0;

    final locale = Localizations.localeOf(context).languageCode;
    final isKo = locale == 'ko';

    String getPhaseName(String phase) {
      final clean = _calculator.getMoonPhaseNameOnly(phase).trim();
      if (!isKo) return clean;
      switch (clean) {
        case 'New Moon':
          return 'New Moon (신월)';
        case 'Crescent Moon':
          return 'Crescent Moon (크레센트)';
        case 'First Quarter':
          return 'First Quarter (퍼스트쿼터)';
        case 'Gibbous Moon':
          return 'Gibbous Moon (지보스문)';
        case 'Full Moon':
          return 'Full Moon (풀문)';
        case 'Disseminating Moon':
          return 'Disseminating Moon (디세미네이팅 문)';
        case 'Last Quarter':
          return 'Last Quarter (라스트쿼터)';
        case 'Balsamic Moon':
          return 'Balsamic Moon (발사믹)';
        default:
          return clean;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Themes.cardGradient(isDark),
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [Themes.cardShadow(isDark)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 미세한 장식 원 (달빛 효과)
            if (isDark)
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Themes.gold.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                children: [
                  // 달 이모지 영역
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(0.0, -0.3),
                        colors:
                            isDark
                                ? [
                                  const Color(0xFF2A4A6E),
                                  const Color(0xFF1E3A5F),
                                ]
                                : [
                                  const Color(0xFFF0EDE5),
                                  const Color.fromARGB(255, 243, 242, 241),
                                ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _calculator.getMoonPhaseEmoji(provider.moonPhase),
                        style: TextStyle(fontSize: emojiSize),
                      ),
                    ),
                  ),
                  SizedBox(width: iconGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Moon Phase',
                          style: TextStyle(
                            color: isDark ? Themes.gold : Themes.midnightBlue,
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          getPhaseName(provider.moonPhase),
                          style: TextStyle(
                            color: theme.textTheme.titleLarge?.color,
                            fontSize: phaseNameSize,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          isKo ? '시작' : 'Start',
                          phaseStartTime != null
                              ? _dateFormat.format(phaseStartTime)
                              : 'N/A',
                          isDark,
                          bodyColor,
                          isCompact,
                        ),
                        const SizedBox(height: 1),
                        _buildTimeRow(
                          isKo ? '종료' : 'End',
                          phaseEndTime != null
                              ? _dateFormat.format(phaseEndTime)
                              : 'N/A',
                          isDark,
                          bodyColor,
                          isCompact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(
    String label,
    String time,
    bool isDark,
    Color? bodyColor,
    bool isCompact,
  ) {
    final textStyle = TextStyle(
      color: bodyColor,
      fontSize: isCompact ? 14.0 : 16.0,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        SizedBox(
          width: label == '시작' || label == '종료'
              ? (isCompact ? 28.0 : 32.0)
              : (isCompact ? 35.0 : 44.0),
          child: Text(label, style: textStyle),
        ),
        Text(' : ', style: textStyle),
        Expanded(
          child: Text(
            time,
            style: textStyle.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
