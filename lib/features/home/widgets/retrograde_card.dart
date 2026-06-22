import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:void_of_course/core/astro/astro_state.dart';
import 'package:void_of_course/core/utils/timezone_provider.dart';
import 'package:void_of_course/themes.dart';

class RetrogradeCard extends StatelessWidget {
  final AstroState provider;

  const RetrogradeCard({super.key, required this.provider});

  static final _dateFormat = DateFormat('MM/dd HH:mm');

  String _formatDateTime(DateTime? dateTime, TimezoneProvider tzProvider) {
    if (dateTime == null) return 'N/A';
    return _dateFormat.format(tzProvider.convert(dateTime));
  }

  @override
  Widget build(BuildContext context) {
    final tzProvider = Provider.of<TimezoneProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = theme.textTheme.bodyLarge?.color;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    final locale = Localizations.localeOf(context).languageCode;
    final isKo = locale == 'ko';

    return Row(
      children: [
        // 수성 역행 카드
        Expanded(
          child: _buildPlanetCard(
            context: context,
            planetSymbol: '☿',
            planetName: isKo ? '수성' : 'Mercury',
            isRetrograde: provider.mercuryRetrograde,
            startTime: _formatDateTime(provider.mercuryRetroStart, tzProvider),
            endTime: _formatDateTime(provider.mercuryRetroEnd, tzProvider),
            planetColor: const Color(0xFF9C27B0), // 수성: 보라색
            isDark: isDark,
            bodyColor: bodyColor,
            isCompact: isCompact,
            isKo: isKo,
          ),
        ),
        const SizedBox(width: 4),
        // 금성 역행 카드
        Expanded(
          child: _buildPlanetCard(
            context: context,
            planetSymbol: '♀',
            planetName: isKo ? '금성' : 'Venus',
            isRetrograde: provider.venusRetrograde,
            startTime: _formatDateTime(provider.venusRetroStart, tzProvider),
            endTime: _formatDateTime(provider.venusRetroEnd, tzProvider),
            planetColor: const Color(0xFFE91E63), // 금성: 핑크/분홍색
            isDark: isDark,
            bodyColor: bodyColor,
            isCompact: isCompact,
            isKo: isKo,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanetCard({
    required BuildContext context,
    required String planetSymbol,
    required String planetName,
    required bool isRetrograde,
    required String startTime,
    required String endTime,
    required Color planetColor,
    required bool isDark,
    required Color? bodyColor,
    required bool isCompact,
    required bool isKo,
  }) {
    final statusColor =
        isRetrograde
            ? const Color(0xFFE53935) // 역행: 빨간색
            : const Color(0xFF4CAF50); // 순행: 초록색

    final statusText =
        isRetrograde ? (isKo ? '역행' : 'Retrograde') : (isKo ? '순행' : 'Direct');

    final circleSize = isCompact ? 36.0 : 42.0;
    final isMercury = planetSymbol == '☿';
    final symbolSize =
        isMercury ? (isCompact ? 22.0 : 26.0) : (isCompact ? 16.0 : 20.0);

    final titleSize = isCompact ? 14.0 : 16.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Themes.cardGradient(isDark),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 상태 색상 악센트 글로우 (우상단 배치)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      statusColor.withValues(alpha: isDark ? 0.2 : 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isCompact ? 10.0 : 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment.center,
                            colors:
                                isDark
                                    ? [
                                      planetColor.withValues(alpha: 0.35),
                                      const Color(0xFF1E3A5F),
                                    ]
                                    : [
                                      planetColor.withValues(alpha: 0.15),
                                      const Color(0xFFF0EDE5),
                                    ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            planetSymbol,
                            style: TextStyle(
                              fontSize: symbolSize,
                              color: planetColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              planetName,
                              style: TextStyle(
                                color:
                                    isDark ? Themes.gold : Themes.midnightBlue,
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(
                                  alpha: isDark ? 0.25 : 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: isCompact ? 10.0 : 12.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTimeRow(
                    isKo ? '시작' : 'Start',
                    startTime,
                    bodyColor,
                    isCompact,
                  ),
                  const SizedBox(height: 2),
                  _buildTimeRow(
                    isKo ? '종료' : 'End',
                    endTime,
                    bodyColor,
                    isCompact,
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
    Color? bodyColor,
    bool isCompact,
  ) {
    final textStyle = TextStyle(
      color: bodyColor,
      fontSize: isCompact ? 11.0 : 13.0,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        SizedBox(
          width:
              label == '시작' || label == '종료'
                  ? (isCompact ? 22.0 : 26.0)
                  : (isCompact ? 38.0 : 46.0),
          child: Text(
            label,
            style: textStyle,
            maxLines: 1,
            softWrap: false,
          ),
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
