package com.weappsinc.webscanerpro.web

import android.webkit.WebStorage
import androidx.webkit.ProfileStore
import androidx.webkit.WebStorageCompat
import androidx.webkit.WebViewFeature
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

object SessionProfiles {
    private val activities = mutableListOf<WeakReference<WebSessionActivity>>()
    private val resetting = mutableSetOf<String>()

    fun name(id: String): String {
        require(WebSessionStore.isValidId(id))
        return "web_scanner_$id"
    }
    fun isResetting(id: String): Boolean = id in resetting
    fun register(activity: WebSessionActivity) { activities.add(WeakReference(activity)) }
    fun unregister(activity: WebSessionActivity) {
        activities.removeAll { it.get() == null || it.get() === activity }
    }

    fun reset(id: String, result: MethodChannel.Result) {
        if (!resetting.add(id)) {
            result.error("reset_running", "Phiên đang được xóa dữ liệu.", null)
            return
        }
        activities.mapNotNull { it.get() }.filter { it.sessionId == id }.forEach { it.closeSession() }
        try {
            if (WebBridge.supportsProfiles()) {
                try {
                    ProfileStore.getInstance().deleteProfile(name(id))
                    resetting.remove(id)
                    result.success(null)
                    return
                } catch (_: IllegalStateException) {
                    // Profile đã tải vào bộ nhớ cần API xóa toàn bộ dữ liệu của riêng profile.
                }
            }
            if (!WebViewFeature.isFeatureSupported(WebViewFeature.DELETE_BROWSING_DATA)) {
                resetting.remove(id)
                result.error("reset_unavailable", "Cập nhật WebView hoặc mở lại app rồi xóa phiên trước khi mở web.", null)
                return
            }
            val storage = if (WebBridge.supportsProfiles())
                ProfileStore.getInstance().getOrCreateProfile(name(id)).webStorage
            else WebStorage.getInstance()
            WebStorageCompat.deleteBrowsingData(storage) {
                resetting.remove(id)
                result.success(null)
            }
        } catch (_: Exception) {
            resetting.remove(id)
            result.error("reset_failed", "Chưa xóa được phiên. Đóng app rồi thử lại.", null)
        }
    }
}
