package com.exmtodo.todo_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Reaplica geofences após reinício do dispositivo.
 */
class GeofenceBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED &&
            intent?.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        GeofenceRepository.restoreFromPrefs(context.applicationContext)
    }
}
