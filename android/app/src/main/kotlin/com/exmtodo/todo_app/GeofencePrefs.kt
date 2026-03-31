package com.exmtodo.todo_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Persiste registros de geofence para re-aplicar após boot e resolver título/corpo na notificação.
 */
object GeofencePrefs {
    private const val PREFS = "exm_geofence_v1"
    private const val KEY_JSON = "registrations_json"

    data class Registration(
        val taskId: String,
        val latitude: Double,
        val longitude: Double,
        val radiusMeters: Float,
        val locationTrigger: String,
        val title: String,
        val body: String,
    )

    fun saveRegistrations(context: Context, items: List<Registration>) {
        val arr = JSONArray()
        for (r in items) {
            val o = JSONObject()
            o.put("taskId", r.taskId)
            o.put("latitude", r.latitude)
            o.put("longitude", r.longitude)
            o.put("radiusMeters", r.radiusMeters.toDouble())
            o.put("locationTrigger", r.locationTrigger)
            o.put("title", r.title)
            o.put("body", r.body)
            arr.put(o)
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_JSON, arr.toString())
            .apply()
    }

    fun loadRegistrations(context: Context): List<Registration> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_JSON, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            val out = ArrayList<Registration>(arr.length())
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                out.add(
                    Registration(
                        taskId = o.getString("taskId"),
                        latitude = o.getDouble("latitude"),
                        longitude = o.getDouble("longitude"),
                        radiusMeters = o.getDouble("radiusMeters").toFloat(),
                        locationTrigger = o.optString("locationTrigger", "arrival"),
                        title = o.getString("title"),
                        body = o.getString("body"),
                    ),
                )
            }
            out
        } catch (_: Exception) {
            emptyList()
        }
    }
}
