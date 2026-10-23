package com.example.web_scanner_pro.history

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class HistoryBridge(private val context: Context) {
    private val store = HistoryStore(context.applicationContext)

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            "listMessages", "clearMessages", "deleteMessage", "deleteConversation" -> HistoryDispatch.worker.execute {
                try {
                    val value = when (call.method) {
                        "listMessages" -> store.list().map { it.asMap() }
                        "deleteMessage" -> {
                            store.deleteMessage(call.argument<String>("id").orEmpty())
                            null
                        }
                        "deleteConversation" -> {
                            store.deleteConversation(
                                call.argument<String>("title").orEmpty(),
                                call.argument<String>("packageName").orEmpty(),
                            )
                            null
                        }
                        else -> {
                            store.clear()
                            null
                        }
                    }
                    HistoryDispatch.main.post { result.success(value) }
                } catch (_: Exception) {
                    HistoryDispatch.main.post {
                        result.error("history_failed", "Không đọc hoặc xóa được lịch sử mã hóa. Hãy thử lại hoặc xóa lịch sử.", null)
                    }
                }
            }
            "openNotificationSettings" -> openSettings(result)
            else -> return false
        }
        return true
    }

    private fun openSettings(result: MethodChannel.Result) {
        try {
            context.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            result.success(null)
        } catch (_: Exception) {
            result.error("settings_unavailable", "Không mở được cài đặt quyền thông báo trên thiết bị này.", null)
        }
    }

    companion object {
        fun hasAccess(context: Context): Boolean =
            context.getSystemService(NotificationManager::class.java).isNotificationListenerAccessGranted(
                ComponentName(context, NotificationCaptureService::class.java))
    }
}
