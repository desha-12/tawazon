package com.example.tawazon

import android.Manifest
import android.app.AlarmManager
import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

object UsageAlertScheduler {
    const val ACTION_CHECK = "com.example.tawazon.CHECK_PHONE_USAGE"

    private const val PREFS = "tawazon_usage_alerts"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_THRESHOLD_MINUTES = "threshold_minutes"
    private const val KEY_LAST_ALERT_DAY = "last_alert_day"
    private const val CHANNEL_ID = "phone_usage_alerts"
    private const val NOTIFICATION_ID = 4204
    private const val REQUEST_CODE = 4204
    private const val DEFAULT_THRESHOLD_MINUTES = 240

    fun isEnabled(context: Context): Boolean =
        preferences(context).getBoolean(KEY_ENABLED, false)

    fun enable(context: Context, thresholdMinutes: Int): Boolean {
        if (!hasNotificationPermission(context) || !hasUsageAccess(context)) {
            return false
        }
        preferences(context).edit()
            .putBoolean(KEY_ENABLED, true)
            .putInt(KEY_THRESHOLD_MINUTES, thresholdMinutes.coerceAtLeast(1))
            .apply()
        createNotificationChannel(context)
        schedule(context)
        return true
    }

    fun disable(context: Context) {
        preferences(context).edit().putBoolean(KEY_ENABLED, false).apply()
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(alarmPendingIntent(context))
    }

    fun ensureScheduled(context: Context) {
        if (!isEnabled(context)) {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(alarmPendingIntent(context))
            return
        }
        // Keep an existing repeating alarm if a permission is temporarily
        // revoked; it can resume checking after the user grants it again.
        if (!hasNotificationPermission(context) || !hasUsageAccess(context)) return
        createNotificationChannel(context)
        if (existingAlarmPendingIntent(context) == null) schedule(context)
    }

    fun checkAndNotify(context: Context) {
        if (!isEnabled(context)) return
        if (!hasNotificationPermission(context) || !hasUsageAccess(context)) {
            ensureScheduled(context)
            return
        }

        val prefs = preferences(context)
        val thresholdMillis =
            prefs.getInt(KEY_THRESHOLD_MINUTES, DEFAULT_THRESHOLD_MINUTES) * 60_000L
        if (todayUsageMillis(context) < thresholdMillis) return

        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        if (prefs.getString(KEY_LAST_ALERT_DAY, null) == today) return

        try {
            postNotification(context)
            prefs.edit().putString(KEY_LAST_ALERT_DAY, today).apply()
        } catch (_: SecurityException) {
            // Permission could be revoked between the check and notify call.
        }
    }

    /**
     * Returns the last seven local calendar days of on-device screen usage.
     * No package names or usage details leave the device.
     */
    fun getUsageWeek(context: Context): List<Map<String, Any>>? {
        if (!hasUsageAccess(context)) return null

        val manager =
            context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_YEAR, -6)
        }

        return try {
            buildList {
                repeat(7) {
                    val dayStart = calendar.timeInMillis
                    val nextDay = (calendar.clone() as Calendar).apply {
                        add(Calendar.DAY_OF_YEAR, 1)
                    }.timeInMillis
                    val dayEnd = minOf(nextDay, now)
                    val totalMillis = if (dayEnd > dayStart) {
                        manager.queryUsageStats(
                            UsageStatsManager.INTERVAL_DAILY,
                            dayStart,
                            dayEnd,
                        ).orEmpty().sumOf { it.totalTimeInForeground }
                    } else {
                        0L
                    }
                    add(
                        mapOf<String, Any>(
                            "dayMillis" to dayStart,
                            "totalMillis" to totalMillis,
                        ),
                    )
                    calendar.add(Calendar.DAY_OF_YEAR, 1)
                }
            }
        } catch (_: SecurityException) {
            null
        }
    }

    private fun schedule(context: Context) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val firstCheck = System.currentTimeMillis() + AlarmManager.INTERVAL_FIFTEEN_MINUTES
        alarmManager.setInexactRepeating(
            AlarmManager.RTC_WAKEUP,
            firstCheck,
            AlarmManager.INTERVAL_FIFTEEN_MINUTES,
            alarmPendingIntent(context),
        )
    }

    private fun alarmPendingIntent(context: Context): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            alarmIntent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or immutablePendingIntentFlag(),
        )
    }

    private fun existingAlarmPendingIntent(context: Context): PendingIntent? =
        PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            alarmIntent(context),
            PendingIntent.FLAG_NO_CREATE or immutablePendingIntentFlag(),
        )

    private fun alarmIntent(context: Context) =
        Intent(context, UsageAlertReceiver::class.java).setAction(ACTION_CHECK)

    private fun immutablePendingIntentFlag(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun hasNotificationPermission(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    @Suppress("DEPRECATION")
    private fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        return try {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            ) == AppOpsManager.MODE_ALLOWED
        } catch (_: SecurityException) {
            false
        }
    }

    private fun todayUsageMillis(context: Context): Long {
        return try {
            val calendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val startOfDay = calendar.timeInMillis
            val now = System.currentTimeMillis()
            val usageStatsManager =
                context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            usageStatsManager
                .queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    startOfDay,
                    now,
                )
                .orEmpty()
                .sumOf { it.totalTimeInForeground }
        } catch (_: SecurityException) {
            0L
        }
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                if (Locale.getDefault().language == "ar") {
                    "تنبيهات استخدام الهاتف"
                } else {
                    "Phone usage alerts"
                },
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = if (Locale.getDefault().language == "ar") {
                    "تنبيه عند تجاوز وقت استخدام الهاتف اليومي"
                } else {
                    "A reminder when daily phone usage passes the limit"
                }
            },
        )
    }

    @Suppress("DEPRECATION")
    private fun postNotification(context: Context) {
        createNotificationChannel(context)
        val arabic = Locale.getDefault().language == "ar"
        val title = if (arabic) "وقت استراحة قصيرة؟" else "Time for a short break?"
        val body = if (arabic) {
            "استخدمت الهاتف ٤ ساعات أو أكثر اليوم. خذ استراحة قصيرة بعيدًا عن الشاشة."
        } else {
            "You have used your phone for 4 hours or more today. Consider a short screen break."
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or immutablePendingIntentFlag()
        val openApp = PendingIntent.getActivity(
            context,
            REQUEST_CODE,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            flags,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }
        val notification = builder
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(openApp)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_DEFAULT)
            .build()
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }
}

class UsageAlertReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED -> UsageAlertScheduler.ensureScheduled(context)
            UsageAlertScheduler.ACTION_CHECK ->
                UsageAlertScheduler.checkAndNotify(context)
        }
    }
}