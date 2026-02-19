package com.ramzan.companion.ramzan_companion

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra("prayer_name")
        val soundPath = intent.getStringExtra("sound_path")
        val alarmId = intent.getIntExtra("alarm_id", 0)

        Log.d("AlarmReceiver", "Alarm received for: $prayerName (ID: $alarmId, soundPath: $soundPath)")
        
        // Remove alarm from persistent storage when it fires
        AlarmStorage.removeAlarm(context, alarmId)
        Log.d("AlarmReceiver", "Removed alarm from persistent storage: id=$alarmId")

        // Intent to launch the AlarmActivity
        val fullScreenIntent = Intent(context, AlarmActivity::class.java).apply {
            putExtra("prayer_name", prayerName)
            putExtra("sound_path", soundPath)
            putExtra("alarm_id", alarmId)
            // Important flags for full screen intent activity
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            alarmId,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "adhan_alarm_channel"

        // Ensure channel exists
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // We use the same channel ID as the Flutter plugin to avoid duplicates if possible,
            // or ensure properties match.
            // The Flutter side creates 'adhan_alarm_channel' with importance MAX.
            if (notificationManager.getNotificationChannel(channelId) == null) {
                Log.d("AlarmReceiver", "Creating notification channel: $channelId")
                val channel = NotificationChannel(
                    channelId,
                    "Adhan Alarm",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Visual alerts for prayer times"
                    // The sound is played by the AlarmActivity, so notification itself is silent
                    setSound(null, null)
                    enableVibration(false)
                }
                notificationManager.createNotificationChannel(channel)
            }
        }

        // Build Notification
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        Log.d("AlarmReceiver", "Creating notification with fullScreenIntent for $prayerName")
        builder.setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Prayer Time: $prayerName")
            .setContentText("It is time for $prayerName prayer.")
            .setPriority(Notification.PRIORITY_MAX)
            .setCategory(Notification.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setAutoCancel(true)
            .setOngoing(true)
            // Fallback content intent if full screen doesn't launch (e.g. user using phone)
            .setContentIntent(fullScreenPendingIntent)

        Log.d("AlarmReceiver", "Showing notification with ID: $alarmId for $prayerName")
        notificationManager.notify(alarmId, builder.build())
        
        // Also launch the AlarmActivity directly as a backup (in case fullScreenIntent doesn't work on some devices)
        try {
            Log.d("AlarmReceiver", "Attempting to launch AlarmActivity directly as backup")
            context.startActivity(fullScreenIntent)
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "Failed to launch AlarmActivity directly: ${e.message}")
        }
    }
}
