package com.example.web_scanner_pro.platform

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SettingsBridge(context: Context) {
    private val preferences = context.getSharedPreferences("web_scanner_settings", Context.MODE_PRIVATE)

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            "getSettings" -> result.success(mapOf(
                "theme" to preferences.getString("theme", "system"),
                "onboardingDone" to preferences.getBoolean("onboardingDone", false),
                "captureEnabled" to preferences.getBoolean("captureEnabled", false)
            ))
            "updateSettings" -> update(call, result)
            else -> return false
        }
        return true
    }

    private fun update(call: MethodCall, result: MethodChannel.Result) {
        val theme = call.argument<String>("theme")
        if (theme != null && theme !in setOf("system", "light", "dark")) {
            result.error("invalid_theme", "Giao diện không hợp lệ.", null)
            return
        }
        val editor = preferences.edit()
        theme?.let { editor.putString("theme", it) }
        call.argument<Boolean>("onboardingDone")?.let { editor.putBoolean("onboardingDone", it) }
        call.argument<Boolean>("captureEnabled")?.let { editor.putBoolean("captureEnabled", it) }
        if (editor.commit()) result.success(null)
        else result.error("settings_failed", "Không lưu được cài đặt.", null)
    }
}
