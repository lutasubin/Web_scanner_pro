package com.weappsinc.webscanerpro.ads

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.weappsinc.webscanerpro.R
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdLoader
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.VideoOptions
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdOptions
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Mirrors original app's `yl/e.java` + `yl/d.java` + `yl/i.java` + `xf/b.java` + `jc/g.java` + `jc/a.java`:
 * - Maintains a shared 3-ad preload queue (`MAX_CACHE = 3`) of raw `NativeAd` objects.
 * - Uses `VideoOptions(startMuted = true, customControlsRequested = false)` and
 *   `NativeAdOptions(ADCHOICES_TOP_RIGHT)` just like `yl/d.java:46-53`.
 * - Inflates the exact XML template (`jc.a.a[style - 1]`) and binds via `bindNativeAdView` (`jc/g.java`)
 *   at the moment `com.example.dual_app/native_ad` (`jc/h.java`) is displayed.
 */
object DualAppNativeAdManager {
    const val MAX_CACHE = 3

    // Exact layout array matching `jc/a.java` (`Integer[] a = {ad_native, ad_native_small, ad_native_small_hollow, ad_native_btn_top, ad_native_btn_bottom}`) + style 6 collab
    val LAYOUT_RES_IDS = intArrayOf(
        R.layout.ad_native,
        R.layout.ad_native_small,
        R.layout.ad_native_small_hollow,
        R.layout.ad_native_btn_top,
        R.layout.ad_native_btn_bottom,
        R.layout.ad_native_collab,
    )

    private data class CachedNativeAd(
        val ad: NativeAd,
        val unitId: String,
        val loadedAtMs: Long = System.currentTimeMillis(),
        val ttlMs: Long = 3_600_000L, // 1 hour expiry (`yl/i.java:132`)
    ) {
        val isExpired: Boolean
            get() = System.currentTimeMillis() - loadedAtMs > ttlMs
    }

    private data class PendingRequest(
        val adUnitId: String,
        val fallbackAdUnitId: String,
        val onResult: (NativeAd?, String?) -> Unit,
    )

    private val mainHandler = Handler(Looper.getMainLooper())
    private val cacheQueue = ArrayList<CachedNativeAd>()
    private val pendingConsumers = CopyOnWriteArrayList<PendingRequest>()
    private var inFlightLoads = 0
    private var primaryAdUnitId: String = "ca-app-pub-3940256099942544/2247696110"
    private var fallbackAdUnitId: String = "ca-app-pub-3940256099942544/1044960115"
    private var appContext: Context? = null

    fun configureAndPreload(
        context: Context,
        adUnitId: String,
        fallbackUnitId: String = "ca-app-pub-3940256099942544/1044960115",
    ) {
        mainHandler.post {
            appContext = context.applicationContext
            val trimmedPrimary = adUnitId.trim()
            val trimmedFallback = fallbackUnitId.trim()
            if (trimmedPrimary.isNotEmpty()) {
                primaryAdUnitId = trimmedPrimary
            }
            if (trimmedFallback.isNotEmpty()) {
                fallbackAdUnitId = trimmedFallback
            }
            replenishQueue()
        }
    }

    fun cachedCount(): Int {
        synchronized(cacheQueue) {
            pruneExpiredLocked()
            return cacheQueue.size
        }
    }

    fun clearCache() {
        synchronized(cacheQueue) {
            for (item in cacheQueue) {
                item.ad.destroy()
            }
            cacheQueue.clear()
        }
    }

    private fun pruneExpiredLocked() {
        val iterator = cacheQueue.iterator()
        while (iterator.hasNext()) {
            val item = iterator.next()
            if (item.isExpired) {
                item.ad.destroy()
                iterator.remove()
            }
        }
    }

