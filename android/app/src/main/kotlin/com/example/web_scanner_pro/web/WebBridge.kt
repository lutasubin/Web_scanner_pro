package com.example.web_scanner_pro.web

import android.app.Activity
import android.content.Intent
import androidx.webkit.WebViewFeature
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WebBridge(private val activity: Activity) {
    private val store = WebSessionStore(activity)

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        if (call.method == "listSessions") {
            result.success(store.list().map(StoredWebSession::toMap))
            return true
        }
        if (call.method == "createSession") {
            return create(call.argument<String>("name").orEmpty(), result)
        }
        if (call.method !in setOf("openSession", "resetSession", "deleteSession")) return false
        val id = call.argument<String>("id").orEmpty()
        if (store.find(id) == null) {
            result.error("invalid_session", "Phiên không hợp lệ.", null)
            return true
        }
        if (id != WebSessionStore.DEFAULT_ID && !supportsProfiles()) {
            result.error("profile_unavailable", "Cập nhật Android System WebView để dùng nhiều người dùng.", null)
            return true
        }
        try {
            when (call.method) {
                "resetSession" -> SessionProfiles.reset(id, result)
                "deleteSession" -> delete(id, result)
                else -> {
                    activity.startActivity(Intent(activity, WebSessionActivity::class.java).putExtra("id", id))
                    result.success(null)
                }
            }
        } catch (_: Exception) {
            result.error("web_unavailable", "Không mở được WebView. Hãy kiểm tra Android System WebView.", null)
        }
        return true
    }

    private fun create(name: String, result: MethodChannel.Result): Boolean {
        if (!supportsProfiles()) {
            result.error("profile_unavailable", "Cập nhật Android System WebView để tạo thêm người dùng.", null)
            return true
        }
        try {
            store.create(name)
            result.success(null)
        } catch (_: IllegalArgumentException) {
            result.error("invalid_name", "Tên người dùng cần từ 1 đến 40 ký tự.", null)
        } catch (_: Exception) {
            result.error("create_failed", "Chưa tạo được người dùng. Hãy thử lại.", null)
        }
        return true
    }

    private fun delete(id: String, result: MethodChannel.Result) {
        if (id == WebSessionStore.DEFAULT_ID) {
            result.error("default_session", "Không thể xóa người dùng mặc định.", null)
            return
        }
        SessionProfiles.reset(id, object : MethodChannel.Result {
            override fun success(value: Any?) {
                if (store.remove(id)) result.success(null)
                else result.error("delete_failed", "Không tìm thấy người dùng để xóa.", null)
            }
            override fun error(code: String, message: String?, details: Any?) =
                result.error(code, message, details)
            override fun notImplemented() = result.notImplemented()
        })
    }

    companion object {
        fun supportsProfiles(): Boolean = try {
            WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)
        } catch (_: Exception) { false }
    }
}
