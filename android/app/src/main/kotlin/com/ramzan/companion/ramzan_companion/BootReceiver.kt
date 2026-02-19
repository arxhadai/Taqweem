package com.ramzan.companion.ramzan_companion

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_DATE_CHANGED
        ) {
            Log.d("BootReceiver", "System event received: $action")

            // Phase B: Recover and reschedule stored alarms
            Log.d("BootReceiver", "Initiating alarm recovery via AlarmRecoveryManager")
            AlarmRecoveryManager.recoverAlarms(context)

            // Legacy: Also launch app for Flutter's NotificationScheduler to double-check
            Log.d("BootReceiver", "Launching app for additional scheduler verification")
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (launchIntent != null) {
                context.startActivity(launchIntent)
            }
        }
    }
}
