package com.weappsinc.webscanerpro.ads

import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
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
 * a full-width overlay with the circular `⌄` collapse button (`orig_home_after_ad.png`).
 */
class DualAppBannerFactory(
    private val messenger: BinaryMessenger,
    private val activityProvider: () -> Activity,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?>
        return DualAppBannerPlatformView(
            activity = activityProvider(),
            messenger = messenger,
            viewId = viewId,
            params = params,
        )
    }
}

class DualAppBannerPlatformView(
    private val activity: Activity,
    messenger: BinaryMessenger,
    viewId: Int,
    params: Map<String, Any?>?,
) : PlatformView {

    // Always use the real Activity context (not a VirtualDisplay context) so AdMob's
    // Collapsible Banner PopupWindow measures full window bounds accurately.
    private val rootLayout = FrameLayout(activity).apply {
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        )
    }
    private val channel = MethodChannel(messenger, "com.example.dual_app/banner_ad/$viewId")
    private var adView: AdView? = null
    private var disposed = false
    private val isCollapsible: Boolean = (params?.get("isCollapsible") as? Boolean) ?: false

    init {
        channel.setMethodCallHandler { _, result -> result.notImplemented() }

        val adUnitId = (params?.get("adUnitId") as? String)?.trim().orEmpty()

        if (adUnitId.isEmpty()) {
            channel.invokeMethod(
                "adStatus",
                mapOf("available" to false, "error" to "Empty adUnitId"),
            )
        } else {
            if (isCollapsible) {
                // Ensure any previous collapsible banner popup is dismissed before creating a new one
                activeCollapsibleView?.let { prev ->
                    if (prev !== this) {
                        prev.destroyBannerOnly()
                    }
                }
                activeCollapsibleView = this
            }

            val displayMetrics = activity.resources.displayMetrics
            val density = if (displayMetrics.density > 0f) displayMetrics.density else 1f
            val screenWidthDp = (displayMetrics.widthPixels / density).toInt().coerceAtLeast(320)

            val adSize = AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, screenWidthDp)
            val banner = AdView(activity).apply {
                this.adUnitId = adUnitId
                setAdSize(adSize)
            }
            adView = banner

            rootLayout.removeAllViews()
            rootLayout.addView(
                banner,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL,
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
                    if (disposed) return
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
                    if (disposed) return
                    channel.invokeMethod(
                        "adStatus",
                        mapOf(
                            "available" to false,
                            "error" to error.message,
                        ),
                    )
                }
            }

            // Defer loadAd until rootLayout is attached and laid out in the Activity window
            // so AdMob's Collapsible Banner PopupWindow anchors to full screen width.
            rootLayout.post {
                if (!disposed && adView === banner) {
                    banner.loadAd(adRequest)
                }
            }
        }
    }

    internal fun destroyBannerOnly() {
        rootLayout.removeAllViews()
        adView?.let { banner ->
            (banner.parent as? ViewGroup)?.removeView(banner)
            banner.removeAllViews()
            banner.destroy()
        }
        adView = null
    }

    override fun getView(): View = rootLayout

    override fun dispose() {
        disposed = true
        if (activeCollapsibleView === this) {
            activeCollapsibleView = null
        }
        channel.setMethodCallHandler(null)
        destroyBannerOnly()
    }

    companion object {
        @Volatile
        private var activeCollapsibleView: DualAppBannerPlatformView? = null
    }
}
