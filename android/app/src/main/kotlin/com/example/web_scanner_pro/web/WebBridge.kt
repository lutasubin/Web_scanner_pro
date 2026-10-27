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
            val activeId = store.activeId()
            result.success(store.list().map { it.toMap(activeId) })
            return true
        }
        if (call.method == "createSession") {
            return create(call.argument<String>("name").orEmpty(), result)
        }
        if (call.method == "renameSession") {
            return rename(
                call.argument<String>("id").orEmpty(),
                call.argument<String>("name").orEmpty(),
                result,
            )
        }
        if (call.method == "reorderSessions") {
            val ids = call.argument<List<String>>("ids").orEmpty()
            store.reorder(ids)
            result.success(null)
            return true
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
        if (call.method == "deleteSession" && id == WebSessionStore.DEFAULT_ID &&
            !supportsProfiles() && store.list().size > 1) {
            result.error("profile_unavailable", "Cập nhật Android System WebView trước khi xóa tài khoản này.", null)
            return true
        }
        try {
            when (call.method) {
                "resetSession" -> SessionProfiles.reset(id, result)
                "deleteSession" -> delete(id, result)
                else -> {
                    store.select(id)
                    val bannerEnabled = call.argument<Boolean>("bannerEnabled") ?: true
                    val bannerAdUnitId = call.argument<String>("bannerAdUnitId").orEmpty()
                    activity.startActivity(
                        Intent(activity, WebSessionActivity::class.java)
                            .putExtra("id", id)
                            .putExtra("banner_enabled", bannerEnabled)
                            .putExtra("banner_ad_unit_id", bannerAdUnitId)
                    )
                    result.success(null)
                }
            }
        } catch (_: Exception) {
            result.error("web_unavailable", "Không mở được WebView. Hãy kiểm tra Android System WebView.", null)
        }
        return true
    }

    private fun create(name: String, result: MethodChannel.Result): Boolean {
        if (store.list().isNotEmpty() && !supportsProfiles()) {
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

    private fun rename(id: String, name: String, result: MethodChannel.Result): Boolean {
        return try {
            if (store.rename(id, name)) result.success(null)
            else result.error("invalid_session", "Không tìm thấy tài khoản.", null)
            true
        } catch (_: IllegalArgumentException) {
            result.error("invalid_name", "Tên tài khoản cần từ 1 đến 40 ký tự.", null)
            true
        } catch (_: Exception) {
            result.error("rename_failed", "Chưa đổi được tên tài khoản. Hãy thử lại.", null)
            true
        }
    }

    private fun delete(id: String, result: MethodChannel.Result) {
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
