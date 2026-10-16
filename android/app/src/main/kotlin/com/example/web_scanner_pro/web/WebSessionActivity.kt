package com.example.web_scanner_pro.web

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.app.DownloadManager
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.graphics.Color
import android.provider.MediaStore
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.InputMethodManager
import android.webkit.PermissionRequest
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.app.AlertDialog
import android.text.InputFilter
import android.text.InputType
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.webkit.WebViewCompat
import com.example.web_scanner_pro.R
import java.io.File

class WebSessionActivity : ComponentActivity() {
    var sessionId: String = "personal"
        private set
    private var webView: WebView? = null
    private lateinit var session: StoredWebSession
    private lateinit var message: TextView
    private lateinit var progress: ProgressBar
    private lateinit var qrOverlay: QrLoginOverlay
    private lateinit var phoneOverlay: PhoneLoginOverlay
    private val handler = Handler(Looper.getMainLooper())
    private var readyChecks = 0
    private var pendingMediaRequest: PermissionRequest? = null
    private var pendingMediaResources: Array<String> = emptyArray()
    private var pendingFileCallback: ValueCallback<Array<Uri>>? = null
    private var pendingCapture: Pair<Uri, File>? = null
    private var pendingFileParams: WebChromeClient.FileChooserParams? = null
    private val mediaPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions(),
    ) {
        val request = pendingMediaRequest ?: return@registerForActivityResult
        val resources = pendingMediaResources.filter(::hasAndroidPermissionFor).toTypedArray()
        clearPendingMediaRequest()
        if (resources.isNotEmpty()) {
            request.grant(resources)
        } else {
            request.deny()
            Toast.makeText(
                this,
                "Cần cấp quyền camera hoặc micro để thực hiện cuộc gọi.",
                Toast.LENGTH_LONG,
            ).show()
        }
    }
    private val fileChooserLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) { result ->
        val callback = pendingFileCallback ?: return@registerForActivityResult
        val captured = pendingCapture?.takeIf {
            result.resultCode == Activity.RESULT_OK && it.second.length() > 0L
        }?.first
        val selected = extractSelectedUris(result.resultCode, result.data, captured)
        clearPendingFileRequest()
        callback.onReceiveValue(selected)
        handler.postDelayed({
            webView?.evaluateJavascript(
                "JSON.stringify(Array.from(document.querySelectorAll(\"input[type=file]\")).map(function(i){return {accept:i.accept,multiple:i.multiple,count:i.files?i.files.length:-1};}))",
            ) { state -> Log.i(FILE_CHOOSER_LOG, "inputs=$state") }
        }, 1200)
    }
    private val fileCapturePermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        val params = pendingFileParams
        pendingFileParams = null
        if (granted && params != null) {
            launchFileChooser(params)
        } else {
            val callback = pendingFileCallback
            clearPendingFileRequest()
            callback?.onReceiveValue(null)
            Toast.makeText(
                this,
                "Cần cấp quyền để ghi nội dung từ camera hoặc micro.",
                Toast.LENGTH_LONG,
            ).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sessionId = intent.getStringExtra("id") ?: "personal"
        session = WebSessionStore(this).find(sessionId) ?: run { finish(); return }
        if (SessionProfiles.isResetting(sessionId) ||
            (sessionId != WebSessionStore.DEFAULT_ID && !WebBridge.supportsProfiles())) { finish(); return }
        try {
            window.statusBarColor = Color.WHITE
            window.navigationBarColor = Color.WHITE
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            val view = FixedWidthWebView(this)
            webView = view
            if (WebBridge.supportsProfiles()) WebViewCompat.setProfile(view, SessionProfiles.name(sessionId))
            buildLayout(view)
            SessionWebConfiguration.configure(view, this, ::showMessage,
                ::showProgress, ::waitForWebContent, ::handleMediaPermission,
                ::cancelMediaPermission, ::showFileChooser)
            SessionProfiles.register(this)
            onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    handleWebBack(view)
                }
            })
            view.loadUrl("https://web.whatsapp.com/")
        } catch (_: Exception) {
            Toast.makeText(this, "Không mở được WebView. Hãy cập nhật và thử lại.", Toast.LENGTH_LONG).show()
            finish()
        }
    }

    private fun buildLayout(view: WebView) {
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        root.setOnApplyWindowInsetsListener { target, insets ->
            target.setPadding(insets.systemWindowInsetLeft, insets.systemWindowInsetTop,
                insets.systemWindowInsetRight, insets.systemWindowInsetBottom)
            insets
        }
        val sessions = WebSessionStore(this).list()
        root.addView(WebSessionToolbar(
            this, sessions, sessionId,
            onClose = { handleWebBack(view) },
            onSelect = ::switchSession,
            onAdd = ::showCreateAccount,
            onReload = { view.reload() },
            onKeyboard = { showKeyboard(view) },
            onDownloads = ::openDownloads,
            onHelp = ::showHelp,
        ).build())
        message = TextView(this).apply {
            setPadding(16, 8, 16, 8)
            setBackgroundColor(0xFFFFF8E7.toInt())
            visibility = View.GONE
        }
        root.addView(message)
        progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
            isIndeterminate = true
            contentDescription = getString(R.string.loading_whatsapp)
        }
        root.addView(progress, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
            resources.getDimensionPixelSize(R.dimen.web_progress_height)))
        qrOverlay = QrLoginOverlay(this, ::showHelp) { showPhoneLogin(view) }
        phoneOverlay = PhoneLoginOverlay(
            this,
            onContinue = { submitPhoneNumber(view, it) },
            onQrLogin = { showQrLogin(view) },
            onHelp = ::showHelp,
        ).apply { visibility = View.GONE }
        val content = FrameLayout(this).apply {
            addView(view, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
            addView(qrOverlay, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
            addView(phoneOverlay, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        }
        root.addView(content, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        setContentView(root)
        view.isHorizontalScrollBarEnabled = false
        view.overScrollMode = View.OVER_SCROLL_NEVER
    }

    private fun installMobileLayout(view: WebView) {
        val widthDp = view.width / resources.displayMetrics.density
        // Giữ chữ và hàng chat ở kích thước mobile dễ đọc thay vì thu nhỏ cả
        // trang desktop. Phần chiều rộng mở rộng bù lại mức zoom để không tạo
        // cuộn ngang.
        val scale = (widthDp / 360f).coerceIn(0.9f, 1.18f)
        val expandedWidth = 100f / scale
        view.evaluateJavascript(WebMobileLayout.install(scale, expandedWidth), null)
    }

    private fun handleMediaPermission(request: PermissionRequest) {
        runOnUiThread {
            val origin = request.origin
            if (origin.scheme != "https" || origin.host != "web.whatsapp.com") {
                request.deny()
                return@runOnUiThread
            }

            val supportedResources = request.resources.filter {
                it == PermissionRequest.RESOURCE_AUDIO_CAPTURE ||
                    it == PermissionRequest.RESOURCE_VIDEO_CAPTURE
            }.toTypedArray()
            if (supportedResources.isEmpty()) {
                request.deny()
                return@runOnUiThread
            }

            pendingMediaRequest?.deny()
            clearPendingMediaRequest()

            val missingPermissions = supportedResources.mapNotNull(::androidPermissionFor)
                .filter {
                    ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
                }
                .distinct()
                .toTypedArray()

            if (missingPermissions.isEmpty()) {
                request.grant(supportedResources)
            } else {
                pendingMediaRequest = request
                pendingMediaResources = supportedResources
                mediaPermissionLauncher.launch(missingPermissions)
            }
        }
    }

    private fun cancelMediaPermission(request: PermissionRequest) {
        if (pendingMediaRequest === request) clearPendingMediaRequest()
    }

    private fun androidPermissionFor(resource: String): String? = when (resource) {
        PermissionRequest.RESOURCE_AUDIO_CAPTURE -> Manifest.permission.RECORD_AUDIO
        PermissionRequest.RESOURCE_VIDEO_CAPTURE -> Manifest.permission.CAMERA
        else -> null
    }

    private fun hasAndroidPermissionFor(resource: String): Boolean {
        val permission = androidPermissionFor(resource) ?: return false
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun clearPendingMediaRequest() {
        pendingMediaRequest = null
        pendingMediaResources = emptyArray()
    }

    private fun showFileChooser(
        callback: ValueCallback<Array<Uri>>,
        params: WebChromeClient.FileChooserParams,
    ): Boolean {
        pendingFileCallback?.onReceiveValue(null)
        clearPendingFileRequest()
        pendingFileCallback = callback

        val capturePermission = capturePermissionFor(params)
        if (capturePermission != null &&
            ContextCompat.checkSelfPermission(this, capturePermission) != PackageManager.PERMISSION_GRANTED
        ) {
            pendingFileParams = params
            fileCapturePermissionLauncher.launch(capturePermission)
            return true
        }

        return launchFileChooser(params)
    }

    private fun launchFileChooser(params: WebChromeClient.FileChooserParams): Boolean {
        return try {
            val intent = if (params.isCaptureEnabled) {
                createCaptureIntent(params.acceptTypes) ?: createPickerIntent(params)
            } else {
                createPickerIntent(params)
            }
            fileChooserLauncher.launch(intent)
            true
        } catch (_: ActivityNotFoundException) {
            val callback = pendingFileCallback
            clearPendingFileRequest()
            callback?.onReceiveValue(null)
            Toast.makeText(this, "Không tìm thấy ứng dụng để chọn tệp.", Toast.LENGTH_LONG).show()
            true
        } catch (_: Exception) {
            val callback = pendingFileCallback
            clearPendingFileRequest()
            callback?.onReceiveValue(null)
            Toast.makeText(this, "Chưa mở được trình chọn tệp.", Toast.LENGTH_LONG).show()
            true
        }
    }

    private fun capturePermissionFor(params: WebChromeClient.FileChooserParams): String? {
        if (!params.isCaptureEnabled) return null
        val accepts = params.acceptTypes.joinToString(",").lowercase()
        return if (accepts.contains("audio")) {
            Manifest.permission.RECORD_AUDIO
        } else {
            Manifest.permission.CAMERA
        }
    }

    private fun extractSelectedUris(resultCode: Int, data: Intent?, captured: Uri?): Array<Uri>? {
        if (resultCode != Activity.RESULT_OK) return null
        val rawUris = buildList {
            WebChromeClient.FileChooserParams.parseResult(resultCode, data)
                ?.forEach(::add)
            data?.clipData?.let { clip ->
                for (index in 0 until clip.itemCount) {
                    clip.getItemAt(index).uri?.let(::add)
                }
            }
            data?.data?.let(::add)
            captured?.let(::add)
        }.distinct()
        Log.i(FILE_CHOOSER_LOG, "rawUris=$rawUris flags=${data?.flags}")
        val uris = rawUris.filter { uri ->
            runCatching {
                contentResolver.openFileDescriptor(uri, "r")?.use { descriptor ->
                    descriptor.statSize != 0L
                } == true
            }.onFailure { Log.e(FILE_CHOOSER_LOG, "Cannot verify $uri", it) }
                .getOrDefault(false)
        }
        Log.i(FILE_CHOOSER_LOG, "verifiedUris=$uris")
        // Return the picker-owned content URIs exactly as Android supplied
        // them. Copying them through FileProvider loses the original display
        // name/type on some photo pickers, so Chromium cannot construct the
        // browser File expected by WhatsApp's attachment editor.
        return uris.toTypedArray().takeIf { it.isNotEmpty() }
    }

    private fun createPickerIntent(params: WebChromeClient.FileChooserParams): Intent = try {
        params.createIntent().apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            if (params.mode == WebChromeClient.FileChooserParams.MODE_OPEN_MULTIPLE) {
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
        }
    } catch (_: Exception) {
        Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = params.acceptTypes.firstOrNull { it.isNotBlank() } ?: "*/*"
            putExtra(
                Intent.EXTRA_ALLOW_MULTIPLE,
                params.mode == WebChromeClient.FileChooserParams.MODE_OPEN_MULTIPLE,
            )
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun createCaptureIntent(acceptTypes: Array<String>): Intent? {
        val accepts = acceptTypes.joinToString(",").lowercase()
        if (accepts.contains("audio")) {
            return Intent(MediaStore.Audio.Media.RECORD_SOUND_ACTION)
        }

        val isVideo = accepts.contains("video") && !accepts.contains("image")
        val suffix = if (isVideo) ".mp4" else ".jpg"
        val directory = File(cacheDir, "web_uploads").apply { mkdirs() }
        val file = File.createTempFile("whatsapp_", suffix, directory)
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        pendingCapture = uri to file
        return Intent(
            if (isVideo) MediaStore.ACTION_VIDEO_CAPTURE else MediaStore.ACTION_IMAGE_CAPTURE,
        ).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }
    }

    private fun clearPendingFileRequest() {
        pendingFileCallback = null
        pendingCapture = null
        pendingFileParams = null
    }

    private fun handleWebBack(view: WebView) {
        view.evaluateJavascript(WebMobileLayout.BACK_SCRIPT) { handled ->
            if (handled != "true") finish()
        }
    }

    private fun showMessage(text: String) {
        message.text = text
        message.visibility = View.VISIBLE
    }

    private fun showPhoneLogin(view: WebView) {
        val script = "(function(){var items=Array.from(document.querySelectorAll(" +
            "'button,a,[role=button]'));var item=items.find(function(e){var t=(e.innerText||'').toLowerCase();" +
            "return t.includes('phone number')||t.includes('số điện thoại');});" +
            "if(item){item.click();return true;}return false;})()"
        view.evaluateJavascript(script) { clicked ->
            if (clicked == "true") {
                qrOverlay.visibility = View.GONE
                phoneOverlay.visibility = View.VISIBLE
                phoneOverlay.prepareForDisplay()
            } else Toast.makeText(this, "Chưa mở được đăng nhập bằng số điện thoại.", Toast.LENGTH_SHORT).show()
        }
    }

    private fun showQrLogin(view: WebView) {
        val script = "(function(){var items=Array.from(document.querySelectorAll(" +
            "'button,a,[role=button]'));var item=items.find(function(e){var t=(e.innerText||'').toLowerCase();" +
            "return t.includes('qr code')||t.includes('mã qr');});" +
            "if(item){item.click();return true;}return false;})()"
        view.evaluateJavascript(script) {
            phoneOverlay.visibility = View.GONE
            qrOverlay.showLoading()
            readyChecks = 0
            handler.postDelayed(::checkWebContent, 350)
        }
    }

    private fun submitPhoneNumber(view: WebView, phone: String) {
        val safePhone = phone.replace("'", "")
        val script = "(function(){" +
            "var input=document.querySelector(\"input[type='tel']\")||" +
            "Array.from(document.querySelectorAll('input')).find(function(e){" +
            "return (e.getAttribute('aria-label')||e.placeholder||'').toLowerCase().includes('phone');});" +
            "if(!input)return 'input-missing';" +
            "var setter=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set;" +
            "setter.call(input,'$safePhone');input.dispatchEvent(new Event('input',{bubbles:true}));" +
            "input.dispatchEvent(new Event('change',{bubbles:true}));" +
            "var buttons=Array.from(document.querySelectorAll('button,[role=button]'));" +
            "var next=buttons.find(function(e){var t=(e.innerText||'').trim().toLowerCase();" +
            "return t==='next'||t==='tiếp tục'||t==='continue';});" +
            "if(next){next.click();return 'submitted';}return 'button-missing';})()"
        view.evaluateJavascript(script) { result ->
            if (result == "\"submitted\"") {
                phoneOverlay.visibility = View.GONE
                installMobileLayout(view)
            } else {
                Toast.makeText(this, "Chưa gửi được số điện thoại. Vui lòng thử lại.", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun switchSession(id: String) {
        if (id == sessionId) return
        WebSessionStore(this).select(id)
        startActivity(Intent(this, WebSessionActivity::class.java).putExtra("id", id))
        finish()
    }

    private fun showCreateAccount() {
        if (!WebBridge.supportsProfiles()) {
            Toast.makeText(this, "Cập nhật Android System WebView để thêm tài khoản.", Toast.LENGTH_LONG).show()
            return
        }
        val input = EditText(this).apply {
            hint = "Ví dụ: Bán hàng"
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
            filters = arrayOf(InputFilter.LengthFilter(40))
            setSingleLine(true)
        }
        val dialog = AlertDialog.Builder(this)
            .setTitle("Thêm tài khoản")
            .setMessage("Tài khoản mới sẽ có mã QR và dữ liệu đăng nhập riêng.")
            .setView(input)
            .setNegativeButton("Hủy", null)
            .setPositiveButton("Tạo", null)
            .create()
        dialog.setOnShowListener {
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener {
                val name = input.text.toString().trim()
                if (name.isEmpty()) input.error = "Nhập tên tài khoản"
                else try {
                    val created = WebSessionStore(this).create(name)
                    dialog.dismiss()
                    switchSession(created.id)
                } catch (_: Exception) {
                    input.error = "Chưa tạo được tài khoản"
                }
            }
            input.requestFocus()
        }
        dialog.show()
    }

    private fun showHelp() {
        AlertDialog.Builder(this)
            .setTitle("Liên kết WhatsApp")
            .setMessage("Mở WhatsApp trên điện thoại chính → Thiết bị liên kết → Liên kết thiết bị, rồi quét mã QR trên màn hình này.")
            .setPositiveButton("Đã hiểu", null)
            .show()
    }

    private fun showKeyboard(view: WebView) {
        view.requestFocus()
        val keyboard = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        if (!keyboard.showSoftInput(view, InputMethodManager.SHOW_IMPLICIT)) {
            Toast.makeText(this, "Chạm vào ô nhập tin nhắn để mở bàn phím.", Toast.LENGTH_SHORT).show()
        }
    }

    private fun openDownloads() {
        try {
            startActivity(Intent(DownloadManager.ACTION_VIEW_DOWNLOADS))
        } catch (_: Exception) {
            Toast.makeText(this, "Không mở được thư mục Tải xuống trên thiết bị này.", Toast.LENGTH_SHORT).show()
        }
    }

    private fun showProgress(value: Int) {
        if (value < 100) {
            progress.visibility = View.VISIBLE
            progress.isIndeterminate = false
            progress.progress = value
        } else {
            progress.visibility = View.GONE
        }
    }

    private fun waitForWebContent() {
        webView?.let(SessionWebConfiguration::flushCookies)
        readyChecks = 0
        qrOverlay.showLoading()
        checkWebContent()
    }

    private fun checkWebContent() {
        val view = webView ?: return
        val script = "(function(){if(document.querySelector(" +
            "\"#pane-side,[data-testid='chat-list']\"))return 'chat';" +
            "if(document.querySelector(\"[data-testid='qrcode'],canvas\"))return 'qr';" +
            "return 'loading';})()"
        view.evaluateJavascript(script) { state ->
            if (state == "\"chat\"") {
                installMobileLayout(view)
                qrOverlay.visibility = View.GONE
                phoneOverlay.visibility = View.GONE
                progress.visibility = View.GONE
                message.visibility = View.GONE
            } else if (state == "\"qr\"") {
                view.evaluateJavascript(WebQrCodeReader.SCRIPT) { encoded ->
                    WebQrCodeReader.decode(encoded)?.let(qrOverlay::showQr)
                }
                progress.visibility = View.GONE
                message.visibility = View.GONE
                handler.postDelayed(::checkWebContent, 1000)
            } else if (++readyChecks < 80) {
                handler.postDelayed(::checkWebContent, 500)
            } else {
                progress.visibility = View.GONE
                showMessage(getString(R.string.web_slow_hint))
            }
        }
    }

    fun closeSession() { disposeWebView(); finish() }

    private fun disposeWebView() {
        handler.removeCallbacksAndMessages(null)
        pendingMediaRequest?.deny()
        clearPendingMediaRequest()
        pendingFileCallback?.onReceiveValue(null)
        clearPendingFileRequest()
        webView?.let { view ->
            (view.parent as? ViewGroup)?.removeView(view)
            view.stopLoading()
            view.destroy()
        }
        webView = null
        SessionProfiles.unregister(this)
    }

    override fun onPause() {
        webView?.let(SessionWebConfiguration::flushCookies)
        // Keep WhatsApp's file-input JavaScript alive while Android's picker is
        // on top. Pausing here makes the chooser callback arrive while the page
        // is suspended, so WhatsApp discards the selected attachment.
        if (pendingFileCallback == null) webView?.onPause()
        super.onPause()
    }
    override fun onResume() { super.onResume(); webView?.onResume() }
    override fun onDestroy() { disposeWebView(); super.onDestroy() }

    companion object {
        private const val FILE_CHOOSER_LOG = "WebFileChooser"
    }

}
