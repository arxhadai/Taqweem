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
import android.util.Log
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
    private var wakeLock: PowerManager.WakeLock? = null
    private var isReleased = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Phase C: Acquire WakeLock to prevent sleep during alarm handling
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "AlarmActivity:alarmWakeLock"
        ).apply {
            acquire(10 * 60 * 1000L)  // 10 minute timeout
            Log.d("AlarmActivity", "WakeLock acquired in onCreate")
        }

        // Force full screen and show on lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        }

        // Phase C: Additional window flags for fullscreen reliability
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )
        
        setContentView(R.layout.activity_alarm)

        val prayerName = intent.getStringExtra("prayer_name") ?: "Prayer"
        val soundPath = intent.getStringExtra("sound_path")
        val alarmId = intent.getIntExtra("alarm_id", 0)

        findViewById<TextView>(R.id.prayer_name_text).text = prayerName
        
        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        findViewById<TextView>(R.id.current_time_text).text = timeFormat.format(Date())

        setupButtons(prayerName, alarmId)
        startAlarm(soundPath)
        
        Log.d("AlarmActivity", "AlarmActivity created for: $prayerName (ID: $alarmId)")
    }

    private fun setupButtons(prayerName: String, alarmId: Int) {
        findViewById<Button>(R.id.stop_button).setOnClickListener {
            Log.d("AlarmActivity", "Stop button pressed for alarm id=$alarmId")
            stopAlarm()
            releaseWakeLock()
            finish()
        }

        findViewById<Button>(R.id.snooze_button).setOnClickListener {
            Log.d("AlarmActivity", "Snooze button pressed for alarm id=$alarmId")
            snoozeAlarm(prayerName, alarmId)
            stopAlarm()
            releaseWakeLock()
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

        // Phase C: Start MediaPlayer with proper audio attributes and looping
        try {
            // New behavior: prefer soundName extra (resource name in raw/), fallback to soundPath URI
            val soundName = intent.getStringExtra("soundName")
            Log.d("ALARM_SOUND_DEBUG", "AlarmActivity.startAlarm: soundName=$soundName, soundPath=$soundPath")
            
            if (soundName != null && soundName.isNotEmpty()) {
                Log.d("ALARM_SOUND_DEBUG", "Resolving resource for soundName='$soundName'")
                val resId = resources.getIdentifier(soundName, "raw", packageName)
                Log.d("ALARM_SOUND_DEBUG", "getIdentifier('$soundName', 'raw', '$packageName') returned resId=$resId")
                
                if (resId == 0) {
                    Log.e("ALARM_SOUND_DEBUG", "ERROR: Resource not found for soundName='$soundName', falling back to 'standard'")
                    val defaultResId = resources.getIdentifier("standard", "raw", packageName)
                    if (defaultResId != 0) {
                        mediaPlayer?.release()
                        mediaPlayer = MediaPlayer.create(this, defaultResId)
                    } else {
                        Log.e("ALARM_SOUND_DEBUG", "ERROR: 'standard' resource also not found! No sound will play")
                    }
                } else {
                    Log.d("ALARM_SOUND_DEBUG", "Successfully found resource id=$resId for soundName='$soundName', creating MediaPlayer")
                    mediaPlayer?.release()
                    mediaPlayer = MediaPlayer.create(this, resId)
                }
                
                mediaPlayer?.apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    isLooping = true
                    setVolume(volumeLevel, volumeLevel)
                    start()
                    Log.d("ALARM_SOUND_DEBUG", "MediaPlayer started with soundName='$soundName', isPlaying=${this.isPlaying}")
                }
                startFadeIn()
            } else {
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
                    Log.d("AlarmActivity", "MediaPlayer started with audio attributes USAGE_ALARM")
                }
                startFadeIn()
            }
        } catch (e: Exception) {
            Log.e("AlarmActivity", "Error starting primary audio: ${e.message}", e)
            e.printStackTrace()
            // Final fallback to system alarm if adhan resource also fails
            try {
                mediaPlayer?.release()
                mediaPlayer = MediaPlayer.create(this, android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI)
                mediaPlayer?.isLooping = true
                mediaPlayer?.start()
                Log.d("AlarmActivity", "Fallback to system alarm audio")
            } catch (e2: Exception) {
                Log.e("AlarmActivity", "Error with fallback audio: ${e2.message}", e2)
                e2.printStackTrace()
            }
        }
    }

    private fun startFadeIn() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (volumeLevel < 1.0f && !isReleased) {
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
            putExtra("alarm_id", alarmId + 10000)
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
            @Suppress("DEPRECATION")
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, snoozeTime, pendingIntent)
        }
        
        Log.d("AlarmActivity", "Snooze scheduled for 5 minutes")
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                Log.d("AlarmActivity", "WakeLock released")
            }
        } catch (e: Exception) {
            Log.e("AlarmActivity", "Error releasing WakeLock: ${e.message}")
        }
    }

    override fun onPause() {
        // Phase C: Clean up on pause to prevent memory leaks
        Log.d("AlarmActivity", "onPause called")
        super.onPause()
    }

    override fun onStop() {
        super.onStop()
        Log.d("AlarmActivity", "onStop called")
        // If the activity is no longer visible and finishing, clean up
        if (isFinishing) {
            stopAlarm()
            releaseWakeLock()
        }
    }

    override fun onDestroy() {
        Log.d("AlarmActivity", "onDestroy called")
        stopAlarm()
        releaseWakeLock()
        super.onDestroy()
    }

    private fun stopAlarm() {
        if (isReleased) {
            Log.d("AlarmActivity", "stopAlarm already called, skipping")
            return
        }
        isReleased = true
        
        Log.d("AlarmActivity", "Stopping alarm (MediaPlayer and Vibrator cleanup)")
        
        // Remove all pending callbacks to stop fade-in
        handler.removeCallbacksAndMessages(null)
        
        // Phase C: Proper MediaPlayer cleanup to prevent memory leaks
        try {
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.stop()
                Log.d("AlarmActivity", "MediaPlayer stopped")
            }
            mediaPlayer?.release()
            Log.d("AlarmActivity", "MediaPlayer released")
        } catch (e: Exception) {
            Log.e("AlarmActivity", "Error stopping MediaPlayer: ${e.message}", e)
        }
        mediaPlayer = null
        
        // Cancel vibration
        try {
            vibrator?.cancel()
            Log.d("AlarmActivity", "Vibrator cancelled")
        } catch (e: Exception) {
            Log.e("AlarmActivity", "Error cancelling vibrator: ${e.message}")
        }
    }
}
