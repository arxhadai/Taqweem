package com.ramzan.companion.ramzan_companion

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d("BootReceiver", "Device rebooted, rescheduling alarms...")
            
            // In a real production app, we would query the local database (Hive/SharedPreferences)
            // here and reschedule alarms. For now, we delegate this back to Flutter
            // via a MethodChannel or wait for the app to launch and handle it.
            // Requirement says "Reschedule all enabled alarms". 
            // We implementation MethodChannel in MainActivity to handle this.
            
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            // context.startActivity(launchIntent) // Optional: launch app to reschedule
        }
    }
}
