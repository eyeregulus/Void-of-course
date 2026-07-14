package com.example.lioluna

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class VocWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "VocWidgetProvider"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val WIDGET_INSTALLED_KEY = "flutter.hasHomeWidgetInstalled"
    }

    private fun markWidgetInstalled(context: Context) {
        context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(WIDGET_INSTALLED_KEY, true)
            .apply()
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        markWidgetInstalled(context)
    }

    private fun getLongSafe(prefs: SharedPreferences, key: String, defValue: Long): Long {
        val value = prefs.all[key] ?: return defValue
        return when (value) {
            is Number -> value.toLong()
            is String -> value.toLongOrNull() ?: defValue
            else -> defValue
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        markWidgetInstalled(context)

        val now = System.currentTimeMillis()

        // Read timestamps saved from Dart
        val currentStart = getLongSafe(widgetData, "current_voc_start_ms", 0L)
        val currentEnd = getLongSafe(widgetData, "current_voc_end_ms", 0L)
        val nextStart = getLongSafe(widgetData, "next_voc_start_ms", 0L)
        val nextEnd = getLongSafe(widgetData, "next_voc_end_ms", 0L)
        val moonZodiac = widgetData.getString("moon_zodiac", "") ?: ""

        var activeStartMs = currentStart
        var activeEndMs = currentEnd
        var startText = widgetData.getString("current_voc_start_text", "N/A") ?: "N/A"
        var endText = widgetData.getString("current_voc_end_text", "N/A") ?: "N/A"

        // If the current period is already over, roll over to the next one
        if (currentEnd != 0L && now >= currentEnd) {
            if (nextStart != 0L && nextEnd != 0L) {
                activeStartMs = nextStart
                activeEndMs = nextEnd
                startText = widgetData.getString("next_voc_start_text", "N/A") ?: "N/A"
                endText = widgetData.getString("next_voc_end_text", "N/A") ?: "N/A"
            }
        }

        // 🚫 Void active, 🔔 Starting today, ✅ Safe
        val isVocNow = activeStartMs != 0L && activeEndMs != 0L && now >= activeStartMs && now < activeEndMs
        
        var isVocToday = false
        if (!isVocNow && activeStartMs != 0L && activeStartMs > now) {
            val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val timezoneId = flutterPrefs.getString("flutter.selected_timezone", "Asia/Seoul") ?: "Asia/Seoul"
            val zone = java.util.TimeZone.getTimeZone(timezoneId)
            val calNow = java.util.Calendar.getInstance(zone)
            calNow.timeInMillis = now
            val calStart = java.util.Calendar.getInstance(zone)
            calStart.timeInMillis = activeStartMs
            isVocToday = calNow.get(java.util.Calendar.YEAR) == calStart.get(java.util.Calendar.YEAR) &&
                    calNow.get(java.util.Calendar.DAY_OF_YEAR) == calStart.get(java.util.Calendar.DAY_OF_YEAR)
        }

        val icon = if (isVocNow) "🚫" else if (isVocToday) "🔔" else "✅"
        val titleText = "🌙 Void of course" + (if (moonZodiac.isNotEmpty()) "  $moonZodiac" else "")
        val timesText = "Start : $startText\nEnd   : $endText"

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.voc_widget).apply {
                setTextViewText(R.id.widget_icon_text, icon)
                setTextViewText(R.id.widget_title_text, titleText)
                setTextViewText(R.id.widget_times_text, timesText)

                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)

            // Schedule alarms for transitions natively (completely battery safe, no Dart wakeup)
            scheduleTransitionAlarms(context, appWidgetId, now, activeStartMs, activeEndMs)
        }
    }

    private fun scheduleTransitionAlarms(
        context: Context,
        appWidgetId: Int,
        now: Long,
        startMs: Long,
        endMs: Long
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // Intent to trigger self-update
        val intent = Intent(context, VocWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        }

        // Schedule at start of void
        if (startMs > now) {
            val pendingStart = PendingIntent.getBroadcast(
                context,
                appWidgetId * 10 + 1,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            scheduleAlarmCompat(alarmManager, startMs, pendingStart)
        }

        // Schedule at end of void
        if (endMs > now) {
            val pendingEnd = PendingIntent.getBroadcast(
                context,
                appWidgetId * 10 + 2,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            scheduleAlarmCompat(alarmManager, endMs, pendingEnd)
        }
    }

    private fun scheduleAlarmCompat(
        alarmManager: AlarmManager,
        timeMs: Long,
        pendingIntent: PendingIntent
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
            }
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, timeMs, pendingIntent)
        }
    }
}
