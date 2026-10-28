package com.weappsinc.webscanerpro.web

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.net.Uri
import android.net.http.SslError
import android.webkit.SslErrorHandler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient

class SessionWebClient(
    private val activity: Activity,
    private val status: (String) -> Unit,
    private val pageReady: () -> Unit,
) : WebViewClient() {
    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
        val uri = request.url
        if (!request.isForMainFrame) return false
        val host = uri.host.orEmpty()
        if (uri.scheme == "https" && (host == "whatsapp.com" || host.endsWith(".whatsapp.com"))) return false
        if (uri.scheme == "https" && request.hasGesture()) confirmExternalLink(uri)
        else status("Liên kết này không được mở trong phiên web.")
        return true
    }

    private fun confirmExternalLink(uri: Uri) {
        AlertDialog.Builder(activity).setTitle("Mở trình duyệt ngoài?")
            .setMessage(uri.host ?: "Liên kết ngoài")
            .setNegativeButton("Hủy", null).setPositiveButton("Mở") { _, _ ->
                try { activity.startActivity(Intent(Intent.ACTION_VIEW, uri)) }
                catch (_: Exception) { status("Không tìm thấy trình duyệt để mở liên kết.") }
            }.show()
    }

    override fun onPageFinished(view: WebView, url: String) {
        pageReady()
    }

    override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
        if (request.isForMainFrame) status("Không tải được WhatsApp Web. Kiểm tra mạng rồi chọn Tải lại.")
    }

    override fun onReceivedSslError(view: WebView, handler: SslErrorHandler, error: SslError) {
        handler.cancel()
        status("Kết nối không an toàn. Trang đã bị chặn.")
    }
}
