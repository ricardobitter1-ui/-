package com.exmtodo.todo_app

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

object GeofenceRepository {
    private const val TAG = "ExmGeofence"

    private fun client(context: Context): GeofencingClient =
        LocationServices.getGeofencingClient(context.applicationContext)

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java).apply {
            action = GeofenceBroadcastReceiver.ACTION
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        return PendingIntent.getBroadcast(context.applicationContext, 0, intent, flags)
    }

    private fun transitionForTrigger(trigger: String): Int =
        if (trigger == "departure") {
            Geofence.GEOFENCE_TRANSITION_EXIT
        } else {
            Geofence.GEOFENCE_TRANSITION_ENTER
        }

    private fun androidRadiusMeters(r: Float): Float = r.coerceAtLeast(50f)

    /**
     * Substitui todos os geofences pelos registos dados (lista vazia remove tudo).
     */
    fun sync(context: Context, items: List<GeofencePrefs.Registration>) {
        GeofencePrefs.saveRegistrations(context, items)
        val geofencingClient = client(context)
        val pi = pendingIntent(context)

        Handler(Looper.getMainLooper()).post {
            geofencingClient.removeGeofences(pi)
                .addOnCompleteListener {
                    if (items.isEmpty()) {
                        Log.d(TAG, "Geofences cleared")
                        return@addOnCompleteListener
                    }
                    val geofences = items.map { reg ->
                        Geofence.Builder()
                            .setRequestId(reg.taskId)
                            .setCircularRegion(
                                reg.latitude,
                                reg.longitude,
                                androidRadiusMeters(reg.radiusMeters),
                            )
                            .setExpirationDuration(Geofence.NEVER_EXPIRE)
                            .setTransitionTypes(transitionForTrigger(reg.locationTrigger))
                            .build()
                    }
                    val request = GeofencingRequest.Builder()
                        .setInitialTrigger(0)
                        .addGeofences(geofences)
                        .build()

                    geofencingClient.addGeofences(request, pi)
                        .addOnSuccessListener {
                            Log.d(TAG, "Registered ${items.size} geofence(s)")
                        }
                        .addOnFailureListener { e ->
                            Log.e(TAG, "addGeofences failed", e)
                        }
                }
        }
    }

    /** Re-registrar após boot (dados já estão em prefs). */
    fun restoreFromPrefs(context: Context) {
        val items = GeofencePrefs.loadRegistrations(context)
        if (items.isEmpty()) return
        // removeGeofences + add em main thread evita race com primeiro remove
        android.os.Handler(Looper.getMainLooper()).post {
            sync(context, items)
        }
    }
}
