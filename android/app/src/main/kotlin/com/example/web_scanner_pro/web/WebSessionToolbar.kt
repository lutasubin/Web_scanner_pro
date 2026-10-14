package com.example.web_scanner_pro.web

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.TextUtils
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.PopupMenu
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
    private val onKeyboard: () -> Unit,
    private val onDownloads: () -> Unit,
    private val onHelp: () -> Unit,
) {
    private val density = activity.resources.displayMetrics.density

    fun build(): View = LinearLayout(activity).apply {
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(8), dp(7), dp(8), dp(7))
        setBackgroundColor(Color.WHITE)
        elevation = dp(2).toFloat()
        addView(action(R.drawable.ic_web_back, "Quay lại", onClose))
        addView(profilePicker(), LinearLayout.LayoutParams(0, dp(48), 1f).apply {
            marginStart = dp(2)
            marginEnd = dp(6)
        })
        addView(action(R.drawable.ic_web_refresh, "Tải lại", onReload))
        addView(action(R.drawable.ic_web_keyboard_lock, "Mở bàn phím", onKeyboard))
        addView(action(R.drawable.ic_web_folder_download, "Mở tệp tải xuống", onDownloads))
        addView(action(R.drawable.ic_web_more, "Tùy chọn khác") { anchor -> showMore(anchor) })
    }

    private fun profilePicker() = TextView(activity).apply {
        val current = sessions.firstOrNull { it.id == currentId }
        text = "${current?.name ?: "Người dùng"}  ▼"
        textSize = 17f
        maxLines = 1
        ellipsize = TextUtils.TruncateAt.END
        gravity = Gravity.CENTER_VERTICAL
        setTextColor(GREEN)
        typeface = Typeface.DEFAULT_BOLD
        background = rounded(PALE_GREEN, dp(24))
        setPadding(dp(16), 0, dp(12), 0)
        contentDescription = "Chuyển hoặc thêm người dùng"
        setOnClickListener { showProfiles(this) }
    }

    private fun showProfiles(anchor: View) {
        val panel = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(8), dp(8), dp(8), dp(8))
            background = rounded(Color.WHITE, dp(12), 0x14000000)
        }
        lateinit var popup: PopupWindow
        sessions.forEach { item ->
            panel.addView(profileRow(item, item.id == currentId) {
                popup.dismiss()
                onSelect(item.id)
            })
        }
        panel.addView(View(activity).apply { setBackgroundColor(DIVIDER) },
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(1)).apply {
                marginStart = dp(12)
                marginEnd = dp(12)
            })
        panel.addView(menuRow(R.drawable.ic_web_person_add, "Thêm tài khoản", false) {
            popup.dismiss()
            onAdd()
        })
        val maxWidth = activity.resources.displayMetrics.widthPixels - dp(24)
        popup = PopupWindow(panel, min(dp(286), maxWidth), ViewGroup.LayoutParams.WRAP_CONTENT, true).apply {
            isOutsideTouchable = true
            elevation = dp(8).toFloat()
            setBackgroundDrawable(rounded(Color.WHITE, dp(12)))
            animationStyle = android.R.style.Animation_Dialog
        }
        popup.showAsDropDown(anchor, 0, dp(6))
    }

    private fun profileRow(item: StoredWebSession, selected: Boolean, click: () -> Unit): View =
        menuRow(R.drawable.ic_web_account, item.name, selected, click)

    private fun menuRow(icon: Int, label: String, selected: Boolean, click: () -> Unit) =
        LinearLayout(activity).apply {
            gravity = Gravity.CENTER_VERTICAL
            minimumHeight = dp(58)
            setPadding(dp(12), dp(4), dp(10), dp(4))
            background = rounded(if (selected) 0xFFF7FBF7.toInt() else Color.TRANSPARENT, dp(9))
            isClickable = true
            isFocusable = true
            setOnClickListener { click() }
            addView(FrameLayout(activity).apply {
                background = rounded(PALE_GREEN, dp(23))
                addView(ImageView(activity).apply {
                    setImageResource(icon)
                    scaleType = ImageView.ScaleType.CENTER_INSIDE
                    setPadding(dp(10), dp(10), dp(10), dp(10))
                }, FrameLayout.LayoutParams(dp(46), dp(46), Gravity.CENTER))
            }, LinearLayout.LayoutParams(dp(46), dp(46)))
            addView(TextView(activity).apply {
                text = label
                textSize = 17f
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
                setTextColor(TEXT)
                typeface = Typeface.DEFAULT_BOLD
            }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dp(12)
            })
            if (selected) addView(ImageView(activity).apply {
                setImageResource(R.drawable.ic_web_check)
                scaleType = ImageView.ScaleType.CENTER_INSIDE
                setPadding(dp(5), dp(5), dp(5), dp(5))
            }, LinearLayout.LayoutParams(dp(36), dp(44)))
        }

    private fun showMore(anchor: View) {
        PopupMenu(activity, anchor).apply {
            menu.add("Hướng dẫn liên kết")
            menu.add("Đóng phiên Web")
            setOnMenuItemClickListener {
                if (it.title == "Hướng dẫn liên kết") onHelp() else onClose()
                true
            }
            show()
        }
    }

    private fun action(icon: Int, description: String, listener: () -> Unit) =
        action(icon, description) { _: View -> listener() }

    private fun action(
        icon: Int,
        description: String,
        listener: (View) -> Unit,
    ) = ImageView(activity).apply {
        setImageResource(icon)
        scaleType = ImageView.ScaleType.CENTER_INSIDE
        setPadding(dp(9), dp(9), dp(9), dp(9))
        contentDescription = description
        isClickable = true
        isFocusable = true
        background = selectableBackground()
        setOnClickListener { listener(this) }
        layoutParams = ViewGroup.LayoutParams(dp(43), dp(48))
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

    companion object {
        private const val GREEN = 0xFF00A884.toInt()
        private const val PALE_GREEN = 0xFFE9F8E7.toInt()
        private const val TEXT = 0xFF202124.toInt()
        private const val DIVIDER = 0xFFE7E9EB.toInt()
    }
}