    fun acquireNativeAd(
        context: Context,
        requestedAdUnitId: String,
        requestedFallbackUnitId: String,
        onResult: (NativeAd?, String?) -> Unit,
    ) {
        mainHandler.post {
            appContext = context.applicationContext
            val targetUnitId = requestedAdUnitId.trim().ifEmpty { primaryAdUnitId }
            val targetFallbackId = requestedFallbackUnitId.trim().ifEmpty { fallbackAdUnitId }

            var popped: NativeAd? = null
            synchronized(cacheQueue) {
                pruneExpiredLocked()
                val matchIdx = cacheQueue.indexOfFirst { it.unitId == targetUnitId }
                if (matchIdx >= 0) {
                    popped = cacheQueue.removeAt(matchIdx).ad
                } else if (cacheQueue.isNotEmpty() && targetUnitId == primaryAdUnitId) {
                    popped = cacheQueue.removeAt(0).ad
                }
            }

            if (popped != null) {
                // Immediately trigger background replenish (`xf/b.java:600-601` -> `eVar.k(fm.k.f)`)
                replenishQueue()
                onResult(popped, null)
            } else {
                pendingConsumers.add(
                    PendingRequest(
                        adUnitId = targetUnitId,
                        fallbackAdUnitId = targetFallbackId,
                        onResult = onResult,
                    ),
                )
                loadSingleNativeAd(
                    context = context.applicationContext,
                    unitId = targetUnitId,
                    fallbackId = targetFallbackId,
                    isFallbackRetry = false,
                )
            }
        }
    }

    fun replenishQueue() {
        mainHandler.post {
            val ctx = appContext ?: return@post
            val currentSize = cachedCount()
            val needed = (MAX_CACHE + pendingConsumers.size) - (currentSize + inFlightLoads)
            if (needed <= 0 || primaryAdUnitId.isEmpty()) return@post

            val toStart = needed.coerceAtMost(MAX_CACHE)
            for (i in 0 until toStart) {
                loadSingleNativeAd(
                    context = ctx,
                    unitId = primaryAdUnitId,
                    fallbackId = fallbackAdUnitId,
                    isFallbackRetry = false,
                )
            }
        }
    }

    private fun loadSingleNativeAd(
        context: Context,
        unitId: String,
        fallbackId: String,
        isFallbackRetry: Boolean,
    ) {
        if (unitId.isEmpty()) return
        inFlightLoads++

        // Exact VideoOptions & NativeAdOptions from `yl/d.java:46-53`
        val videoOptions = VideoOptions.Builder()
            .setCustomControlsRequested(false)
            .setStartMuted(true)
            .build()

        val nativeAdOptions = NativeAdOptions.Builder()
            .setAdChoicesPlacement(NativeAdOptions.ADCHOICES_TOP_RIGHT)
            .setVideoOptions(videoOptions)
            .build()

        val adLoader = AdLoader.Builder(context, unitId)
            .withNativeAdOptions(nativeAdOptions)
            .forNativeAd { nativeAd ->
                mainHandler.post {
                    inFlightLoads = (inFlightLoads - 1).coerceAtLeast(0)
                    if (pendingConsumers.isNotEmpty()) {
                        val matchIdx = pendingConsumers.indexOfFirst {
                            it.adUnitId == unitId || (isFallbackRetry && it.fallbackAdUnitId == unitId)
                        }
                        val consumer = if (matchIdx >= 0) {
                            pendingConsumers.removeAt(matchIdx)
                        } else {
                            pendingConsumers.removeAt(0)
                        }
                        consumer.onResult(nativeAd, null)
                    } else {
                        synchronized(cacheQueue) {
                            pruneExpiredLocked()
                            if (cacheQueue.size < MAX_CACHE) {
                                cacheQueue.add(CachedNativeAd(nativeAd, unitId))
                            } else {
                                nativeAd.destroy()
                            }
                        }
                    }
                    // Continue filling up to MAX_CACHE = 3 (`yl/e.java`)
                    if (cachedCount() + inFlightLoads < MAX_CACHE) {
                        replenishQueue()
                    }
                }
            }
            .withAdListener(
                object : AdListener() {
                    override fun onAdFailedToLoad(error: LoadAdError) {
                        mainHandler.post {
                            inFlightLoads = (inFlightLoads - 1).coerceAtLeast(0)
                            if (!isFallbackRetry && fallbackId.isNotEmpty() && fallbackId != unitId) {
                                loadSingleNativeAd(
                                    context = context,
                                    unitId = fallbackId,
                                    fallbackId = fallbackId,
                                    isFallbackRetry = true,
                                )
                                return@post
                            }
                            if (pendingConsumers.isNotEmpty() && inFlightLoads == 0 && cachedCount() == 0) {
                                val snapshot = ArrayList(pendingConsumers)
                                pendingConsumers.clear()
                                for (consumer in snapshot) {
                                    consumer.onResult(null, error.message)
                                }
                            }
                        }
                    }
                },
            )
            .build()

        adLoader.loadAd(AdRequest.Builder().build())
    }

