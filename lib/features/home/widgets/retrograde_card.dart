import 'dart:ui';
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 수성 역행 카드
        _buildPlanetCard(
          context: context,
          planetSymbol: '☿',
          planetName: 'Mercury',
          isRetrograde: provider.mercuryRetrograde,
          startTime: _formatDateTime(provider.mercuryRetroStart, tzProvider),
          endTime: _formatDateTime(provider.mercuryRetroEnd, tzProvider),
          planetColor: const Color(0xFF9C27B0), // 수성: 보라색
          isDark: isDark,
          bodyColor: bodyColor,
          isCompact: isCompact,
          isKo: isKo,
        ),
        const SizedBox(height: 4),
        // 금성 역행 카드
        _buildPlanetCard(
          context: context,
          planetSymbol: '♀',
          planetName: 'Venus',
          isRetrograde: provider.venusRetrograde,
          startTime: _formatDateTime(provider.venusRetroStart, tzProvider),
          endTime: _formatDateTime(provider.venusRetroEnd, tzProvider),
          planetColor: const Color(0xFFE91E63), // 금성: 핑크/분홍색
          isDark: isDark,
          bodyColor: bodyColor,
          isCompact: isCompact,
          isKo: isKo,
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

    final statusBgColor =
        isRetrograde
            ? (isDark ? const Color(0xFF3D1F1F) : const Color(0xFFFFF0F0))
            : (isDark ? const Color(0xFF1F3D2A) : const Color(0xFFF0FFF4));

    final statusText =
        isRetrograde
            ? (isKo ? '현재 역행' : 'Retrograde')
            : (isKo ? '현재 순행' : 'Direct');

    final alignmentWidth = isCompact ? 66.0 : 82.0;
    // 세로 크기 축소를 위해 alignmentHeight를 별도로 더 작게 설정
    final alignmentHeight = isCompact ? 60.0 : 76.0;
    final circleSize = isCompact ? 46.0 : 56.0;
    final isMercury = planetSymbol == '☿';
    final symbolSize =
        isMercury ? (isCompact ? 26.0 : 34.0) : (isCompact ? 20.0 : 26.0);

    final titleSize = isCompact ? 15.0 : 17.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Themes.cardGradient(isDark),
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 상태 색상 악센트 글로우 (우상단 배치)
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
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
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12.0 : 16.0,
                vertical: isCompact ? 8.0 : 10.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 정렬용 외부 영역 (다른 카드들과 X축 라인을 완벽히 일치시키고 높이는 소형화)
                  SizedBox(
                    width: alignmentWidth,
                    height: alignmentHeight,
                    child: Center(
                      child: Container(
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
                    ),
                  ),
                  SizedBox(width: isCompact ? 12.0 : 16.0),

                  // 역행 세부 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          planetName,
                          style: TextStyle(
                            color: isDark ? Themes.gold : Themes.midnightBlue,
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(
                              alpha: isDark ? 0.25 : 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: isCompact ? 12.0 : 14.0,
                              fontWeight:
                                  FontWeight.w900, // 글로우 된 텍스트 볼드(w900)로 강조
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildTimeRow(
                          isKo ? '시작' : 'Start',
                          startTime,
                          bodyColor,
                          isCompact,
                        ),
                        const SizedBox(height: 1),
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
      fontSize: isCompact ? 14.0 : 16.0,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        SizedBox(
          width: isCompact ? 35.0 : 44.0,
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
