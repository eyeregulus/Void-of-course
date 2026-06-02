import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:void_of_course/l10n/app_localizations.dart';
import 'package:void_of_course/features/premium/widgets/premium_badge.dart';

import 'package:void_of_course/core/utils/app_analytics.dart';
import 'package:void_of_course/features/calendar/services/calendar_voc_cache.dart';
import 'package:void_of_course/core/utils/timezone_provider.dart';
import 'package:void_of_course/themes.dart';

DateTime _calendarDayKey(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Map<String, dynamic>>> _selectedEvents;

  final CalendarVocCache _vocCache = CalendarVocCache.instance;

  Map<DateTime, List<Map<String, dynamic>>> _rawVocEvents = {};
  Map<DateTime, List<Map<String, dynamic>>> _tzAdjustedEvents = {};
  Map<DateTime, Map<String, dynamic>> _vocSpans = {};

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isLoading = false;
  String? _error;
  String _lastTzId = '';
  bool _lastIsDst = false;
  int _fetchGeneration = 0;
  int? _lastAnalyticsMonthKey;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureMonthWindowLoaded(_focusedDay);
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tzProvider = Provider.of<TimezoneProvider>(context, listen: false);
    if (_lastTzId != tzProvider.selectedTimezoneId ||
        _lastIsDst != tzProvider.isDstApplied) {
      _lastTzId = tzProvider.selectedTimezoneId;
      _lastIsDst = tzProvider.isDstApplied;
      _applyTzAdjustedData(tzProvider);
      if (_selectedDay != null) {
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      }
    }
  }

  void _applyTzAdjustedData(TimezoneProvider tzProvider) {
    _tzAdjustedEvents.clear();
    _vocSpans.clear();

    final Set<Map<String, dynamic>> uniqueEvents = {};
    for (final eventsList in _rawVocEvents.values) {
      uniqueEvents.addAll(eventsList);
    }

    for (final voc in uniqueEvents) {
      final startUtc = voc['start'] as DateTime?;
      final endUtc = voc['end'] as DateTime?;
      if (startUtc == null || endUtc == null) continue;

      final tzStart = tzProvider.convert(startUtc);
      final tzEnd = tzProvider.convert(endUtc);

      var currentDay = _calendarDayKey(tzStart);
      final vocEndDay = _calendarDayKey(tzEnd);
      while (currentDay.isBefore(vocEndDay) ||
          currentDay.isAtSameMomentAs(vocEndDay)) {
        _tzAdjustedEvents.putIfAbsent(currentDay, () => []).add(voc);
        currentDay = currentDay.add(const Duration(days: 1));
      }
    }

    final sortedDates = _tzAdjustedEvents.keys.toList()..sort();
    for (final currentDate in sortedDates) {
      if (_vocSpans.containsKey(currentDate)) continue;

      final currentVoc = _tzAdjustedEvents[currentDate]?.first;
      if (currentVoc == null) continue;

      final startUtc = currentVoc['start'] as DateTime?;
      final endUtc = currentVoc['end'] as DateTime?;
      if (startUtc == null || endUtc == null) continue;

      final tzStart = tzProvider.convert(startUtc);
      final tzEnd = tzProvider.convert(endUtc);

      final vocStartDay = _calendarDayKey(tzStart);
      final vocEndDay = _calendarDayKey(tzEnd);

      final dayDifference = vocEndDay.difference(vocStartDay).inDays;
      final isMultiDay = dayDifference > 0;

      var checkDate = vocStartDay;
      while (checkDate.isBefore(vocEndDay) ||
          checkDate.isAtSameMomentAs(vocEndDay)) {
        _vocSpans[checkDate] = {
          'isMultiDay': isMultiDay,
          'spanStart': vocStartDay,
          'spanEnd': vocEndDay,
          'dayDifference': dayDifference,
          'isFirstDay': checkDate.isAtSameMomentAs(vocStartDay),
          'isLastDay': checkDate.isAtSameMomentAs(vocEndDay),
        };
        checkDate = checkDate.add(const Duration(days: 1));
      }
    }
  }

  void _mergeWindowIntoRawEvents(DateTime month) {
    _rawVocEvents = _vocCache.mergeWindow(month);
  }

  void _schedulePreload(DateTime month) {
    _vocCache.preloadAroundSilent(month, radius: 2);
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _tzAdjustedEvents[_calendarDayKey(day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
      final events = _getEventsForDay(selectedDay);
      AppAnalytics.logCalendarDaySelected(
        year: selectedDay.year,
        month: selectedDay.month,
        day: selectedDay.day,
        hasVoc: events.isNotEmpty,
      );
    }
  }

  void _onCalendarPageChanged(DateTime focusedDay) {
    final monthKey = focusedDay.year * 12 + focusedDay.month;
    if (_lastAnalyticsMonthKey != monthKey) {
      _lastAnalyticsMonthKey = monthKey;
      AppAnalytics.logCalendarMonthChanged(focusedDay.year, focusedDay.month);
    }
    setState(() => _focusedDay = focusedDay);
    _ensureMonthWindowLoaded(focusedDay);
  }

  Future<void> _ensureMonthWindowLoaded(DateTime month) async {
    if (_vocCache.isWindowCached(month)) {
      _mergeWindowIntoRawEvents(month);
      if (!mounted) return;
      final tzProvider = Provider.of<TimezoneProvider>(context, listen: false);
      _applyTzAdjustedData(tzProvider);
      if (_selectedDay != null) {
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      }
      if (mounted) setState(() {});
      _schedulePreload(month);
      return;
    }

    final generation = ++_fetchGeneration;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      await _vocCache.ensureWindowLoaded(month);
      if (!mounted || generation != _fetchGeneration) return;

      _mergeWindowIntoRawEvents(month);

      final tzProvider = Provider.of<TimezoneProvider>(context, listen: false);
      _applyTzAdjustedData(tzProvider);
      if (_selectedDay != null) {
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
      _schedulePreload(month);
    } catch (e, stack) {
      debugPrint('Calendar VOC load failed: $e\n$stack');
      if (!mounted || generation != _fetchGeneration) return;
      setState(() {
        _error = 'Failed to load VOC data.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tzProvider = Provider.of<TimezoneProvider>(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                appLocalizations.voidCalendar,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const PremiumBadge(),
            if (_isLoading) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: Column(
        children: [
          TableCalendar<Map<String, dynamic>>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2050, 12, 31),
            focusedDay: _focusedDay,
            locale: appLocalizations.localeName,
            pageAnimationEnabled: true,
            pageJumpingEnabled: false,
            daysOfWeekHeight: 24,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 13,
                height: 1.0,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
              ),
              weekendStyle: TextStyle(
                fontSize: 13,
                height: 1.0,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.redAccent
                        : Colors.red,
              ),
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: _onDaySelected,
            onPageChanged: _onCalendarPageChanged,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Themes.gold.withOpacity(0.3)
                        : Themes.midnightBlue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Themes.gold
                        : Themes.midnightBlue,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.redAccent
                        : Colors.red,
                shape: BoxShape.circle,
              ),
              markerSize: 6.0,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                fontSize: 18,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final isWeekend =
                    day.weekday == DateTime.saturday ||
                    day.weekday == DateTime.sunday;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final label = DateFormat.E(
                  appLocalizations.localeName,
                ).format(day);

                return Align(
                  alignment: const Alignment(0, -0.35),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.0,
                      color:
                          isWeekend
                              ? (isDark ? Colors.redAccent : Colors.red)
                              : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final vocSpan = _vocSpans[_calendarDayKey(day)];
                if (vocSpan == null || !vocSpan['isMultiDay']) {
                  return null;
                }

                final isFirstDay = vocSpan['isFirstDay'] as bool;
                final isLastDay = vocSpan['isLastDay'] as bool;
                final markerColor =
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.redAccent
                        : Colors.red;

                return Stack(
                  children: [
                    Align(
                      alignment: const Alignment(0, 0.8),
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(
                          left: isFirstDay ? 12.0 : 0.0,
                          right: isLastDay ? 12.0 : 0.0,
                        ),
                        decoration: BoxDecoration(
                          color: markerColor,
                          borderRadius: BorderRadius.horizontal(
                            left:
                                isFirstDay
                                    ? const Radius.circular(10)
                                    : Radius.zero,
                            right:
                                isLastDay
                                    ? const Radius.circular(10)
                                    : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        day.day.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child:
                _error != null
                    ? Center(child: Text(_error!))
                    : ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: _selectedEvents,
                      builder: (context, events, _) {
                        if (events.isEmpty) {
                          return Center(
                            child: Text(appLocalizations.noVocFound),
                          );
                        }
                        return ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            final vocStart = event['start'] as DateTime?;
                            final vocEnd = event['end'] as DateTime?;

                            if (vocStart == null || vocEnd == null) {
                              return ListTile(
                                title: Text(appLocalizations.invalidVocData),
                              );
                            }

                            final tzStart = tzProvider.convert(vocStart);
                            final tzEnd = tzProvider.convert(vocEnd);
                            final timeFormat = DateFormat('HH:mm');

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 4.0,
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.timer_off_outlined,
                                  color: Colors.red,
                                ),
                                title: const Text('Void of course'),
                                subtitle: Text(
                                  '${timeFormat.format(tzStart)} - ${timeFormat.format(tzEnd)}',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
