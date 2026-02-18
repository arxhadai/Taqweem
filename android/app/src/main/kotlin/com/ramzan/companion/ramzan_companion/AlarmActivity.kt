package com.ramzan.companion.ramzan_companion

import android.app.Activity
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.*
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.*

class AlarmActivity : Activity() {

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var handler = Handler(Looper.getMainLooper())
    private var volumeLevel = 0.1f

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Force full screen and show on lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        
        setContentView(R.layout.activity_alarm)

        val prayerName = intent.getStringExtra("prayer_name") ?: "Prayer"
        val soundPath = intent.getStringExtra("sound_path")
        val alarmId = intent.getIntExtra("alarm_id", 0)

        findViewById<TextView>(R.id.prayer_name_text).text = prayerName
        
        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        findViewById<TextView>(R.id.current_time_text).text = timeFormat.format(Date())

        setupButtons(prayerName, alarmId)
        startAlarm(soundPath)
    }

    private fun setupButtons(prayerName: String, alarmId: Int) {
        findViewById<Button>(R.id.stop_button).setOnClickListener {
            stopAlarm()
            finish()
        }

        findViewById<Button>(R.id.snooze_button).setOnClickListener {
            snoozeAlarm(prayerName, alarmId)
            stopAlarm()
            finish()
        }
    }

    private fun startAlarm(soundPath: String?) {
        // Start Vibration
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        val pattern = longArrayOf(0, 1000, 1000)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }

        // Start MediaPlayer
        try {
            mediaPlayer = MediaPlayer()
            val uri = if (soundPath != null && soundPath.startsWith("android.resource")) {
                Uri.parse(soundPath)
            } else if (soundPath != null && !soundPath.contains("default")) {
                Uri.parse(soundPath)
            } else {
                // Default fallback
                Uri.parse("android.resource://$packageName/raw/athan")
            }

            mediaPlayer?.apply {
                setDataSource(applicationContext, uri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                setVolume(volumeLevel, volumeLevel)
                prepare()
                start()
            }
            
            // Fade-in volume
            startFadeIn()

        } catch (e: Exception) {
            e.printStackTrace()
            // Final fallback to system alarm if adhan resource also fails
            try {
                mediaPlayer?.release()
                mediaPlayer = MediaPlayer.create(this, android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI)
                mediaPlayer?.isLooping = true
                mediaPlayer?.start()
            } catch (e2: Exception) {
                e2.printStackTrace()
            }
        }
    }

    private fun startFadeIn() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (volumeLevel < 1.0f) {
                    volumeLevel += 0.05f
                    mediaPlayer?.setVolume(volumeLevel, volumeLevel)
                    handler.postDelayed(this, 1000)
                }
            }
        }, 1000)
    }

    private fun snoozeAlarm(prayerName: String, alarmId: Int) {
        val snoozeTime = System.currentTimeMillis() + 5 * 60 * 1000
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("prayer_name", "$prayerName (Snoozed)")
            putExtra("alarm_id", alarmId + 10000) // Different ID for snooze
            // Reuse same sound path if original had one
            putExtra("sound_path", intent.getStringExtra("sound_path"))
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            alarmId + 10000,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, snoozeTime, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, snoozeTime, pendingIntent)
        }
    }

    private fun stopAlarm() {
        handler.removeCallbacksAndMessages(null)
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        vibrator?.cancel()
    }

    override fun onDestroy() {
        stopAlarm()
        super.onDestroy()
    }
}
