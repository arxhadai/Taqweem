package com.ramzan.companion.ramzan_companion

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Data class to represent a stored alarm in persistent storage.
 *
 * @property alarmId Unique identifier for the alarm
 * @property alarmType Type of alarm (e.g., "sehri", "iftar", "pre-alarm")
 * @property triggerTime Alarm trigger time in milliseconds since epoch
 * @property prayerName Name of the prayer (e.g., "Fajr", "Maghrib")
 * @property dayOffset Day offset relative to today (0 = today, 1 = tomorrow, etc.)
 */
data class StoredAlarm(
    val alarmId: Int,
    val alarmType: String,
    val triggerTime: Long,
    val prayerName: String,
    val dayOffset: Int
)

/**
 * AlarmStorage handles persistent storage of alarm metadata using SharedPreferences.
 *
 * This layer ensures that alarm metadata can be recovered if:
 * - The app crashes after scheduling but before the alarm fires
 * - The app is force-stopped
 * - The device reboots
 *
 * Data is stored as a JSON array under the key "stored_alarms".
 */
object AlarmStorage {
    private const val TAG = "AlarmStorage"
    private const val PREFS_NAME = "alarm_storage"
    private const val ALARMS_KEY = "stored_alarms"

    /**
     * Get SharedPreferences instance for alarm storage.
     */
    private fun getPreferences(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    /**
     * Save or update an alarm in persistent storage.
     *
     * If an alarm with the same alarmId already exists, it will be replaced.
     * This prevents duplicate entries.
     *
     * @param context Application context
     * @param alarm The alarm to save
     */
    fun saveAlarm(context: Context, alarm: StoredAlarm) {
        try {
            val prefs = getPreferences(context)
            val alarms = getAllAlarms(context).toMutableList()

            // Remove existing alarm with same ID to prevent duplicates
            alarms.removeAll { it.alarmId == alarm.alarmId }

            // Add the new alarm
            alarms.add(alarm)

            // Convert to JSON and save
            val jsonArray = JSONArray()
            for (a in alarms) {
                val obj = JSONObject().apply {
                    put("alarmId", a.alarmId)
                    put("alarmType", a.alarmType)
                    put("triggerTime", a.triggerTime)
                    put("prayerName", a.prayerName)
                    put("dayOffset", a.dayOffset)
                }
                jsonArray.put(obj)
            }

            prefs.edit().apply {
                putString(ALARMS_KEY, jsonArray.toString())
                apply()
            }

            Log.d(TAG, "Saved alarm: id=${alarm.alarmId}, type=${alarm.alarmType}, prayer=${alarm.prayerName}, time=${alarm.triggerTime}")

        } catch (e: Exception) {
            Log.e(TAG, "Error saving alarm: ${e.message}", e)
        }
    }

    /**
     * Remove an alarm from persistent storage by its ID.
     *
     * If the alarm doesn't exist, this operation has no effect.
     *
     * @param context Application context
     * @param alarmId The ID of the alarm to remove
     */
    fun removeAlarm(context: Context, alarmId: Int) {
        try {
            val prefs = getPreferences(context)
            val alarms = getAllAlarms(context).toMutableList()

            // Remove the alarm with the given ID
            val wasRemoved = alarms.removeAll { it.alarmId == alarmId }

            if (wasRemoved) {
                // Convert to JSON and save
                val jsonArray = JSONArray()
                for (a in alarms) {
                    val obj = JSONObject().apply {
                        put("alarmId", a.alarmId)
                        put("alarmType", a.alarmType)
                        put("triggerTime", a.triggerTime)
                        put("prayerName", a.prayerName)
                        put("dayOffset", a.dayOffset)
                    }
                    jsonArray.put(obj)
                }

                prefs.edit().apply {
                    putString(ALARMS_KEY, jsonArray.toString())
                    apply()
                }

                Log.d(TAG, "Removed alarm: id=$alarmId")
            } else {
                Log.d(TAG, "Alarm not found for removal: id=$alarmId")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error removing alarm: ${e.message}", e)
        }
    }

    /**
     * Retrieve all stored alarms from persistent storage.
     *
     * Returns an empty list if no alarms are stored or if there's an error reading.
     *
     * @param context Application context
     * @return List of all stored alarms
     */
    fun getAllAlarms(context: Context): List<StoredAlarm> {
        return try {
            val prefs = getPreferences(context)
            val jsonString = prefs.getString(ALARMS_KEY, null) ?: return emptyList()

            val alarms = mutableListOf<StoredAlarm>()
            val jsonArray = JSONArray(jsonString)

            for (i in 0 until jsonArray.length()) {
                try {
                    val obj = jsonArray.getJSONObject(i)
                    val alarm = StoredAlarm(
                        alarmId = obj.getInt("alarmId"),
                        alarmType = obj.getString("alarmType"),
                        triggerTime = obj.getLong("triggerTime"),
                        prayerName = obj.getString("prayerName"),
                        dayOffset = obj.getInt("dayOffset")
                    )
                    alarms.add(alarm)
                } catch (e: Exception) {
                    Log.w(TAG, "Error parsing alarm at index $i: ${e.message}")
                    // Continue processing other alarms
                }
            }

            Log.d(TAG, "Retrieved ${alarms.size} alarms from storage")
            alarms

        } catch (e: Exception) {
            Log.e(TAG, "Error retrieving alarms: ${e.message}", e)
            emptyList()
        }
    }

    /**
     * Clear all stored alarms from persistent storage.
     *
     * This is a destructive operation that removes all alarm metadata.
     * Use with caution.
     *
     * @param context Application context
     */
    fun clearAll(context: Context) {
        try {
            val prefs = getPreferences(context)
            prefs.edit().apply {
                remove(ALARMS_KEY)
                apply()
            }
            Log.d(TAG, "Cleared all stored alarms")
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing alarms: ${e.message}", e)
        }
    }
}