    /**
     * Exact port of `jc/g.java:17-84` (`jc.g.a(nativeAdView, nativeAd)`).
     */
    fun bindNativeAdView(nativeAdView: NativeAdView, nativeAd: NativeAd, isCollabCollapsed: Boolean = false) {
        val mediaView = nativeAdView.findViewById<MediaView?>(R.id.ad_media)
        val headlineView = nativeAdView.findViewById<TextView?>(R.id.ad_headline)
        val bodyView = nativeAdView.findViewById<TextView?>(R.id.ad_body)
        val mainCta = nativeAdView.findViewById<Button?>(R.id.ad_call_to_action)
        val smallCta = nativeAdView.findViewById<Button?>(R.id.ad_call_to_action_small)
        val iconView = nativeAdView.findViewById<ImageView?>(R.id.ad_app_icon)

        nativeAdView.mediaView = mediaView
        nativeAdView.headlineView = headlineView
        nativeAdView.bodyView = bodyView
        nativeAdView.callToActionView = if (isCollabCollapsed && smallCta != null) smallCta else mainCta
        nativeAdView.iconView = iconView

        headlineView?.text = nativeAd.headline ?: ""

        if (mediaView != null) {
            val mediaContent = nativeAd.mediaContent
            if (mediaContent != null) {
                mediaView.mediaContent = mediaContent
            }
            mediaView.visibility = if (isCollabCollapsed) View.GONE else View.VISIBLE
        }

        if (bodyView != null) {
            val body = nativeAd.body
            bodyView.visibility = if (body == null) View.INVISIBLE else View.VISIBLE
            if (body != null) {
                bodyView.text = body
            }
        }

        val ctaText = nativeAd.callToAction
        if (mainCta != null) {
            if (isCollabCollapsed && smallCta != null) {
                mainCta.visibility = View.GONE
            } else {
                mainCta.visibility = if (ctaText == null) View.INVISIBLE else View.VISIBLE
                if (ctaText != null) {
                    mainCta.text = ctaText
                }
            }
        }
        if (smallCta != null) {
            smallCta.text = ctaText ?: ""
            smallCta.visibility = if (isCollabCollapsed) View.VISIBLE else View.GONE
        }

        if (iconView != null) {
            val iconDrawable = nativeAd.icon?.drawable ?: nativeAd.images.firstOrNull()?.drawable
            if (iconDrawable != null) {
                iconView.visibility = View.VISIBLE
                iconView.setImageDrawable(iconDrawable)
            } else if (iconView.background != null) {
                iconView.visibility = View.VISIBLE
            } else {
                iconView.visibility = View.GONE
            }
        }

        (nativeAdView.priceView as? TextView)?.let { priceView ->
            val price = nativeAd.price
            priceView.visibility = if (price == null) View.INVISIBLE else View.VISIBLE
            if (price != null) priceView.text = price
        }

        (nativeAdView.storeView as? TextView)?.let { storeView ->
            val store = nativeAd.store
            storeView.visibility = if (store == null) View.INVISIBLE else View.VISIBLE
            if (store != null) storeView.text = store
        }

        (nativeAdView.starRatingView as? RatingBar)?.let { starRatingView ->
            val rating = nativeAd.starRating
            starRatingView.visibility = if (rating == null) View.INVISIBLE else View.VISIBLE
            if (rating != null) starRatingView.rating = rating.toFloat()
        }

        (nativeAdView.advertiserView as? TextView)?.let { advertiserView ->
            val advertiser = nativeAd.advertiser
            advertiserView.visibility = if (advertiser != null) View.VISIBLE else View.INVISIBLE
            if (advertiser != null) advertiserView.text = advertiser
        }

        nativeAdView.setNativeAd(nativeAd)
    }
}

