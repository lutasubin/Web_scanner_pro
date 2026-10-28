package com.weappsinc.webscanerpro.platform

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DirectChatBridge(private val activity: Activity) {
    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        if (call.method != "openDirectChat") return false
        val phone = call.argument<String>("phone").orEmpty()
        if (!Regex("^[1-9][0-9]{6,14}$").matches(phone)) {
            result.error("invalid_phone", "Nhập số quốc tế gồm mã nước và 7–15 chữ số.", null)
            return true
        }
        val message = call.argument<String>("message").orEmpty()
        val uri = Uri.Builder().scheme("https").authority("wa.me").appendPath(phone)
            .appendQueryParameter("text", message).build()
        val appPackage = if (call.argument<Boolean>("business") == true)
            "com.whatsapp.w4b" else "com.whatsapp"
        try {
            activity.startActivity(Intent(Intent.ACTION_VIEW, uri).setPackage(appPackage))
            result.success(null)
        } catch (_: ActivityNotFoundException) {
            result.error("app_not_installed", "Chưa cài ứng dụng WhatsApp đã chọn. Hãy cài hoặc đổi lựa chọn.", null)
        }
        return true
    }
}
