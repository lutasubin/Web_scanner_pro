package com.example.web_scanner_pro.ads

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.example.web_scanner_pro.R
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import io.flutter.plugins.googlemobileads.NativeAdFactory
import java.lang.ref.WeakReference

/**
 * Mirrors original app's `jc/g.java` + `jc/a.java` mapping the 6 Native Ad XML templates:
 * - adFactoryStyle1 -> R.layout.ad_native              (Large with MediaView 120dp + Bottom Solid CTA)
 * - adFactoryStyle2 -> R.layout.ad_native_small        (Compact Row + Right Solid Green CTA)
 * - adFactoryStyle3 -> R.layout.ad_native_small_hollow (Compact Row + Right Hollow Outlined CTA)
 * - adFactoryStyle4 -> R.layout.ad_native_btn_top      (Medium No-Media + Top Solid Green CTA)
 * - adFactoryStyle5 -> R.layout.ad_native_btn_bottom   (Medium No-Media + Bottom Solid Green CTA)
 * - adFactoryStyle6 -> R.layout.ad_native_collab       (Collapsible Native Ad: Expanded Large Media <-> Collapsed Small Row)
 */
class WebScannerNativeAdFactory(
    private val layoutInflater: LayoutInflater,
    private val layoutResId: Int,
) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = layoutInflater.inflate(layoutResId, null) as NativeAdView

        adView.mediaView = adView.findViewById<MediaView?>(R.id.ad_media)
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        val mainCta = adView.findViewById<Button?>(R.id.ad_call_to_action)
        val smallCta = adView.findViewById<Button?>(R.id.ad_call_to_action_small)
        adView.callToActionView = mainCta
        adView.iconView = adView.findViewById(R.id.ad_app_icon)

        (adView.headlineView as? TextView)?.text = nativeAd.headline ?: ""

        adView.mediaView?.let { mediaView ->
            val mediaContent = nativeAd.mediaContent
            if (mediaContent != null) {
                mediaView.mediaContent = mediaContent
                mediaView.visibility = View.VISIBLE
            } else {
                mediaView.visibility = View.GONE
            }
        }

        (adView.bodyView as? TextView)?.let { bodyView ->
            val body = nativeAd.body
            if (body.isNullOrBlank()) {
                bodyView.visibility = View.INVISIBLE
            } else {
                bodyView.visibility = View.VISIBLE
                bodyView.text = body
            }
        }

        val ctaText = nativeAd.callToAction
        mainCta?.let { ctaView ->
            if (ctaText.isNullOrBlank()) {
                ctaView.visibility = View.INVISIBLE
            } else {
                ctaView.visibility = View.VISIBLE
                ctaView.text = ctaText
            }
        }
        smallCta?.let { compactBtn ->
            compactBtn.text = ctaText ?: ""
            compactBtn.visibility = View.GONE
            compactBtn.setOnClickListener {
                mainCta?.performClick()
            }
        }

        (adView.iconView as? ImageView)?.let { iconView ->
            val iconDrawable =
                nativeAd.icon?.drawable ?: nativeAd.images.firstOrNull()?.drawable
            if (iconDrawable == null) {
                iconView.visibility = View.GONE
            } else {
                iconView.setImageDrawable(iconDrawable)
                iconView.visibility = View.VISIBLE
            }
        }

        adView.setNativeAd(nativeAd)
        if (layoutResId == R.layout.ad_native_collab) {
            synchronized(collabViews) {
                collabViews.removeAll { it.get() == null }
                collabViews.add(WeakReference(adView))
            }
        }
        return adView
    }

    companion object {
        private val collabViews = mutableListOf<WeakReference<NativeAdView>>()

        private val STYLE_LAYOUTS = mapOf(
            "adFactoryStyle1" to R.layout.ad_native,
            "adFactoryStyle2" to R.layout.ad_native_small,
            "adFactoryStyle3" to R.layout.ad_native_small_hollow,
            "adFactoryStyle4" to R.layout.ad_native_btn_top,
            "adFactoryStyle5" to R.layout.ad_native_btn_bottom,
            "adFactoryStyle6" to R.layout.ad_native_collab,
        )

        fun setCollabCollapsed(collapsed: Boolean) {
            synchronized(collabViews) {
                val iterator = collabViews.iterator()
                while (iterator.hasNext()) {
                    val adView = iterator.next().get()
                    if (adView == null) {
                        iterator.remove()
                        continue
                    }
                    val mediaView = adView.findViewById<View?>(R.id.ad_media)
                    val mainCta = adView.findViewById<Button?>(R.id.ad_call_to_action)
                    val smallCta = adView.findViewById<Button?>(R.id.ad_call_to_action_small)
                    if (collapsed) {
                        mediaView?.visibility = View.GONE
                        mainCta?.visibility = View.GONE
                        smallCta?.visibility = View.VISIBLE
                        if (smallCta != null) {
                            adView.callToActionView = smallCta
                        }
                    } else {
                        mediaView?.visibility = View.VISIBLE
                        mainCta?.visibility = View.VISIBLE
                        smallCta?.visibility = View.GONE
                        if (mainCta != null) {
                            adView.callToActionView = mainCta
                        }
                    }
                    adView.requestLayout()
                }
            }
        }

        fun registerAll(flutterEngine: FlutterEngine, layoutInflater: LayoutInflater) {
            for ((factoryId, layoutRes) in STYLE_LAYOUTS) {
                GoogleMobileAdsPlugin.registerNativeAdFactory(
                    flutterEngine,
                    factoryId,
                    WebScannerNativeAdFactory(layoutInflater, layoutRes),
                )
            }
        }

        fun unregisterAll(flutterEngine: FlutterEngine) {
            for (factoryId in STYLE_LAYOUTS.keys) {
                GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, factoryId)
            }
        }
    }
}
