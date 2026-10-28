package com.example.web_scanner_pro

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.web_scanner_pro.ads.DualAppBannerFactory
import com.example.web_scanner_pro.ads.DualAppNativeAdManager
import com.example.web_scanner_pro.ads.DualAppNativeFactory
import com.example.web_scanner_pro.ads.WebScannerNativeAdFactory
import com.example.web_scanner_pro.history.HistoryBridge
import com.example.web_scanner_pro.history.NotificationCaptureService
import com.example.web_scanner_pro.media.MediaBridge
import com.example.web_scanner_pro.media.StatusMonitorService
import com.example.web_scanner_pro.platform.DirectChatBridge
import com.example.web_scanner_pro.platform.SettingsBridge
import com.example.web_scanner_pro.web.WebBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var media: MediaBridge
    private var pendingRoute: String? = null
    private var platformChannel: MethodChannel? = null
    private val statusUpdateListener: () -> Unit = {
        runCatching {
            platformChannel?.invokeMethod("onStatusesUpdated", null)
        }
    }
    private val historyUpdateListener: () -> Unit = {
        runCatching {
            platformChannel?.invokeMethod("onHistoryUpdated", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ensurePostNotificationsPermission()
        StatusMonitorService.ensureRunning(this)
        StatusMonitorService.addListener(statusUpdateListener)
        NotificationCaptureService.onHistoryUpdated = historyUpdateListener
        WebScannerNativeAdFactory.registerAll(flutterEngine, layoutInflater)
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "com.example.dual_app/banner_ad",
                DualAppBannerFactory(flutterEngine.dartExecutor.binaryMessenger) { this },
            )
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "com.example.dual_app/native_ad",
                DualAppNativeFactory(flutterEngine.dartExecutor.binaryMessenger) { this },
            )
        pendingRoute = intent?.getStringExtra("open_route") ?: pendingRoute
        media = MediaBridge(this)
        val web = WebBridge(this)
        val history = HistoryBridge(this)
        val settings = SettingsBridge(this)
        val directChat = DirectChatBridge(this)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "web_scanner_pro/platform",
        )
        platformChannel = channel
        channel.setMethodCallHandler { call, result ->
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
                } else if (call.method == "setNativeCollabCollapsed") {
                    val collapsed = call.argument<Boolean>("collapsed") ?: false
                    WebScannerNativeAdFactory.setCollabCollapsed(collapsed)
                    result.success(null)
                } else if (call.method == "preloadNativeAds") {
                    val adUnitId = call.argument<String>("adUnitId").orEmpty()
                    val fallbackAdUnitId = call.argument<String>("fallbackAdUnitId").orEmpty()
                    DualAppNativeAdManager.configureAndPreload(this, adUnitId, fallbackAdUnitId)
                    result.success(DualAppNativeAdManager.cachedCount())
                } else if (call.method == "getNativeCachedCount") {
                    result.success(DualAppNativeAdManager.cachedCount())
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
        intent.getStringExtra("open_route")?.takeIf { it.isNotBlank() }?.let { route ->
            pendingRoute = route
            runCatching {
                platformChannel?.invokeMethod("onOpenRoute", route)
            }
        }
    }

    private fun ensurePostNotificationsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS,
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                runCatching {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        7420,
                    )
                }
            }
        }
    }

    @Deprecated("Flutter Activity integration uses the Android activity result callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (::media.isInitialized && media.onActivityResult(requestCode, resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        StatusMonitorService.removeListener(statusUpdateListener)
        if (NotificationCaptureService.onHistoryUpdated === historyUpdateListener) {
            NotificationCaptureService.onHistoryUpdated = null
        }
        platformChannel = null
        WebScannerNativeAdFactory.unregisterAll(flutterEngine)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        StatusMonitorService.removeListener(statusUpdateListener)
        if (NotificationCaptureService.onHistoryUpdated === historyUpdateListener) {
            NotificationCaptureService.onHistoryUpdated = null
        }
        if (::media.isInitialized) media.dispose()
        super.onDestroy()
    }
}
