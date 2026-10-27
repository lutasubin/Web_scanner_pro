package com.example.web_scanner_pro.web

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.text.InputFilter
import android.text.InputType
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.InputMethodManager
import android.webkit.JavascriptInterface
import android.webkit.PermissionRequest
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.webkit.WebSettingsCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import com.example.web_scanner_pro.MainActivity
import com.example.web_scanner_pro.R
import java.io.File

class WebSessionActivity : ComponentActivity() {
    var sessionId: String = "personal"
        private set
    private var webView: FixedWidthWebView? = null
    private lateinit var session: StoredWebSession
    private lateinit var toolbar: WebSessionToolbar
    private lateinit var message: TextView
    private lateinit var progress: ProgressBar
    private lateinit var preLoginFab: ImageButton
    private lateinit var keyboardHintCard: LinearLayout
    private lateinit var downloadHandler: WebDownloadHandler
    private val handler = Handler(Looper.getMainLooper())
    private var readyChecks = 0
    private var isLoggedIn = false
    private var isLoginReady = false
    private var currentLoginMode = WebMobileLayout.MODE_QR
    private var webMode = 0 // 0 = Advanced Mobile (1-pane), 1 = Basic Desktop
    private var isKeyboardLocked = false
    private var isDarkMode = false
    private var openedQrHelperThisSession = false
    private var openedCodeHelperThisSession = false
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
            (sessionId != WebSessionStore.DEFAULT_ID && !WebBridge.supportsProfiles())
        ) {
            finish()
            return
        }
        val prefs = prefs()
        webMode = prefs.getInt("web_mode_$sessionId", 0)
        isDarkMode = prefs.getBoolean("dark_mode_$sessionId", false)
        isKeyboardLocked = prefs.getBoolean("kb_lock_$sessionId", false)
        try {
            window.statusBarColor = Color.WHITE
            window.navigationBarColor = Color.WHITE
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            val view = FixedWidthWebView(this).apply {
                allowHorizontalScroll = (webMode == 1)
            }
            webView = view
            if (WebBridge.supportsProfiles()) {
                WebViewCompat.setProfile(view, SessionProfiles.name(sessionId))
            }
            downloadHandler = WebDownloadHandler(applicationContext, ::showMessage)
            downloadHandler.attach(view)
            view.addJavascriptInterface(AndroidJsBridge(), "Android")
            buildLayout(view)
            SessionWebConfiguration.configure(
                view,
                this,
                ::showMessage,
                ::showProgress,
                ::waitForWebContent,
                ::handleMediaPermission,
                ::cancelMediaPermission,
                ::showFileChooser,
                downloadHandler::download,
            )
            applyWebDisplaySettings(view)
            applyDarkMode(view)
            SessionProfiles.register(this)
            onBackPressedDispatcher.addCallback(
                this,
                object : OnBackPressedCallback(true) {
                    override fun handleOnBackPressed() {
                        handleWebBack(view)
                    }
                },
            )
            view.loadUrl("https://web.whatsapp.com/")
        } catch (_: Exception) {
            Toast.makeText(
                this,
                "Không mở được WebView. Hãy cập nhật và thử lại.",
                Toast.LENGTH_LONG,
            ).show()
            finish()
        }
    }

    private fun buildLayout(view: FixedWidthWebView) {
        val density = resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        root.setOnApplyWindowInsetsListener { target, insets ->
            target.setPadding(
                insets.systemWindowInsetLeft,
                insets.systemWindowInsetTop,
                insets.systemWindowInsetRight,
                insets.systemWindowInsetBottom,
            )
            insets
        }
        val sessions = WebSessionStore(this).list()
        toolbar = WebSessionToolbar(
            activity = this,
            sessions = sessions,
            currentId = sessionId,
            onClose = { handleWebBack(view) },
            onSelect = ::switchSession,
            onAdd = ::showCreateAccount,
            onReload = {
                readyChecks = 0
                isLoginReady = false
                updateLoginModeViews()
                progress.visibility = View.VISIBLE
                progress.isIndeterminate = true
                view.reload()
            },
            onKeyboardToggle = { toggleKeyboardLock(view) },
            onDownloads = ::openDownloads,
            onHelp = { showHelp(currentLoginMode) },
            onSwitchLoginMode = { anchor ->
                WebHelpDialogs.showLoginModePopup(this, anchor, currentLoginMode) { selected ->
                    if (selected != currentLoginMode) {
                        toggleLoginModeOnWeb(view, selected)
                    }
                }
            },
            onShowModeDialog = {
                WebHelpDialogs.showDisplayModeDialog(this, webMode) { selectedMode ->
                    setWebDisplayMode(view, selectedMode)
                }
            },
            onToggleDarkMode = {
                isDarkMode = !isDarkMode
                prefs().edit().putBoolean("dark_mode_$sessionId", isDarkMode).apply()
                applyDarkMode(view)
            },
        )
        root.addView(toolbar.build())
        toolbar.setKeyboardLocked(isKeyboardLocked)
        toolbar.setDarkMode(isDarkMode)

        message = TextView(this).apply {
            setPadding(dp(16), dp(8), dp(16), dp(8))
            setBackgroundColor(0xFFFFF8E7.toInt())
            setTextColor(0xFF202124.toInt())
            textSize = 13.5f
            visibility = View.GONE
            setOnClickListener { visibility = View.GONE }
        }
        root.addView(message)

        progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
            isIndeterminate = true
            progressTintList = android.content.res.ColorStateList.valueOf(0xFF08C567.toInt())
            indeterminateTintList = android.content.res.ColorStateList.valueOf(0xFF08C567.toInt())
            contentDescription = getString(R.string.loading_whatsapp)
        }
        root.addView(
            progress,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                resources.getDimensionPixelSize(R.dimen.web_progress_height),
            ),
        )

        // Bottom-right floating login-mode button matching `ImageButton @0x7f0a00c4` in original app's `activity_web.xml`
        preLoginFab = ImageButton(this).apply {
            setBackgroundColor(Color.TRANSPARENT)
            setImageResource(R.drawable.ic_login_code)
            scaleType = ImageView.ScaleType.FIT_CENTER
            visibility = View.GONE
            contentDescription = "Chuyển chế độ đăng nhập"
            setOnClickListener {
                val targetMode = if (currentLoginMode == WebMobileLayout.MODE_QR) {
                    WebMobileLayout.MODE_CODE
                } else {
                    WebMobileLayout.MODE_QR
                }
                toggleLoginModeOnWeb(view, targetMode)
            }
        }

        // Top floating Keyboard Lock hint card (matches `popup_hint_keybroad.xml` in original app)
        keyboardHintCard = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            visibility = View.GONE
            background = GradientDrawable().apply {
                setColor(0xFF1F2C34.toInt())
                cornerRadius = dp(12).toFloat()
            }
            elevation = dp(6).toFloat()
            setPadding(dp(14), dp(10), dp(14), dp(10))
            addView(
                ImageView(this@WebSessionActivity).apply {
                    setImageResource(R.drawable.ic_web_keyboard_lock)
                    imageTintList = android.content.res.ColorStateList.valueOf(Color.WHITE)
                },
                LinearLayout.LayoutParams(dp(20), dp(20)),
            )
            addView(
                TextView(this@WebSessionActivity).apply {
                    text = "Bàn phím đang khóa để tránh nhảy phím. Nhấn để mở khóa."
                    textSize = 13f
                    setTextColor(Color.WHITE)
                },
                LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                    marginStart = dp(10)
                },
            )
            addView(
                TextView(this@WebSessionActivity).apply {
                    text = "Mở khóa"
                    textSize = 13f
                    typeface = Typeface.DEFAULT_BOLD
                    setTextColor(0xFF08C567.toInt())
                    setPadding(dp(8), dp(4), dp(4), dp(4))
                },
            )
            setOnClickListener {
                if (isKeyboardLocked) {
                    toggleKeyboardLock(view)
                } else {
                    visibility = View.GONE
                }
            }
        }

        val content = FrameLayout(this).apply {
            addView(
                view,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                ),
            )
            addView(
                preLoginFab,
                FrameLayout.LayoutParams(
                    dp(72),
                    dp(72),
                    Gravity.BOTTOM or Gravity.END,
                ).apply {
                    bottomMargin = dp(66)
                    marginEnd = dp(3)
                },
            )
            addView(
                keyboardHintCard,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    Gravity.TOP,
                ).apply {
                    topMargin = dp(8)
                    marginStart = dp(12)
                    marginEnd = dp(12)
                },
            )
        }
        root.addView(content, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        setContentView(root)
        view.overScrollMode = View.OVER_SCROLL_NEVER
        updateLoginModeViews()
    }

    private fun updateLoginModeViews() {
        if (!::preLoginFab.isInitialized) return
        if (isLoggedIn || !isLoginReady) {
            preLoginFab.visibility = View.GONE
            return
        }
        preLoginFab.visibility = View.VISIBLE
        val isQr = currentLoginMode == WebMobileLayout.MODE_QR
        preLoginFab.setImageResource(
            if (isQr) R.drawable.ic_login_code else R.drawable.ic_login_qr,
        )
    }

    private fun toggleLoginModeOnWeb(view: WebView, targetMode: String) {
        currentLoginMode = targetMode
        updateLoginModeViews()
        view.evaluateJavascript(WebMobileLayout.TOGGLE_LOGIN_MODE_SCRIPT) { result ->
            handler.postDelayed({ syncObserverAndLayout(view) }, 350)
            if (result == "\"not-found\"") {
                Toast.makeText(
                    this,
                    "Đang tải trang đăng nhập WhatsApp Web, vui lòng đợi giây lát...",
                    Toast.LENGTH_SHORT,
                ).show()
            }
        }
    }

    private fun toggleKeyboardLock(view: WebView) {
        isKeyboardLocked = !isKeyboardLocked
        prefs().edit().putBoolean("kb_lock_$sessionId", isKeyboardLocked).apply()
        toolbar.setKeyboardLocked(isKeyboardLocked)
        view.evaluateJavascript(
            "window.__webScannerKeyboardLocked = $isKeyboardLocked;",
            null,
        )
        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        if (isKeyboardLocked) {
            imm.hideSoftInputFromWindow(view.windowToken, 0)
            showKeyboardHintBriefly()
        } else {
            keyboardHintCard.visibility = View.GONE
            view.requestFocus()
            imm.showSoftInput(view, InputMethodManager.SHOW_IMPLICIT)
            Toast.makeText(this, "Đã mở khóa bàn phím.", Toast.LENGTH_SHORT).show()
        }
    }

    private fun showKeyboardHintBriefly() {
        keyboardHintCard.visibility = View.VISIBLE
        handler.removeCallbacks(hideKeyboardHintRunnable)
        handler.postDelayed(hideKeyboardHintRunnable, 4500L)
    }

    private val hideKeyboardHintRunnable = Runnable {
        if (::keyboardHintCard.isInitialized) {
            keyboardHintCard.visibility = View.GONE
        }
    }

    private fun setWebDisplayMode(view: FixedWidthWebView, newMode: Int) {
        webMode = newMode
        prefs().edit().putInt("web_mode_$sessionId", webMode).apply()
        applyWebDisplaySettings(view)
        syncObserverAndLayout(view)
        Toast.makeText(
            this,
            if (webMode == 0) "Đã chuyển sang Chế độ nâng cao (Mobile)."
            else "Đã chuyển sang Chế độ cơ bản (Desktop).",
            Toast.LENGTH_SHORT,
        ).show()
    }

    private fun applyWebDisplaySettings(view: FixedWidthWebView) {
        val isBasicDesktop = (webMode == 1)
        view.allowHorizontalScroll = isBasicDesktop
        view.isHorizontalScrollBarEnabled = isBasicDesktop
        view.settings.apply {
            setSupportZoom(isBasicDesktop)
            builtInZoomControls = isBasicDesktop
            displayZoomControls = false
        }
    }

    private fun applyDarkMode(view: WebView) {
        toolbar.setDarkMode(isDarkMode)
        window.statusBarColor = if (isDarkMode) 0xFF1F2C34.toInt() else Color.WHITE
        if (WebViewFeature.isFeatureSupported(WebViewFeature.ALGORITHMIC_DARKENING)) {
            try {
                WebSettingsCompat.setAlgorithmicDarkeningAllowed(view.settings, isDarkMode)
            } catch (_: Exception) {}
        }
        view.evaluateJavascript(
            "(function(){if(document.body){document.body.classList.toggle('dark',$isDarkMode);}})()",
            null,
        )
    }

    private fun installMobileLayout(view: WebView) {
        if (webMode == 1) {
            view.evaluateJavascript(
                WebMobileLayout.installDualAppObserver(webMode, isKeyboardLocked),
                null,
            )
            return
        }
        val widthDp = (view.width.takeIf { it > 0 } ?: resources.displayMetrics.widthPixels) /
            resources.displayMetrics.density
        val scale = (widthDp / 360f).coerceIn(0.9f, 1.18f)
        val expandedWidth = 100f / scale
        view.evaluateJavascript(WebMobileLayout.install(scale, expandedWidth), null)
        view.evaluateJavascript(
            WebMobileLayout.installDualAppObserver(webMode, isKeyboardLocked),
            null,
        )
    }

    private fun syncObserverAndLayout(view: WebView) {
        view.evaluateJavascript(
            WebMobileLayout.installDualAppObserver(webMode, isKeyboardLocked),
        ) { state ->
            if (state == "\"chat\"") {
                onLoggedInDetected(view)
            }
        }
    }

    private fun onLoggedInDetected(view: WebView) {
        if (!isLoggedIn) {
            isLoggedIn = true
            toolbar.setLoggedIn(true)
            updateLoginModeViews()
            val prefs = prefs()
            if (!prefs.getBoolean("shown_first_login_security_dialog", false)) {
                prefs.edit().putBoolean("shown_first_login_security_dialog", true).apply()
                WebHelpDialogs.showFirstLoginSecurityDialog(this)
            }
        }
        installMobileLayout(view)
        applyDarkMode(view)
        progress.visibility = View.GONE
        message.visibility = View.GONE
    }

    private inner class AndroidJsBridge {
        @JavascriptInterface
        fun postMessage(event: String?) {
            val ev = event ?: return
            handler.post {
                val view = webView ?: return@post
                when (ev) {
                    WebMobileLayout.MODE_QR -> {
                        currentLoginMode = WebMobileLayout.MODE_QR
                        isLoginReady = true
                        if (isLoggedIn) {
                            isLoggedIn = false
                            toolbar.setLoggedIn(false)
                        }
                        progress.visibility = View.GONE
                        message.visibility = View.GONE
                        updateLoginModeViews()
                    }
                    WebMobileLayout.MODE_CODE -> {
                        currentLoginMode = WebMobileLayout.MODE_CODE
                        isLoginReady = true
                        if (isLoggedIn) {
                            isLoggedIn = false
                            toolbar.setLoggedIn(false)
                        }
                        progress.visibility = View.GONE
                        message.visibility = View.GONE
                        updateLoginModeViews()
                    }
                    "webLoading" -> {
                        isLoginReady = false
                        if (isLoggedIn) {
                            isLoggedIn = false
                            toolbar.setLoggedIn(false)
                            toolbar.setBackVisible(true)
                        }
                        updateLoginModeViews()
                        progress.visibility = View.VISIBLE
                        progress.isIndeterminate = true
                        readyChecks = 0
                    }
                    "openHelper" -> {
                        if (!openedQrHelperThisSession &&
                            !prefs().getBoolean("auto_shown_qr_helper", false)
                        ) {
                            openedQrHelperThisSession = true
                            prefs().edit().putBoolean("auto_shown_qr_helper", true).apply()
                            showHelp(WebMobileLayout.MODE_QR)
                        }
                    }
                    "openCodeHelper" -> {
                        if (!openedCodeHelperThisSession) {
                            openedCodeHelperThisSession = true
                            showHelp(WebMobileLayout.MODE_CODE)
                        }
                    }
                    "logSuccess" -> {
                        onLoggedInDetected(view)
                    }
                    "entryMessageDetail" -> {
                        // Hide top toolbar back button inside chat detail so only WhatsApp's chat header back arrow shows (matches original app)
                        toolbar.setBackVisible(false)
                    }
                    "leaveMessageDetail" -> {
                        toolbar.setBackVisible(true)
                    }
                    "openKeyBroad" -> {
                        if (isKeyboardLocked) {
                            showKeyboardHintBriefly()
                        }
                    }
                }
            }
        }

        @JavascriptInterface
        fun copyCode(code: String?) {
            val clean = code?.trim().orEmpty()
            if (clean.isEmpty()) return
            handler.post {
                try {
                    val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    clipboard.setPrimaryClip(ClipData.newPlainText("WhatsApp Link Code", clean))
                    Toast.makeText(
                        this@WebSessionActivity,
                        "Đã tự động sao chép mã liên kết: $clean",
                        Toast.LENGTH_LONG,
                    ).show()
                } catch (_: Exception) {}
            }
        }
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

    private fun switchSession(id: String) {
        if (id == sessionId) return
        WebSessionStore(this).select(id)
        startActivity(Intent(this, WebSessionActivity::class.java).putExtra("id", id))
        finish()
    }

    private fun showCreateAccount() {
        if (!WebBridge.supportsProfiles()) {
            Toast.makeText(
                this,
                "Cập nhật Android System WebView để thêm tài khoản.",
                Toast.LENGTH_LONG,
            ).show()
            return
        }
        val sessions = WebSessionStore(this).list()
        if (sessions.size >= 5) {
            Toast.makeText(this, "Hỗ trợ tối đa 5 tài khoản song song.", Toast.LENGTH_SHORT).show()
            return
        }
        val input = EditText(this).apply {
            hint = "Ví dụ: Bán hàng"
            setText("Tài khoản ${sessions.size + 1}")
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
            filters = arrayOf(InputFilter.LengthFilter(40))
            setSingleLine(true)
            selectAll()
        }
        val dialog = AlertDialog.Builder(this)
            .setTitle("Thêm tài khoản")
            .setMessage("Tài khoản mới sẽ có mã QR và dữ liệu đăng nhập riêng biệt.")
            .setView(input)
            .setNegativeButton("Hủy", null)
            .setPositiveButton("Tạo", null)
            .create()
        dialog.setOnShowListener {
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener {
                val name = input.text.toString().trim()
                if (name.isEmpty()) {
                    input.error = "Nhập tên tài khoản"
                } else {
                    try {
                        val created = WebSessionStore(this).create(name)
                        dialog.dismiss()
                        switchSession(created.id)
                    } catch (_: Exception) {
                        input.error = "Chưa tạo được tài khoản"
                    }
                }
            }
            input.requestFocus()
        }
        dialog.show()
    }

    private fun showHelp(mode: String = currentLoginMode) {
        val view = webView
        WebHelpDialogs.showHelpSheet(
            activity = this,
            initialMode = mode,
            onSwitchLoginMode = { selected ->
                if (view != null && selected != currentLoginMode) {
                    toggleLoginModeOnWeb(view, selected)
                }
            },
        )
    }

    private fun openDownloads() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("open_route", "/files")
            }
            startActivity(intent)
        } catch (_: Exception) {
            Toast.makeText(
                this,
                "Không mở được màn hình Tệp tải xuống.",
                Toast.LENGTH_SHORT,
            ).show()
        }
    }

    private fun showProgress(value: Int) {
        if (value < 100) {
            progress.visibility = View.VISIBLE
            progress.isIndeterminate = false
            progress.progress = value
        } else if (isLoggedIn || isLoginReady) {
            progress.visibility = View.GONE
        } else {
            progress.visibility = View.VISIBLE
            progress.isIndeterminate = true
        }
    }

    private fun waitForWebContent() {
        webView?.let(SessionWebConfiguration::flushCookies)
        readyChecks = 0
        checkWebContent()
    }

    private fun checkWebContent() {
        val view = webView ?: return
        view.evaluateJavascript(
            WebMobileLayout.installDualAppObserver(webMode, isKeyboardLocked),
        ) { state ->
            when (state) {
                "\"chat\"" -> {
                    onLoggedInDetected(view)
                }
                "\"login\"" -> {
                    isLoginReady = true
                    progress.visibility = View.GONE
                    message.visibility = View.GONE
                    updateLoginModeViews()
                    if (++readyChecks < 120) {
                        handler.postDelayed(::checkWebContent, 1000)
                    }
                }
                else -> {
                    isLoginReady = false
                    updateLoginModeViews()
                    if (++readyChecks < 80) {
                        progress.visibility = View.VISIBLE
                        progress.isIndeterminate = true
                        handler.postDelayed(::checkWebContent, 500)
                    } else {
                        progress.visibility = View.GONE
                        showMessage(getString(R.string.web_slow_hint))
                    }
                }
            }
        }
    }

    private fun prefs() = getSharedPreferences("web_session_ui_prefs", Context.MODE_PRIVATE)

    fun closeSession() {
        disposeWebView()
        finish()
    }

    private fun disposeWebView() {
        handler.removeCallbacksAndMessages(null)
        pendingMediaRequest?.deny()
        clearPendingMediaRequest()
        pendingFileCallback?.onReceiveValue(null)
        clearPendingFileRequest()
        webView?.let { view ->
            if (::downloadHandler.isInitialized) downloadHandler.detach(view)
            view.removeJavascriptInterface("Android")
            (view.parent as? ViewGroup)?.removeView(view)
            view.stopLoading()
            view.destroy()
        }
        webView = null
        SessionProfiles.unregister(this)
    }

    override fun onPause() {
        webView?.let(SessionWebConfiguration::flushCookies)
        if (pendingFileCallback == null) webView?.onPause()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        webView?.onResume()
    }

    override fun onDestroy() {
        disposeWebView()
        super.onDestroy()
    }

    companion object {
        private const val FILE_CHOOSER_LOG = "WebFileChooser"
    }
}
