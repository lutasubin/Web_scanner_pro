package com.example.web_scanner_pro.web

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.webkit.JavascriptInterface
import android.webkit.URLUtil
import android.webkit.WebView
import com.example.web_scanner_pro.media.OwnedDownloads
import com.example.web_scanner_pro.media.PendingDownload
import com.example.web_scanner_pro.media.StatusFolders
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/** Saves explicit WebView downloads into the app-owned MediaStore folder. */
internal class WebDownloadHandler(
    context: Context,
    private val status: (String) -> Unit,
) {
    private val appContext = context.applicationContext
    private val downloads = OwnedDownloads(appContext)
    private val main = Handler(Looper.getMainLooper())
    private val token = UUID.randomUUID().toString()
    private val blobs = ConcurrentHashMap<String, BlobTransfer>()

    fun attach(view: WebView) {
        view.addJavascriptInterface(this, BRIDGE_NAME)
    }

    fun detach(view: WebView) {
        blobs.values.forEach { it.target.abort() }
        blobs.clear()
        view.removeJavascriptInterface(BRIDGE_NAME)
    }

    fun download(
        view: WebView,
        url: String,
        userAgent: String?,
        contentDisposition: String?,
        mimeType: String?,
        contentLength: Long,
    ) {
        val name = URLUtil.guessFileName(url, contentDisposition, mimeType)
        when {
            url.startsWith("blob:") || url.startsWith("data:") -> {
                post("Đang lưu $name…")
                view.evaluateJavascript(blobScript(url, name, mimeType, contentLength), null)
            }
            url.startsWith("https://") -> {
                val cookie = SessionWebConfiguration.cookiesFor(view, url)
                val referer = view.url
                post("Đang tải $name…")
                executor.execute {
                    downloadHttps(url, userAgent, cookie, referer, contentDisposition, mimeType)
                }
            }
            else -> post("Liên kết tải xuống không an toàn hoặc không được hỗ trợ.")
        }
    }

    private fun downloadHttps(
        url: String,
        userAgent: String?,
        cookie: String?,
        referer: String?,
        originalDisposition: String?,
        originalMimeType: String?,
    ) {
        var connection: HttpURLConnection? = null
        var target: PendingDownload? = null
        try {
            connection = (URL(url).openConnection() as HttpURLConnection).apply {
                instanceFollowRedirects = true
                connectTimeout = 20_000
                readTimeout = 60_000
                requestMethod = "GET"
                userAgent?.takeIf { it.isNotBlank() }?.let { setRequestProperty("User-Agent", it) }
                cookie?.takeIf { it.isNotBlank() }?.let { setRequestProperty("Cookie", it) }
                referer?.takeIf { it.startsWith("https://") }?.let { setRequestProperty("Referer", it) }
            }
            val code = connection.responseCode
            if (code !in 200..299) throw IOException("HTTP $code")
            val mime = connection.contentType?.substringBefore(';')?.trim()
                ?.takeIf { it.isNotBlank() } ?: originalMimeType.orEmpty()
            val disposition = connection.getHeaderField("Content-Disposition") ?: originalDisposition
            val name = URLUtil.guessFileName(connection.url.toString(), disposition, mime)
            target = downloads.open(name, mime)
            connection.inputStream.use { input ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE * 8)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    if (Thread.currentThread().isInterrupted) throw IOException("Download interrupted")
                    target.write(if (count == buffer.size) buffer else buffer.copyOf(count))
                }
            }
            target.publish()
            post("Đã tải $name vào Downloads/WebScannerPro.")
        } catch (_: Exception) {
            target?.abort()
            post("Không tải được tệp. Kiểm tra kết nối rồi thử lại.")
        } finally {
            connection?.disconnect()
        }
    }

    @JavascriptInterface
    fun begin(secret: String, name: String, mimeType: String): String {
        if (secret != token) return ""
        return try {
            val id = UUID.randomUUID().toString()
            blobs[id] = BlobTransfer(name, downloads.open(name, mimeType))
            id
        } catch (_: Exception) {
            post("Không tạo được tệp tải xuống. Kiểm tra bộ nhớ rồi thử lại.")
            ""
        }
    }

    @JavascriptInterface
    fun write(secret: String, id: String, encoded: String): Boolean {
        if (secret != token) return false
        return try {
            val bytes = Base64.decode(encoded, Base64.DEFAULT)
            blobs[id]?.target?.write(bytes) ?: throw IOException("Unknown blob transfer")
            true
        } catch (_: Exception) {
            fail(secret, id, "write")
            false
        }
    }

    @JavascriptInterface
    fun finish(secret: String, id: String) {
        if (secret != token) return
        val transfer = blobs.remove(id) ?: return
        try {
            transfer.target.publish()
            post("Đã tải ${transfer.name} vào Downloads/WebScannerPro.")
        } catch (_: Exception) {
            transfer.target.abort()
            post("Không hoàn tất được tệp tải xuống.")
        }
    }

    @JavascriptInterface
    fun fail(secret: String, id: String, reason: String) {
        if (secret != token) return
        if (id.isNotBlank()) blobs.remove(id)?.target?.abort()
        post("Không tải được tệp từ phiên web. Hãy thử lại.")
    }

    @JavascriptInterface
    fun saveDataUrl(dataUrl: String, keyHint: String, cacheOnly: Boolean): Boolean {
        if (!dataUrl.startsWith("data:")) return false
        val commaIndex = dataUrl.indexOf(',')
        if (commaIndex <= 5) return false
        val header = dataUrl.substring(5, commaIndex)
        val mimeType = header.substringBefore(';').trim().lowercase().ifBlank { "image/jpeg" }
        val isMedia = mimeType.startsWith("image/") || mimeType.startsWith("video/")
        if (!isMedia) return false
        val payload = dataUrl.substring(commaIndex + 1)
        executor.execute {
            try {
                val bytes = Base64.decode(payload, Base64.DEFAULT)
                if (bytes.isEmpty()) return@execute
                val ext = when {
                    mimeType.contains("mp4") || mimeType.startsWith("video/") -> "mp4"
                    mimeType.contains("png") -> "png"
                    mimeType.contains("webp") -> "webp"
                    mimeType.contains("gif") -> "gif"
                    else -> "jpg"
                }
                val digest = MessageDigest.getInstance("SHA-1").digest(bytes)
                    .take(8)
                    .joinToString("") { "%02x".format(it) }
                val fileName = "status_$digest.$ext"
                val cacheFile = File(StatusFolders.webStatusDir(appContext), fileName)
                if (!cacheFile.exists() || cacheFile.length() != bytes.size.toLong()) {
                    cacheFile.writeBytes(bytes)
                }
                if (!cacheOnly) {
                    val target = downloads.open(fileName, mimeType)
                    try {
                        target.write(bytes)
                        target.publish()
                        post("Đã lưu trạng thái ($fileName) vào mục Đã lưu & Tải xuống.")
                    } catch (e: Exception) {
                        target.abort()
                        throw e
                    }
                }
            } catch (_: Exception) {
                if (!cacheOnly) {
                    post("Không lưu được trạng thái. Hãy thử lại.")
                }
            }
        }
        return true
    }

    private fun blobScript(url: String, name: String, mimeType: String?, length: Long): String {
        val source = JSONObject.quote(url)
        val fileName = JSONObject.quote(name)
        val type = JSONObject.quote(mimeType.orEmpty())
        val secret = JSONObject.quote(token)
        return """
            (function() {
              var bridge = window.$BRIDGE_NAME;
              if (!bridge) return;
              fetch($source).then(function(response) { return response.blob(); }).then(function(blob) {
                var id = bridge.begin($secret, $fileName, blob.type || $type || 'application/octet-stream');
                if (!id) throw new Error('create');
                var offset = 0;
                var chunkSize = $BLOB_CHUNK_SIZE;
                function next() {
                  if (offset >= blob.size) { bridge.finish($secret, id); return; }
                  var end = Math.min(offset + chunkSize, blob.size);
                  var reader = new FileReader();
                  reader.onload = function() {
                    try {
                      var value = String(reader.result || '');
                      if (!bridge.write($secret, id, value.substring(value.indexOf(',') + 1))) return;
                      offset = end;
                      setTimeout(next, 0);
                    } catch (error) { bridge.fail($secret, id, String(error)); }
                  };
                  reader.onerror = function() { bridge.fail($secret, id, 'read'); };
                  reader.readAsDataURL(blob.slice(offset, end));
                }
                if (blob.size === 0 && $length > 0) {
                  bridge.fail($secret, id, 'empty');
                } else {
                  next();
                }
              }).catch(function(error) { bridge.fail($secret, '', String(error)); });
            })();
        """.trimIndent()
    }

    private fun post(message: String) {
        main.post { status(message) }
    }

    private data class BlobTransfer(val name: String, val target: PendingDownload)

    companion object {
        private const val BRIDGE_NAME = "WebScannerDownloads"
        private const val BLOB_CHUNK_SIZE = 192 * 1024
        private val executor = Executors.newFixedThreadPool(2)
    }
}
