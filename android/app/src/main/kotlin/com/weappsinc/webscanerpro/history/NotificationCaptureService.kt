package com.weappsinc.webscanerpro.history

import android.content.ComponentName
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import com.weappsinc.webscanerpro.media.StatusMonitorService
import com.weappsinc.webscanerpro.media.StatusNotificationHelper

class NotificationCaptureService : NotificationListenerService() {
    override fun onCreate() {
        super.onCreate()
        StatusMonitorService.ensureRunning(this)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        StatusMonitorService.ensureRunning(this)
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        runCatching {
            requestRebind(ComponentName(this, NotificationCaptureService::class.java))
        }
    }

    override fun onNotificationPosted(notification: StatusBarNotification) {
        StatusMonitorService.ensureRunning(this)
        if (notification.packageName !in setOf("com.whatsapp", "com.whatsapp.w4b")) return
        val settings = getSharedPreferences("web_scanner_settings", Context.MODE_PRIVATE)
        if (!settings.getBoolean("captureEnabled", true)) return
        val messages = try { NotificationTextParser.parse(notification) } catch (_: Exception) { emptyList() }
        if (messages.isEmpty()) return
        val appContext = applicationContext
        HistoryDispatch.worker.execute {
            // Kiểm tra lại sau khi xếp hàng để việc tắt tính năng có hiệu lực ngay.
            if (!settings.getBoolean("captureEnabled", true)) return@execute
            try {
                HistoryStore(appContext).append(messages)
                StatusNotificationHelper.notifyNewMessage(appContext)
                dispatchHistoryUpdated()
            } catch (_: Exception) {
                // Không ghi nội dung thông báo hoặc dữ liệu mã hóa vào log.
            }
        }
    }

    companion object {
        @Volatile
        var onHistoryUpdated: (() -> Unit)? = null

        fun dispatchHistoryUpdated() {
            HistoryDispatch.main.post {
                onHistoryUpdated?.invoke()
            }
        }
    }
}
