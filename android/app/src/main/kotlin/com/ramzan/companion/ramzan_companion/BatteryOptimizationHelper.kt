package com.ramzan.companion.ramzan_companion

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * BatteryOptimizationHelper provides utilities to check and request battery optimization whitelist.
 *
 * Background:
 * Many OEM devices (Xiaomi, Oppo, Vivo, Realme, Huawei, OnePlus) implement aggressive battery
 * optimization that kills background processes aggressively. This prevents alarms from being
 * scheduled and rescheduled reliably.
 *
 * Solution:
 * Request user to whitelist the app from battery optimization. This is a soft prompt that
 * respects user choice but educates about the requirement.
 */
object BatteryOptimizationHelper {
    private const val TAG = "BatteryOptimizationHelper"

    // SharedPreferences key to track if we've shown the dialog
    private const val PREFS_NAME = "battery_optimization"
    private const val KEY_DIALOG_SHOWN = "battery_opt_dialog_shown"

    /**
     * Check if the app is currently whitelisted from battery optimization.
     *
     * @param context Application context
     * @return true if app is ignoring battery optimization, false otherwise
     */
    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(context.packageName)
        } else {
            // Pre-Android 6.0 doesn't have aggressive battery optimization
            true
        }
    }

    /**
     * Request user to disable battery optimization for this app.
     *
     * This launches the system settings for battery optimization whitelist.
     * User can choose to allow or deny.
     *
     * @param activity The activity to launch the intent from
     */
    fun requestDisableBatteryOptimization(activity: Activity) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = android.net.Uri.parse("package:${activity.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                activity.startActivity(intent)
                Log.d(TAG, "Launched battery optimization whitelist intent")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error launching battery optimization settings: ${e.message}", e)
        }
    }

    /**
     * Check if device manufacturer is known to be aggressive with battery optimization.
     *
     * These manufacturers typically kill background processes very aggressively,
     * making it necessary for users to explicitly whitelist the app.
     *
     * @return true if device is from an aggressive OEM, false otherwise
     */
    fun isAggressiveOEM(): Boolean {
        val manufacturer = Build.MANUFACTURER.lowercase()
        return manufacturer in listOf(
            "xiaomi",
            "oppo",
            "vivo",
            "realme",
            "huawei",
            "oneplus"
        )
    }

    /**
     * Get the device manufacturer name.
     *
     * @return Manufacturer name from Build.MANUFACTURER
     */
    fun getManufacturerName(): String {
        return Build.MANUFACTURER
    }

    /**
     * Check if battery optimization dialog should be shown.
     *
     * Returns true if:
     * - Device has aggressive battery optimization
     * - App is not whitelisted
     * - Dialog hasn't been shown before in this install
     *
     * @param context Application context
     * @return true if dialog should be shown
     */
    fun shouldShowDialog(context: Context): Boolean {
        // Only show on aggressive OEMs
        if (!isAggressiveOEM()) {
            Log.d(TAG, "Device is not aggressive OEM (${getManufacturerName()}), skipping dialog")
            return false
        }

        // Only show if not already whitelisted
        if (isIgnoringBatteryOptimizations(context)) {
            Log.d(TAG, "App is already whitelisted from battery optimization")
            return false
        }

        // Only show once per install
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val alreadyShown = prefs.getBoolean(KEY_DIALOG_SHOWN, false)
        if (alreadyShown) {
            Log.d(TAG, "Battery optimization dialog already shown in this install")
            return false
        }

        Log.d(TAG, "Should show battery optimization dialog")
        return true
    }

    /**
     * Mark the dialog as shown so it won't appear again.
     *
     * @param context Application context
     */
    fun markDialogAsShown(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().apply {
            putBoolean(KEY_DIALOG_SHOWN, true)
            apply()
        }
        Log.d(TAG, "Marked battery optimization dialog as shown")
    }

    /**
     * Log battery optimization state for debugging.
     *
     * @param context Application context
     */
    fun logBatteryOptimizationState(context: Context) {
        val manufacturer = getManufacturerName()
        val isAggressive = isAggressiveOEM()
        val isIgnoring = isIgnoringBatteryOptimizations(context)
        
        Log.d(
            TAG,
            "Battery Optimization State: " +
            "Manufacturer=$manufacturer, " +
            "IsAggressiveOEM=$isAggressive, " +
            "IsWhitelisted=$isIgnoring"
        )
    }
}
