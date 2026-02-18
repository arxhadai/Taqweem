package com.ramzan.companion.ramzan_companion

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra("prayer_name")
        val soundPath = intent.getStringExtra("sound_path")
        val alarmId = intent.getIntExtra("alarm_id", 0)

        Log.d("AlarmReceiver", "Alarm received for: $prayerName (ID: $alarmId)")

        val activityIntent = Intent(context, AlarmActivity::class.java).apply {
            putExtra("prayer_name", prayerName)
            putExtra("sound_path", soundPath)
            putExtra("alarm_id", alarmId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        
        context.startActivity(activityIntent)
    }
}
