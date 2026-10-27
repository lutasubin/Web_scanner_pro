package com.example.web_scanner_pro.ads

import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.RelativeLayout
import com.google.ads.mediation.admob.AdMobAdapter
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.LoadAdError
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Mirrors original app's `jc/f.java` + `jc/e.java` + `zl/e.java` + `yl/h.java`:
 * Registers `"com.example.dual_app/banner_ad"` and creates `AdView(activity)` with the real
 * `Activity` context so Google AdMob's Collapsible Banner (`collapsible: bottom`) expands into
 * the half-screen overlay with the circular `⌄` collapse button (`orig_home_after_ad.png`).
 */
class DualAppBannerFactory(
    private val messenger: BinaryMessenger,
    private val activityProvider: () -> Activity,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?>
        return DualAppBannerPlatformView(
            context = context,
            activity = activityProvider(),
            messenger = messenger,
            viewId = viewId,
            params = params,
        )
    }
}

class DualAppBannerPlatformView(
    context: Context,
    activity: Activity,
    messenger: BinaryMessenger,
    viewId: Int,
    params: Map<String, Any?>?,
) : PlatformView {

    private val rootLayout = RelativeLayout(context)
    private val channel = MethodChannel(messenger, "com.example.dual_app/banner_ad/$viewId")
    private var adView: AdView? = null

    init {
        channel.setMethodCallHandler { _, result -> result.notImplemented() }

        val adUnitId = (params?.get("adUnitId") as? String)?.trim().orEmpty()
        val isCollapsible = (params?.get("isCollapsible") as? Boolean) ?: false
        val requestedWidthDp = (params?.get("widthDp") as? Number)?.toInt() ?: 0

        if (adUnitId.isEmpty()) {
            channel.invokeMethod(
                "adStatus",
                mapOf("available" to false, "error" to "Empty adUnitId"),
            )
        } else {
            val frameLayout = FrameLayout(activity)
            val lp = RelativeLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                addRule(RelativeLayout.CENTER_IN_PARENT)
            }
            rootLayout.addView(frameLayout, lp)

            val displayMetrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            activity.windowManager.defaultDisplay.getMetrics(displayMetrics)
            val density = if (displayMetrics.density > 0f) displayMetrics.density else 1f
            val widthDp = if (requestedWidthDp > 0) {
                requestedWidthDp
            } else {
                (displayMetrics.widthPixels / density).toInt().coerceAtLeast(320)
            }

            val adSize = AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, widthDp)
            val banner = AdView(activity).apply {
                this.adUnitId = adUnitId
                setAdSize(adSize)
            }
            adView = banner

            frameLayout.removeAllViews()
            frameLayout.addView(
                banner,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    Gravity.CENTER,
                ),
            )

            val adRequest = if (isCollapsible) {
                val bundle = Bundle().apply {
                    putString("collapsible", "bottom")
                }
                AdRequest.Builder()
                    .addNetworkExtrasBundle(AdMobAdapter::class.java, bundle)
                    .build()
            } else {
                AdRequest.Builder().build()
            }

            banner.adListener = object : AdListener() {
                override fun onAdLoaded() {
                    val actualSize = banner.adSize ?: adSize
                    channel.invokeMethod(
                        "adStatus",
                        mapOf(
                            "available" to true,
                            "widthDp" to actualSize.width,
                            "heightDp" to actualSize.height,
                        ),
                    )
                }

                override fun onAdFailedToLoad(error: LoadAdError) {
                    channel.invokeMethod(
                        "adStatus",
                        mapOf(
                            "available" to false,
                            "error" to error.message,
                        ),
                    )
                }
            }

            banner.loadAd(adRequest)
        }
    }

    override fun getView(): View = rootLayout

    override fun dispose() {
        channel.setMethodCallHandler(null)
        rootLayout.removeAllViews()
        adView?.let { banner ->
            (banner.parent as? ViewGroup)?.removeView(banner)
            banner.removeAllViews()
            banner.destroy()
        }
        adView = null
    }
}