class DualAppNativeFactory(
    private val messenger: BinaryMessenger,
    private val activityProvider: () -> Activity,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?>
        return DualAppNativePlatformView(
            context = context,
            activity = activityProvider(),
            messenger = messenger,
            viewId = viewId,
            params = params,
        )
    }
}

/**
 * Mirrors original app's `jc/h.java` + `xf/b.java:590-658`:
 * Inflates `LAYOUT_RES_IDS[style - 1]` into a `FrameLayout`, pops a preloaded `NativeAd`
 * from `DualAppNativeAdManager`, binds via `jc.g.a`, and notifies Flutter via
 * `com.example.dual_app/native_ad/$viewId`.
 */
class DualAppNativePlatformView(
    context: Context,
    private val activity: Activity,
    messenger: BinaryMessenger,
    viewId: Int,
    params: Map<String, Any?>?,
) : PlatformView {

    private val frameLayout = FrameLayout(context)
    private val channel = MethodChannel(messenger, "com.example.dual_app/native_ad/$viewId")
    private var currentNativeAd: NativeAd? = null
    private var currentAdView: NativeAdView? = null
    private var disposed = false

    init {
        val rawStyle = (params?.get("style") as? Number)?.toInt() ?: 2
        val styleIndex = (rawStyle - 1).coerceIn(0, DualAppNativeAdManager.LAYOUT_RES_IDS.size - 1)
        val configOn = (params?.get("configOn") as? Boolean) ?: true
        val adUnitId = (params?.get("adUnitId") as? String)?.trim().orEmpty()
        val fallbackAdUnitId = (params?.get("fallbackAdUnitId") as? String)?.trim().orEmpty()
        val initialCollapsed = (params?.get("collapsed") as? Boolean) ?: false

        channel.setMethodCallHandler { call, result ->
            if (call.method == "setCollapsed") {
                val collapsed = call.argument<Boolean>("collapsed") ?: false
                val adView = currentAdView
                val ad = currentNativeAd
                if (adView != null && ad != null) {
                    DualAppNativeAdManager.bindNativeAdView(adView, ad, isCollabCollapsed = collapsed)
                    adView.requestLayout()
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        if (!configOn || rawStyle <= 0 || adUnitId.isEmpty()) {
            frameLayout.visibility = View.GONE
            channel.invokeMethod(
                "adStatus",
                mapOf("available" to false, "error" to "Disabled by config"),
            )
        } else {
            val layoutRes = DualAppNativeAdManager.LAYOUT_RES_IDS[styleIndex]
            val inflated = LayoutInflater.from(activity).inflate(layoutRes, frameLayout, false) as NativeAdView
            currentAdView = inflated
            frameLayout.visibility = View.VISIBLE
            frameLayout.removeAllViews()
            frameLayout.addView(
                inflated,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                ),
            )

            DualAppNativeAdManager.acquireNativeAd(
                context = activity,
                requestedAdUnitId = adUnitId,
                requestedFallbackUnitId = fallbackAdUnitId,
            ) { nativeAd, errorMsg ->
                if (disposed) {
                    nativeAd?.destroy()
                    return@acquireNativeAd
                }
                if (nativeAd == null) {
                    frameLayout.visibility = View.GONE
                    channel.invokeMethod(
                        "adStatus",
                        mapOf(
                            "available" to false,
                            "error" to (errorMsg ?: "No Ad Available"),
                        ),
                    )
                    return@acquireNativeAd
                }

                currentNativeAd = nativeAd
                val activeView = currentAdView ?: inflated

                DualAppNativeAdManager.bindNativeAdView(
                    nativeAdView = activeView,
                    nativeAd = nativeAd,
                    isCollabCollapsed = (rawStyle == 6 && initialCollapsed),
                )

                channel.invokeMethod(
                    "adStatus",
                    mapOf("available" to true),
                )
            }
        }
    }

    override fun getView(): View = frameLayout

    override fun dispose() {
        disposed = true
        channel.setMethodCallHandler(null)
        frameLayout.removeAllViews()
        currentAdView?.destroy()
        currentAdView = null
        currentNativeAd?.destroy()
        currentNativeAd = null
    }
}
