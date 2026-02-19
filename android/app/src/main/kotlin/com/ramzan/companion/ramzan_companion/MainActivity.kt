package com.ramzan.companion.ramzan_companion

import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
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
                "checkExactAlarmPermission" -> {
                    result.success(checkExactAlarmPermission())
                }
                "requestBatteryOptimization" -> {
                    requestBatteryOptimization()
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

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                Log.e("MainActivity", "ERROR: Cannot schedule exact alarms - SCHEDULE_EXACT_ALARM permission not granted or disabled")
                try {
                    val settingsIntent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(settingsIntent)
                } catch (e: Exception) {
                    Log.e("MainActivity", "Failed to open exact alarm settings: ${e.message}")
                    e.printStackTrace()
                }
                return
            }
        }

        // Use setAlarmClock for maximum reliability - exempt from Doze, shows alarm icon in status bar
        val showIntent = android.app.PendingIntent.getActivity(
            this,
            id,
            Intent(this, MainActivity::class.java),
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        
        Log.d("MainActivity", "Scheduling alarm: prayerName=$prayerName, id=$id, timeInMillis=$timeInMillis, soundPath=$soundPath")
        alarmManager.setAlarmClock(
            android.app.AlarmManager.AlarmClockInfo(timeInMillis, showIntent),
            pendingIntent
        )
        Log.d("MainActivity", "Successfully called setAlarmClock for $prayerName")
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

    private fun checkExactAlarmPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            return alarmManager.canScheduleExactAlarms()
        }
        return true // Pre-S always has permission
    }

    private fun requestBatteryOptimization() {
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
