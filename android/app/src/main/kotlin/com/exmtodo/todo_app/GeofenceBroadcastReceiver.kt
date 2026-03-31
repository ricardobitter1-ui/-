package com.exmtodo.todo_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

class GeofenceBroadcastReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return

        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) {
            Log.w(TAG, "Geofencing error: ${event.errorCode}")
            return
        }

        val transition = event.geofenceTransition
        val regs = GeofencePrefs.loadRegistrations(context).associateBy { it.taskId }

        for (gf in event.triggeringGeofences ?: emptyList()) {
            val id = gf.requestId ?: continue
            val reg = regs[id] ?: continue
            val wantEnter = reg.locationTrigger != "departure"
            val ok = (wantEnter && transition == Geofence.GEOFENCE_TRANSITION_ENTER) ||
                (!wantEnter && transition == Geofence.GEOFENCE_TRANSITION_EXIT)
            if (!ok) continue
            showTaskNotification(context, id, reg.title, reg.body)
        }
    }

    private fun showTaskNotification(
        context: Context,
        taskId: String,
        title: String,
        body: String,
    ) {
        ensureChannel(context)
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val contentPi = PendingIntent.getActivity(
            context,
            taskId.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(contentPi)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(taskId.hashCode(), notification)
        } catch (se: SecurityException) {
            Log.e(TAG, "POST_NOTIFICATIONS denied?", se)
        }
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = nm.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        val ch = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alertas ao chegar ou sair do local da tarefa"
        }
        nm.createNotificationChannel(ch)
    }

    companion object {
        const val ACTION = "com.exmtodo.todo_app.action.GEOFENCE_EVENT"
        private const val TAG = "ExmGeofenceRx"
        const val CHANNEL_ID = "geofence_task_channel_v1"
        private const val CHANNEL_NAME = "Lembretes por localização"
    }
}
