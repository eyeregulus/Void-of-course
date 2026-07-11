import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:void_of_course/core/utils/timezone_provider.dart';
import 'package:void_of_course/core/utils/locale_provider.dart';
import 'package:void_of_course/core/astro/astro_state.dart';
import 'package:void_of_course/themes.dart';
import 'package:void_of_course/core/utils/app_analytics.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void showTimezoneSelectorDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const TimezoneSelectorDialog(),
  );
}

class TimezoneSelectorDialog extends StatefulWidget {
  const TimezoneSelectorDialog({super.key});

  @override
  State<TimezoneSelectorDialog> createState() => _TimezoneSelectorDialogState();
}

class _TimezoneSelectorDialogState extends State<TimezoneSelectorDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final timezoneProvider = Provider.of<TimezoneProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final languageCode = localeProvider.locale?.languageCode ?? 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 검색 필터링
    final filteredTimezones = TimezoneProvider.supportedTimezones.where((tz) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final displayName = tz.getDisplayName(languageCode).toLowerCase();
      final offset = tz.offsetDisplay.toLowerCase();
      return displayName.contains(query) || offset.contains(query);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E3A5F), const Color(0xFF16213E)]
                      : [const Color(0xFFF8F6F0), Colors.white],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    color: isDark ? Themes.gold : Themes.midnightBlue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      languageCode == 'ko' ? '타임존 선택' : 'Select Timezone',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Themes.gold : Themes.midnightBlue,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 검색창
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: languageCode == 'ko' ? '검색...' : 'Search...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Themes.gold : Themes.midnightBlue,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // 타임존 목록
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filteredTimezones.length,
                itemBuilder: (context, index) {
                  final tz = filteredTimezones[index];
                  final isSelected = tz.id == timezoneProvider.selectedTimezoneId;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final astro =
                            Provider.of<AstroState>(context, listen: false);

                        // Analytics 로깅
                        await AppAnalytics.logSelectTimezone(tz.id);

                        // 1. 타임존 설정
                        await timezoneProvider.setTimezone(tz.id);

                        // 2. 새 타임존 기준으로 데이터 재계산 (UI 및 SharedPreferences 캐시 갱신)
                        await astro.refreshData();

                        // 3. 실행 중인 백그라운드 서비스에 즉시 데이터 갱신을 알림
                        FlutterBackgroundService().invoke("refreshData");

                        // 4. 알람 재설정 로직 실행 (알람 끄기 및 사용자에게 경고)
                        await astro.updateVocAlarmForTimezone();

                        // 5. 대화 상자 닫기
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? Themes.gold.withValues(alpha: 0.15)
                                  : Themes.midnightBlue.withValues(alpha: 0.08))
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            // 체크 아이콘
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? (isDark ? Themes.gold : Themes.midnightBlue)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.05)),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 18,
                                      color: isDark ? Colors.black : Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            // 국기
                            Text(
                              tz.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            // 타임존 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tz.getDisplayName(languageCode),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isDark
                                          ? (isSelected
                                              ? Themes.gold
                                              : Colors.white)
                                          : (isSelected
                                              ? Themes.midnightBlue
                                              : Colors.black87),
                                    ),
                                  ),
                                  if (tz.offsetDisplay.isNotEmpty)
                                    Text(
                                      tz.offsetDisplay,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
