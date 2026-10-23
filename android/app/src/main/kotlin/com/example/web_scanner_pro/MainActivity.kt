package com.example.web_scanner_pro

import android.content.Intent
import com.example.web_scanner_pro.history.HistoryBridge
import com.example.web_scanner_pro.media.MediaBridge
import com.example.web_scanner_pro.platform.DirectChatBridge
import com.example.web_scanner_pro.platform.SettingsBridge
import com.example.web_scanner_pro.web.WebBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var media: MediaBridge
    private var pendingRoute: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingRoute = intent?.getStringExtra("open_route") ?: pendingRoute
        media = MediaBridge(this)
        val web = WebBridge(this)
        val history = HistoryBridge(this)
        val settings = SettingsBridge(this)
        val directChat = DirectChatBridge(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "web_scanner_pro/platform").setMethodCallHandler { call, result ->
            try {
                if (call.method == "getCapabilities") {
                    result.success(mapOf(
                        "multiProfile" to WebBridge.supportsProfiles(),
                        "notificationAccess" to HistoryBridge.hasAccess(this)
                    ))
                } else if (call.method == "consumePendingRoute") {
                    val route = pendingRoute
                    pendingRoute = null
                    result.success(route)
                } else if (!settings.handle(call, result) &&
                    !directChat.handle(call, result) && !web.handle(call, result) &&
                    !history.handle(call, result) && !media.handle(call, result)) {
                    result.notImplemented()
                }
            } catch (_: Exception) {
                result.error("platform_error", "Không thể hoàn tất thao tác. Hãy thử lại.", null)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra("open_route")?.takeIf { it.isNotBlank() }?.let {
            pendingRoute = it
        }
    }

    @Deprecated("Flutter Activity integration uses the Android activity result callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (::media.isInitialized && media.onActivityResult(requestCode, resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        if (::media.isInitialized) media.dispose()
        super.onDestroy()
    }
}
