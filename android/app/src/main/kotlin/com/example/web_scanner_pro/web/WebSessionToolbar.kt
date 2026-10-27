package com.example.web_scanner_pro.web

import android.app.Activity
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.text.TextUtils
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.animation.Animation
import android.view.animation.LinearInterpolator
import android.view.animation.RotateAnimation
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView
import com.example.web_scanner_pro.R
import kotlin.math.min

class WebSessionToolbar(
    private val activity: Activity,
    private val sessions: List<StoredWebSession>,
    private val currentId: String,
    private val onClose: () -> Unit,
    private val onSelect: (String) -> Unit,
    private val onAdd: () -> Unit,
    private val onReload: () -> Unit,
    private val onKeyboardToggle: () -> Unit,
    private val onDownloads: () -> Unit,
    private val onHelp: () -> Unit,
    private val onSwitchLoginMode: (View) -> Unit,
    private val onShowModeDialog: () -> Unit,
    private val onToggleDarkMode: () -> Unit,
) {
    private val density = activity.resources.displayMetrics.density
    private lateinit var rootLayout: LinearLayout
    private lateinit var backButton: ImageView
    private lateinit var reloadButton: ImageView
    private lateinit var preLoginGroup: LinearLayout
    private lateinit var postLoginGroup: LinearLayout
    private lateinit var keyboardButton: ImageView
    private lateinit var helpButton: ImageView
    private lateinit var loginModeButton: ImageView
    private lateinit var downloadsButton: ImageView
    private lateinit var moreButton: ImageView
    private var isLoggedIn = false
    private var isKeyboardLocked = false
    private var isDarkMode = false

    fun build(): View = LinearLayout(activity).apply {
        rootLayout = this
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(8), dp(7), dp(8), dp(7))
        setBackgroundColor(Color.WHITE)
        elevation = dp(2).toFloat()

        backButton = action(R.drawable.ic_web_back, "Quay lại", onClose)
        addView(backButton)

        addView(
            profilePicker(),
            LinearLayout.LayoutParams(0, dp(42), 1f).apply {
                marginStart = dp(4)
                marginEnd = dp(6)
            },
        )

        reloadButton = action(R.drawable.ic_web_refresh, "Tải lại") {
            animateReload()
            onReload()
        }
        addView(reloadButton)

        // Pre-login actions (layout_unlogin in original app: Help `?` + Switch Login Mode)
        preLoginGroup = LinearLayout(activity).apply {
            gravity = Gravity.CENTER_VERTICAL
            helpButton = textBadgeAction("?", "Hướng dẫn liên kết") { onHelp() }
            loginModeButton = ImageView(activity).apply {
                setImageResource(R.drawable.ic_login_qr)
                scaleType = ImageView.ScaleType.CENTER_INSIDE
                setPadding(dp(8), dp(8), dp(8), dp(8))
                contentDescription = "Chuyển chế độ đăng nhập"
                isClickable = true
                isFocusable = true
                background = selectableBackground()
                setOnClickListener { onSwitchLoginMode(this) }
                layoutParams = ViewGroup.LayoutParams(dp(41), dp(44))
            }
            addView(helpButton)
            addView(loginModeButton)
        }
        addView(preLoginGroup)

        // Post-login actions (layout_login in original app: Keyboard Lock, Downloads, More)
        postLoginGroup = LinearLayout(activity).apply {
            gravity = Gravity.CENTER_VERTICAL
            visibility = View.GONE
            keyboardButton = action(R.drawable.ic_web_keyboard_lock, "Khóa/Mở bàn phím") {
                onKeyboardToggle()
            }
            downloadsButton = action(R.drawable.ic_web_folder_download, "Tệp đã tải xuống") {
                onDownloads()
            }
            moreButton = anchoredAction(R.drawable.ic_web_more, "Tùy chọn khác") { anchor ->
                showMore(anchor)
            }
            addView(keyboardButton)
            addView(downloadsButton)
            addView(moreButton)
        }
        addView(postLoginGroup)
    }

    fun setLoggedIn(loggedIn: Boolean) {
        isLoggedIn = loggedIn
        preLoginGroup.visibility = if (loggedIn) View.GONE else View.VISIBLE
        postLoginGroup.visibility = if (loggedIn) View.VISIBLE else View.GONE
    }

    fun setBackVisible(visible: Boolean) {
        backButton.visibility = if (visible) View.VISIBLE else View.GONE
    }

    fun setKeyboardLocked(locked: Boolean) {
        isKeyboardLocked = locked
        if (::keyboardButton.isInitialized) {
            keyboardButton.background = if (locked) {
                rounded(0xFFFFEFEF.toInt(), dp(10), 0xFFE53935.toInt())
            } else {
                selectableBackground()
            }
            keyboardButton.imageTintList = ColorStateList.valueOf(
                if (locked) 0xFFD32F2F.toInt()
                else if (isDarkMode) Color.WHITE
                else TEXT,
            )
        }
    }

    fun setDarkMode(dark: Boolean) {
        isDarkMode = dark
        if (!::rootLayout.isInitialized) return
        val bg = if (dark) 0xFF1F2C34.toInt() else Color.WHITE
        val fg = if (dark) Color.WHITE else TEXT
        rootLayout.setBackgroundColor(bg)
        listOf(backButton, reloadButton, downloadsButton, moreButton).forEach {
            it.imageTintList = ColorStateList.valueOf(fg)
        }
        setKeyboardLocked(isKeyboardLocked)
    }

    fun animateReload() {
        if (!::reloadButton.isInitialized) return
        val rotate = RotateAnimation(
            0f,
            360f,
            Animation.RELATIVE_TO_SELF,
            0.5f,
            Animation.RELATIVE_TO_SELF,
            0.5f,
        ).apply {
            duration = 650L
            interpolator = LinearInterpolator()
        }
        reloadButton.startAnimation(rotate)
    }

    private fun profilePicker(): View {
        val index = sessions.indexOfFirst { it.id == currentId }.coerceAtLeast(0)
        val palette = ACCOUNT_PALETTES[index % ACCOUNT_PALETTES.size]
        val current = sessions.firstOrNull { it.id == currentId }
        return TextView(activity).apply {
            text = "${current?.name ?: "Tài khoản 1"}  ▼"
            textSize = 15.5f
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
            gravity = Gravity.CENTER_VERTICAL
            setTextColor(palette.first)
            typeface = Typeface.DEFAULT_BOLD
            background = rounded(palette.second, dp(21))
            setPadding(dp(14), 0, dp(12), 0)
            contentDescription = "Chuyển hoặc thêm người dùng"
            setOnClickListener { showProfiles(this) }
        }
    }

    private fun showProfiles(anchor: View) {
        val panel = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(8), dp(8), dp(8), dp(8))
            background = rounded(Color.WHITE, dp(12), 0x14000000)
        }
        lateinit var popup: PopupWindow
        sessions.forEachIndexed { idx, item ->
            val palette = ACCOUNT_PALETTES[idx % ACCOUNT_PALETTES.size]
            panel.addView(
                profileRow(item, item.id == currentId, palette.first, palette.second) {
                    popup.dismiss()
                    onSelect(item.id)
                },
            )
        }
        if (sessions.size < 5) {
            panel.addView(
                View(activity).apply { setBackgroundColor(DIVIDER) },
                LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(1)).apply {
                    marginStart = dp(12)
                    marginEnd = dp(12)
                },
            )
            panel.addView(
                menuRow(R.drawable.ic_web_person_add, "Thêm tài khoản", false, GREEN, PALE_GREEN) {
                    popup.dismiss()
                    onAdd()
                },
            )
        }
        val maxWidth = activity.resources.displayMetrics.widthPixels - dp(24)
        popup = PopupWindow(panel, min(dp(286), maxWidth), ViewGroup.LayoutParams.WRAP_CONTENT, true).apply {
            isOutsideTouchable = true
            elevation = dp(8).toFloat()
            setBackgroundDrawable(rounded(Color.WHITE, dp(12)))
            animationStyle = android.R.style.Animation_Dialog
        }
        popup.showAsDropDown(anchor, 0, dp(6))
    }

    private fun profileRow(
        item: StoredWebSession,
        selected: Boolean,
        accent: Int,
        paleBg: Int,
        click: () -> Unit,
    ): View = menuRow(R.drawable.ic_web_account, item.name, selected, accent, paleBg, click)

    private fun menuRow(
        icon: Int,
        label: String,
        selected: Boolean,
        accent: Int,
        paleBg: Int,
        click: () -> Unit,
    ) = LinearLayout(activity).apply {
        gravity = Gravity.CENTER_VERTICAL
        minimumHeight = dp(54)
        setPadding(dp(12), dp(4), dp(10), dp(4))
        background = rounded(if (selected) 0xFFF7FBF7.toInt() else Color.TRANSPARENT, dp(9))
        isClickable = true
        isFocusable = true
        setOnClickListener { click() }
        addView(
            FrameLayout(activity).apply {
                background = rounded(paleBg, dp(21))
                addView(
                    ImageView(activity).apply {
                        setImageResource(icon)
                        imageTintList = ColorStateList.valueOf(accent)
                        scaleType = ImageView.ScaleType.CENTER_INSIDE
                        setPadding(dp(9), dp(9), dp(9), dp(9))
                    },
                    FrameLayout.LayoutParams(dp(42), dp(42), Gravity.CENTER),
                )
            },
            LinearLayout.LayoutParams(dp(42), dp(42)),
        )
        addView(
            TextView(activity).apply {
                text = label
                textSize = 16f
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
                setTextColor(TEXT)
                typeface = Typeface.DEFAULT_BOLD
            },
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dp(12)
            },
        )
        if (selected) {
            addView(
                ImageView(activity).apply {
                    setImageResource(R.drawable.ic_web_check)
                    scaleType = ImageView.ScaleType.CENTER_INSIDE
                    setPadding(dp(5), dp(5), dp(5), dp(5))
                },
                LinearLayout.LayoutParams(dp(34), dp(40)),
            )
        }
    }

    /**
     * Matches `popup_more_actions.xml` in the original app (`orig_logged_in.png`):
     * 1. Switch Mode (Advanced vs Basic)
     * 2. Dark Mode / Light Mode
     */
    private fun showMore(anchor: View) {
        lateinit var popup: PopupWindow
        val panel = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(Color.WHITE, dp(12), 0x1A000000)
            setPadding(dp(6), dp(6), dp(6), dp(6))
        }

        fun itemRow(symbol: String, title: String, click: () -> Unit): View =
            LinearLayout(activity).apply {
                gravity = Gravity.CENTER_VERTICAL
                setPadding(dp(14), dp(12), dp(16), dp(12))
                background = selectableBackground()
                setOnClickListener {
                    popup.dismiss()
                    click()
                }
                addView(
                    TextView(activity).apply {
                        text = symbol
                        textSize = 16.5f
                        setTextColor(TEXT)
                        typeface = Typeface.DEFAULT_BOLD
                        gravity = Gravity.CENTER
                    },
                    LinearLayout.LayoutParams(dp(26), ViewGroup.LayoutParams.WRAP_CONTENT),
                )
                addView(
                    TextView(activity).apply {
                        text = title
                        textSize = 14.5f
                        typeface = Typeface.DEFAULT_BOLD
                        setTextColor(TEXT)
                    },
                    LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                    ).apply { marginStart = dp(10) },
                )
            }

        panel.addView(itemRow("⇄", "Chuyển chế độ", onShowModeDialog))
        panel.addView(
            View(activity).apply { setBackgroundColor(DIVIDER) },
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(1)).apply {
                marginStart = dp(10)
                marginEnd = dp(10)
            },
        )
        panel.addView(
            itemRow(
                if (isDarkMode) "☀" else "☾",
                if (isDarkMode) "Chế độ sáng" else "Chế độ tối",
                onToggleDarkMode,
            ),
        )

        popup = PopupWindow(
            panel,
            dp(196),
            ViewGroup.LayoutParams.WRAP_CONTENT,
            true,
        ).apply {
            isOutsideTouchable = true
            elevation = dp(8).toFloat()
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        }
        popup.showAsDropDown(anchor, -dp(135), dp(4))
    }

    private fun textBadgeAction(label: String, description: String, listener: () -> Unit) =
        ImageView(activity).apply {
            // Use a clean circular question mark badge
            setImageResource(R.drawable.ic_web_more)
            scaleType = ImageView.ScaleType.CENTER_INSIDE
            setPadding(dp(9), dp(9), dp(9), dp(9))
            contentDescription = description
            isClickable = true
            isFocusable = true
            background = selectableBackground()
            setOnClickListener { listener() }
            layoutParams = ViewGroup.LayoutParams(dp(40), dp(44))
            // Replace with custom drawn `?` icon drawable
            setImageDrawable(QuestionMarkDrawable(density))
        }

    private fun action(icon: Int, description: String, listener: () -> Unit) =
        anchoredAction(icon, description) { _: View -> listener() }

    private fun anchoredAction(
        icon: Int,
        description: String,
        listener: (View) -> Unit,
    ) = ImageView(activity).apply {
        setImageResource(icon)
        scaleType = ImageView.ScaleType.CENTER_INSIDE
        setPadding(dp(8), dp(8), dp(8), dp(8))
        contentDescription = description
        isClickable = true
        isFocusable = true
        background = selectableBackground()
        setOnClickListener { listener(this) }
        layoutParams = ViewGroup.LayoutParams(dp(41), dp(44))
    }

    private fun selectableBackground() = activity.obtainStyledAttributes(
        intArrayOf(android.R.attr.selectableItemBackgroundBorderless),
    ).let { values ->
        val drawable = values.getDrawable(0)
        values.recycle()
        drawable
    }

    private fun rounded(color: Int, radius: Int, stroke: Int = 0) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = radius.toFloat()
        if (stroke != 0) setStroke(dp(1), stroke)
    }

    private fun dp(value: Int) = (value * density).toInt()

    private class QuestionMarkDrawable(private val density: Float) : android.graphics.drawable.Drawable() {
        private val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
            color = TEXT
            textAlign = android.graphics.Paint.Align.CENTER
            typeface = Typeface.DEFAULT_BOLD
        }
        private val circlePaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
            color = TEXT
            style = android.graphics.Paint.Style.STROKE
            strokeWidth = 1.8f * density
        }

        override fun draw(canvas: android.graphics.Canvas) {
            val b = bounds
            val cx = b.exactCenterX()
            val cy = b.exactCenterY()
            val r = min(b.width(), b.height()) * 0.30f
            canvas.drawCircle(cx, cy, r, circlePaint)
            paint.textSize = r * 1.35f
            val fm = paint.fontMetrics
            val ty = cy - (fm.ascent + fm.descent) / 2f
            canvas.drawText("?", cx, ty, paint)
        }

        override fun setAlpha(alpha: Int) {
            paint.alpha = alpha
            circlePaint.alpha = alpha
        }

        override fun setColorFilter(colorFilter: android.graphics.ColorFilter?) {
            paint.colorFilter = colorFilter
            circlePaint.colorFilter = colorFilter
        }

        @Deprecated("Deprecated in Java")
        override fun getOpacity(): Int = android.graphics.PixelFormat.TRANSLUCENT
    }

    companion object {
        private const val GREEN = 0xFF00A884.toInt()
        private const val PALE_GREEN = 0xFFE9F8E7.toInt()
        private const val TEXT = 0xFF202124.toInt()
        private const val DIVIDER = 0xFFE7E9EB.toInt()

        // 5 account color palettes from the original app (`WebActivity.setAccountBoxStyle()`)
        private val ACCOUNT_PALETTES = listOf(
            0xFF489A86.toInt() to 0xFFE6F4F1.toInt(),
            0xFFDF871B.toInt() to 0xFFFCF1E3.toInt(),
            0xFFB7477D.toInt() to 0xFFF9EAF1.toInt(),
            0xFF4772B7.toInt() to 0xFFEAF0F9.toInt(),
            0xFF6F47B7.toInt() to 0xFFEFEAF9.toInt(),
        )
    }
}
