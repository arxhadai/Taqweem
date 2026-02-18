package com.ramzan.companion.ramzan_companion

import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ramzan.companion/nature_sound"
    private val PREMIUM_ALARM_CHANNEL = "premium_alarm_channel"
    private var ringtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Existing Nature Sound Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playSystemSound" -> {
                    val type = call.argument<String>("type")
                    playSystemSound(type)
                    result.success(null)
                }
                "stopSystemSound" -> {
                    stopSystemSound()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // New Premium Alarm Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PREMIUM_ALARM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val id = call.argument<Int>("alarmId") ?: 0
                    val timeInMillis = call.argument<Long>("timeInMillis") ?: 0L
                    val prayerName = call.argument<String>("prayerName") ?: ""
                    val soundPath = call.argument<String>("soundPath")
                    
                    scheduleNativeAlarm(id, timeInMillis, prayerName, soundPath)
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("alarmId") ?: 0
                    cancelNativeAlarm(id)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleNativeAlarm(id: Int, timeInMillis: Long, prayerName: String, soundPath: String?) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val intent = android.content.Intent(this, AlarmReceiver::class.java).apply {
            putExtra("prayer_name", prayerName)
            putExtra("sound_path", soundPath)
            putExtra("alarm_id", id)
        }

        val pendingIntent = android.app.PendingIntent.getBroadcast(
            this,
            id,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                android.app.AlarmManager.RTC_WAKEUP,
                timeInMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                android.app.AlarmManager.RTC_WAKEUP,
                timeInMillis,
                pendingIntent
            )
        }
    }

    private fun cancelNativeAlarm(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val intent = android.content.Intent(this, AlarmReceiver::class.java)
        val pendingIntent = android.app.PendingIntent.getBroadcast(
            this,
            id,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    private fun playSystemSound(type: String?) {
        stopSystemSound()
        val uri: Uri = when (type) {
            "alarm" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            "ringtone" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            "notification" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        }
        try {
            ringtone = RingtoneManager.getRingtone(applicationContext, uri)
            ringtone?.play()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopSystemSound() {
        ringtone?.stop()
        ringtone = null
    }

    override fun onDestroy() {
        stopSystemSound()
        super.onDestroy()
    }
}
