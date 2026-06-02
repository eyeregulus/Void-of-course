import 'dart:ui';



import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';



import 'package:void_of_course/core/astro/void_cycle_scheduler.dart';

import 'package:void_of_course/core/background/void_notification_delivery.dart';

import 'package:void_of_course/features/home/services/widget_service.dart';



const int preVoidAlarmId = 100;

const int vocStartAlarmId = 101;

const int vocMidAlarmId = 102;

const int vocEndAlarmId = 103;



class AlarmService {

  static final AlarmService _instance = AlarmService._internal();

  factory AlarmService() => _instance;

  AlarmService._internal();



  Future<void> init() async {

    await AndroidAlarmManager.initialize();

  }



  Future<void> schedulePreVoidAlarm(DateTime preVoidStart) async {

    final now = DateTime.now();

    if (preVoidStart.isBefore(now)) return;



    await AndroidAlarmManager.cancel(preVoidAlarmId);

    await AndroidAlarmManager.oneShotAt(

      preVoidStart,

      preVoidAlarmId,

      _preVoidAlarmCallback,

      exact: true,

      wakeup: true,

      allowWhileIdle: true,

      rescheduleOnReboot: true,

    );

  }



  Future<void> scheduleVocStartAlarm(DateTime vocStart) async {

    final now = DateTime.now();

    if (vocStart.isBefore(now)) return;



    await AndroidAlarmManager.cancel(vocStartAlarmId);

    await AndroidAlarmManager.oneShotAt(

      vocStart,

      vocStartAlarmId,

      _vocStartAlarmCallback,

      exact: true,

      wakeup: true,

      allowWhileIdle: true,

      rescheduleOnReboot: true,

    );

  }



  Future<void> scheduleVocMidAlarm(DateTime vocMid) async {

    final now = DateTime.now();

    if (vocMid.isBefore(now)) return;



    await AndroidAlarmManager.cancel(vocMidAlarmId);

    await AndroidAlarmManager.oneShotAt(

      vocMid,

      vocMidAlarmId,

      _vocMidAlarmCallback,

      exact: true,

      wakeup: true,

      allowWhileIdle: true,

      rescheduleOnReboot: true,

    );

  }



  Future<void> scheduleVocEndAlarm(DateTime vocEnd) async {

    final now = DateTime.now();

    if (vocEnd.isBefore(now)) return;



    await AndroidAlarmManager.cancel(vocEndAlarmId);

    await AndroidAlarmManager.oneShotAt(

      vocEnd,

      vocEndAlarmId,

      _vocEndAlarmCallback,

      exact: true,

      wakeup: true,

      allowWhileIdle: true,

      rescheduleOnReboot: true,

    );

  }



  Future<void> cancelAlarm() async {

    await Future.wait([

      AndroidAlarmManager.cancel(preVoidAlarmId),

      AndroidAlarmManager.cancel(vocStartAlarmId),

      AndroidAlarmManager.cancel(vocMidAlarmId),

      AndroidAlarmManager.cancel(vocEndAlarmId),

    ]);

  }

}



@pragma('vm:entry-point')

Future<void> _preVoidAlarmCallback() async {

  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  await prefs.reload();



  if (await WidgetService.isEnabled(prefs)) {

    await WidgetService.refreshFromPrefs();

  }



  if (!await VoidCycleScheduler.isVoidAlarmEnabled(prefs)) return;



  await VoidNotificationDelivery.showPreVoidStarted(prefs);

  await VoidCycleScheduler.tryStartCountdownService(prefs);

}



@pragma('vm:entry-point')

Future<void> _vocStartAlarmCallback() async {

  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  await prefs.reload();



  if (await WidgetService.isEnabled(prefs)) {

    await WidgetService.refreshFromPrefs();

  }



  if (!await VoidCycleScheduler.isVoidAlarmEnabled(prefs)) return;



  await VoidNotificationDelivery.showVocStarted(prefs);

  await VoidCycleScheduler.tryStartCountdownService(prefs);

}



@pragma('vm:entry-point')

Future<void> _vocMidAlarmCallback() async {

  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  await prefs.reload();



  if (await WidgetService.isEnabled(prefs)) {

    await WidgetService.refreshFromPrefs();

  }



  if (!await VoidCycleScheduler.isVoidAlarmEnabled(prefs)) return;



  await VoidNotificationDelivery.showCountdown(prefs);

  await VoidCycleScheduler.tryStartCountdownService(prefs);



  final vocEndString = prefs.getString('cached_voc_end');

  if (vocEndString == null) return;



  final vocEnd = DateTime.parse(vocEndString);

  final now = DateTime.now().toUtc();

  const maxInterval = Duration(hours: 12);

  final nextMidVoc = now.add(maxInterval);



  if (nextMidVoc.isBefore(vocEnd)) {

    await AndroidAlarmManager.oneShotAt(

      nextMidVoc,

      vocMidAlarmId,

      _vocMidAlarmCallback,

      exact: true,

      wakeup: true,

      allowWhileIdle: true,

      rescheduleOnReboot: true,

    );

  }

}



@pragma('vm:entry-point')

Future<void> _vocEndAlarmCallback() async {

  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  await prefs.reload();



  final endStr = prefs.getString('cached_voc_end');

  final endedAt = endStr != null ? DateTime.parse(endStr) : DateTime.now().toUtc();



  if (await WidgetService.isEnabled(prefs)) {

    await WidgetService.refreshFromPrefs(advanceAfterEnd: true);

  }



  if (await VoidCycleScheduler.isVoidAlarmEnabled(prefs)) {

    await VoidNotificationDelivery.showVocEnded(prefs);

    await VoidCycleScheduler.advanceAfterVocEnd(prefs, endedAt);

    await VoidCycleScheduler.stopCountdownService();

  } else if (await WidgetService.isEnabled(prefs)) {

    await VoidCycleScheduler.advanceAfterVocEnd(prefs, endedAt);

  }

}


