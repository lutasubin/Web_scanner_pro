package com.example.web_scanner_pro.web

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.view.ViewGroup
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
import androidx.webkit.WebViewCompat
import com.example.web_scanner_pro.R

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
                ::showProgress, ::waitForWebContent)
            SessionProfiles.register(this)
            onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    if (view.canGoBack()) view.goBack() else finish()
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
            onClose = ::finish,
            onSelect = ::switchSession,
            onAdd = ::showCreateAccount,
            onReload = { view.reload() },
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

    private fun fitDesktopPage(view: WebView) {
        val widthDp = view.width / resources.displayMetrics.density
        val scale = (widthDp / 500f).coerceIn(0.65f, 1f)
        val expandedWidth = 96f / scale
        val script = "(function(){" +
            "var style=document.getElementById('web-scanner-fixed-width');" +
            "if(!style){style=document.createElement('style');" +
            "style.id='web-scanner-fixed-width';document.head.appendChild(style);}" +
            "style.textContent='html,body,*{overscroll-behavior-x:none!important;}" +
            "html,body{overflow-x:hidden!important;}" +
            "*::-webkit-scrollbar:horizontal{height:0!important;display:none!important;}';" +
            "document.documentElement.style.zoom='$scale';" +
            "document.documentElement.style.width='${expandedWidth}%';" +
            "document.documentElement.style.overflowX='hidden';" +
            "document.body.style.overflowX='hidden';" +
            "if(!window.__webScannerWidthLock){window.__webScannerWidthLock=true;" +
            "var sx=0,sy=0;document.addEventListener('touchstart',function(e){" +
            "if(e.touches.length){sx=e.touches[0].clientX;sy=e.touches[0].clientY;}},{passive:true});" +
            "document.addEventListener('touchmove',function(e){if(!e.touches.length)return;" +
            "var dx=Math.abs(e.touches[0].clientX-sx),dy=Math.abs(e.touches[0].clientY-sy);" +
            "if(dx>dy)e.preventDefault();},{passive:false});}" +
            "return true;})()"
        view.evaluateJavascript(script, null)
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
                fitDesktopPage(view)
            } else {
                Toast.makeText(this, "Chưa gửi được số điện thoại. Vui lòng thử lại.", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun switchSession(id: String) {
        if (id == sessionId) return
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
                fitDesktopPage(view)
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
        webView?.onPause()
        super.onPause()
    }
    override fun onResume() { super.onResume(); webView?.onResume() }
    override fun onDestroy() { disposeWebView(); super.onDestroy() }
}
