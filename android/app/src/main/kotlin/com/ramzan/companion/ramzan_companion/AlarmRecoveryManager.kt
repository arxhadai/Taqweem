package com.ramzan.companion.ramzan_companion

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * AlarmRecoveryManager handles restoration of alarms after system events.
 *
 * Triggered by:
 * - Device reboot (ACTION_BOOT_COMPLETED)
 * - System time change (ACTION_TIME_CHANGED)
 * - Timezone change (ACTION_TIMEZONE_CHANGED)
 * - App update (ACTION_MY_PACKAGE_REPLACED)
 * - App process restart
 *
 * Recovery strategy:
 * 1. Load all stored alarms from persistent storage
 * 2. Filter out stale alarms (> 24 hours in the past)
 * 3. Reschedule remaining future alarms using existing IDs
 * 4. Log recovery metrics for debugging
 */
object AlarmRecoveryManager {
    private const val TAG = "AlarmRecoveryManager"
    private const val STALE_THRESHOLD_MS = 24 * 60 * 60 * 1000L // 24 hours in milliseconds

    /**
     * Recover and reschedule stored alarms after system events.
     *
     * This is the main entry point called from BootReceiver when system events occur.
     *
     * @param context Application context
     */
    fun recoverAlarms(context: Context) {
        try {
            val startTime = System.currentTimeMillis()
            Log.d(TAG, "Starting alarm recovery...")

            // Get all stored alarms
            val storedAlarms = AlarmStorage.getAllAlarms(context)
            Log.d(TAG, "Loaded ${storedAlarms.size} alarms from persistent storage")

            if (storedAlarms.isEmpty()) {
                Log.d(TAG, "No stored alarms to recover")
                return
            }

            var rescheduledCount = 0
            var staleCount = 0
            val currentTime = System.currentTimeMillis()

            // Process each stored alarm
            for (alarm in storedAlarms) {
                val timeDifference = currentTime - alarm.triggerTime

                // Check if alarm is stale (more than 24 hours in the past)
                if (timeDifference > STALE_THRESHOLD_MS) {
                    Log.d(
                        TAG,
                        "Removing stale alarm: id=${alarm.alarmId}, prayer=${alarm.prayerName}, " +
                        "was ${timeDifference / 1000 / 60 / 60} hours ago"
                    )
                    AlarmStorage.removeAlarm(context, alarm.alarmId)
                    staleCount++
                    continue
                }

                // Check if alarm is in the past but within tolerance (< 24 hours)
                if (alarm.triggerTime < currentTime) {
                    Log.d(
                        TAG,
                        "Skipping past alarm (within 24h): id=${alarm.alarmId}, " +
                        "prayer=${alarm.prayerName}, was ${timeDifference / 1000 / 60} minutes ago"
                    )
                    // Keep the alarm in storage but don't reschedule
                    // It will fire naturally or be handled by the system
                    continue
                }

                // Alarm is in the future - reschedule it
                rescheduleAlarm(context, alarm)
                rescheduledCount++
            }

            val elapsedTime = System.currentTimeMillis() - startTime
            Log.d(
                TAG,
                "Alarm recovery complete. " +
                "Rescheduled: $rescheduledCount, Removed stale: $staleCount, " +
                "Total processed: ${storedAlarms.size}, Time: ${elapsedTime}ms"
            )

        } catch (e: Exception) {
            Log.e(TAG, "Error during alarm recovery: ${e.message}", e)
        }
    }

    /**
     * Reschedule a single alarm using its stored metadata and original ID.
     *
     * This method reuses the existing native alarm scheduling logic without
     * generating a new ID, ensuring that alarms maintain their identity
     * across recovery events.
     *
     * @param context Application context
     * @param alarm The stored alarm to reschedule
     */
    private fun rescheduleAlarm(context: Context, alarm: StoredAlarm) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            // Create intent with stored metadata
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra("prayer_name", alarm.prayerName)
                putExtra("alarm_id", alarm.alarmId)
                // Note: soundPath is not stored, so it will be null
                // This is acceptable as a fallback; ideally soundPath should be added to StoredAlarm
            }

            // Create PendingIntent with original alarm ID as requestCode
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarm.alarmId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Check exact alarm permission (Android 12+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (!alarmManager.canScheduleExactAlarms()) {
                    Log.w(
                        TAG,
                        "Cannot reschedule exact alarms - permission not granted. " +
                        "Falling back to setAndAllowWhileIdle for alarm id=${alarm.alarmId}"
                    )
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        alarm.triggerTime,
                        pendingIntent
                    )
                    Log.d(TAG, "Rescheduled (inexact) alarm: id=${alarm.alarmId}, prayer=${alarm.prayerName}")
                    return
                }
            }

            // Use setAlarmClock for exact timing with Doze exemption
            val showIntent = PendingIntent.getActivity(
                context,
                alarm.alarmId,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(alarm.triggerTime, showIntent),
                pendingIntent
            )

            Log.d(
                TAG,
                "Rescheduled alarm: id=${alarm.alarmId}, prayer=${alarm.prayerName}, " +
                "type=${alarm.alarmType}, triggerTime=${alarm.triggerTime} (dayOffset=${alarm.dayOffset})"
            )

        } catch (e: Exception) {
            Log.e(TAG, "Error rescheduling alarm id=${alarm.alarmId}: ${e.message}", e)
        }
    }
}
