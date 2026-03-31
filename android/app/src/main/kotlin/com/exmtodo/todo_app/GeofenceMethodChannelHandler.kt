package com.exmtodo.todo_app

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object GeofenceMethodChannelHandler {
    private const val CHANNEL = "com.exmtodo.todo_app/geofence"

    fun register(messenger: io.flutter.plugin.common.BinaryMessenger, context: Context) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sync" -> handleSync(call, context, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleSync(call: MethodCall, context: Context, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        val raw = call.arguments as? List<*> ?: run {
            result.error("bad_args", "Expected list", null)
            return
        }
        val items = ArrayList<GeofencePrefs.Registration>(raw.size)
        for (e in raw) {
            val m = e as? Map<*, *> ?: continue
            val taskId = m["taskId"]?.toString() ?: continue
            val lat = (m["latitude"] as? Number)?.toDouble() ?: continue
            val lng = (m["longitude"] as? Number)?.toDouble() ?: continue
            val radius = (m["radiusMeters"] as? Number)?.toFloat() ?: 100f
            val trigger = m["locationTrigger"]?.toString() ?: "arrival"
            val title = m["title"]?.toString() ?: "Tarefa"
            val body = m["body"]?.toString() ?: ""
            items.add(
                GeofencePrefs.Registration(
                    taskId = taskId,
                    latitude = lat,
                    longitude = lng,
                    radiusMeters = radius,
                    locationTrigger = trigger,
                    title = title,
                    body = body,
                ),
            )
        }
        try {
            GeofenceRepository.sync(context.applicationContext, items)
            result.success(null)
        } catch (e: Exception) {
            result.error("sync_failed", e.message, null)
        }
    }
}
