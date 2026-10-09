package com.example.web_scanner_pro.web

import android.annotation.SuppressLint
import android.app.Activity
import android.content.pm.ApplicationInfo
import android.webkit.CookieManager
import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.widget.Toast
import androidx.webkit.WebViewCompat

object SessionWebConfiguration {
    @SuppressLint("SetJavaScriptEnabled", "RequiresFeature")
    fun configure(
        view: WebView,
        activity: Activity,
        status: (String) -> Unit,
        progress: (Int) -> Unit,
        pageReady: () -> Unit,
    ) {
        view.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            cacheMode = WebSettings.LOAD_DEFAULT
            allowFileAccess = false
            allowContentAccess = false
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            safeBrowsingEnabled = true
            setSupportMultipleWindows(false)
            javaScriptCanOpenWindowsAutomatically = true
            mediaPlaybackRequiresUserGesture = false
            loadWithOverviewMode = true
            useWideViewPort = true
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
            userAgentString = DESKTOP_USER_AGENT
        }
        if (activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            WebView.setWebContentsDebuggingEnabled(true)
        }
        configureCookies(view)
        view.webViewClient = SessionWebClient(activity, status, pageReady)
        view.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(webView: WebView?, newProgress: Int) {
                progress(newProgress)
            }
            override fun onPermissionRequest(request: PermissionRequest) {
                request.deny()
                notice(activity, "Base chưa hỗ trợ camera, micro và gọi điện trong phiên web.")
            }
            override fun onShowFileChooser(webView: WebView?, callback: android.webkit.ValueCallback<Array<android.net.Uri>>?,
                params: FileChooserParams?): Boolean {
                callback?.onReceiveValue(null)
                notice(activity, "Base chưa hỗ trợ tải tệp lên WhatsApp Web.")
                return true
            }
        }
        view.setDownloadListener { _, _, _, _, _ ->
            notice(activity, "Base chưa hỗ trợ tải tệp từ phiên web. Bạn có thể lưu Status từ thư mục đã cấp quyền.")
        }
    }

    private fun configureCookies(view: WebView) {
        val cookies = cookieManager(view)
        cookies.setAcceptCookie(true)
        cookies.setAcceptThirdPartyCookies(view, true)
        cookies.flush()
    }

    fun flushCookies(view: WebView) = cookieManager(view).flush()

    private fun cookieManager(view: WebView): CookieManager =
        if (WebBridge.supportsProfiles()) {
            WebViewCompat.getProfile(view).cookieManager
        } else {
            CookieManager.getInstance()
        }

    private fun notice(activity: Activity, text: String) {
        Toast.makeText(activity, text, Toast.LENGTH_LONG).show()
    }

    private const val DESKTOP_USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) " +
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"
}
