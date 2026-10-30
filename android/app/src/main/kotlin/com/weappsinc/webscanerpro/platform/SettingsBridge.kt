package com.weappsinc.webscanerpro.platform

import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SettingsBridge(private val context: Context) {
    private val preferences = context.getSharedPreferences("web_scanner_settings", Context.MODE_PRIVATE)

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            "getSettings" -> result.success(mapOf(
                "theme" to preferences.getString("theme", "system"),
                "onboardingDone" to preferences.getBoolean("onboardingDone", false),
                "languageCode" to preferences.getString("languageCode", "vi"),
                "showHomeHand" to preferences.getBoolean("showHomeHand", true),
                "shownNotifyDialog" to preferences.getBoolean("shownNotifyDialog", false),
                "shownStorageDialog" to preferences.getBoolean("shownStorageDialog", false),
                "captureEnabled" to preferences.getBoolean("captureEnabled", true)
            ))
            "updateSettings" -> update(call, result)
            "openExternalUrl" -> openExternalUrl(call, result)
            else -> return false
        }
        return true
    }

    private fun openExternalUrl(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url").orEmpty().trim()
        if (url.isBlank()) {
            result.error("invalid_url", "URL không hợp lệ.", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            result.success(null)
        } catch (_: Exception) {
            result.error("open_url_failed", "Không mở được liên kết.", null)
        }
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
        call.argument<String>("languageCode")?.let { editor.putString("languageCode", it) }
        call.argument<Boolean>("showHomeHand")?.let { editor.putBoolean("showHomeHand", it) }
        call.argument<Boolean>("shownNotifyDialog")?.let { editor.putBoolean("shownNotifyDialog", it) }
        call.argument<Boolean>("shownStorageDialog")?.let { editor.putBoolean("shownStorageDialog", it) }
        call.argument<Boolean>("captureEnabled")?.let { editor.putBoolean("captureEnabled", it) }
        if (editor.commit()) result.success(null)
        else result.error("settings_failed", "Không lưu được cài đặt.", null)
    }
}
