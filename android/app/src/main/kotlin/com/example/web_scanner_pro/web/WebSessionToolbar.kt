package com.example.web_scanner_pro.web

import android.app.Activity
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.PopupMenu
import android.widget.TextView

class WebSessionToolbar(
    private val activity: Activity,
    private val sessions: List<StoredWebSession>,
    private val currentId: String,
    private val onClose: () -> Unit,
    private val onSelect: (String) -> Unit,
    private val onAdd: () -> Unit,
    private val onReload: () -> Unit,
    private val onHelp: () -> Unit,
) {
    private val density = activity.resources.displayMetrics.density

    fun build(): View = LinearLayout(activity).apply {
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(8), dp(6), dp(8), dp(6))
        setBackgroundColor(Color.WHITE)
        addView(action("‹", "Đóng", onClose))
        addView(profilePicker(sessions, currentId), LinearLayout.LayoutParams(0, dp(48), 1f))
        addView(badge(), LinearLayout.LayoutParams(dp(72), dp(40)).apply {
            marginStart = dp(6)
            marginEnd = dp(3)
        })
        addView(action("↻", "Tải lại", onReload))
        addView(action("?", "Hướng dẫn", onHelp))
        addView(action("⇄", "Chọn người dùng", onClose))
    }

    private fun profilePicker(sessions: List<StoredWebSession>, currentId: String) =
        TextView(activity).apply {
            val current = sessions.firstOrNull { it.id == currentId }
            text = "${current?.name ?: "Người dùng"}  ▼"
            textSize = 16f
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
            gravity = Gravity.CENTER_VERTICAL
            setTextColor(0xFF0AA06E.toInt())
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            background = rounded(0xFFEAF9E8.toInt(), dp(24), 0)
            setPadding(dp(14), 0, dp(10), 0)
            contentDescription = "Chuyển hoặc thêm người dùng"
            setOnClickListener { showProfiles(this, sessions, currentId) }
        }

    private fun showProfiles(anchor: View, sessions: List<StoredWebSession>, currentId: String) {
        val popup = PopupMenu(activity, anchor)
        sessions.forEachIndexed { index, item ->
            val prefix = if (item.id == currentId) "✓  " else "     "
            popup.menu.add(0, index, index, "$prefix${item.name}")
        }
        popup.menu.add(1, ADD_ACCOUNT_ID, sessions.size + 1, "＋  Thêm tài khoản")
        popup.menu.setGroupDividerEnabled(true)
        popup.setOnMenuItemClickListener { item ->
            if (item.itemId == ADD_ACCOUNT_ID) onAdd()
            else sessions.getOrNull(item.itemId)?.let { onSelect(it.id) }
            true
        }
        popup.show()
    }

    private fun badge() = TextView(activity).apply {
        text = "♕ WA"
        textSize = 18f
        setTextColor(0xFFD0A51B.toInt())
        gravity = Gravity.CENTER
        typeface = android.graphics.Typeface.DEFAULT_BOLD
        background = rounded(Color.WHITE, dp(20), 0xFFD0A51B.toInt())
    }

    private fun action(label: String, description: String, listener: () -> Unit) =
        TextView(activity).apply {
            text = label
            textSize = if (label == "?") 22f else 30f
            gravity = Gravity.CENTER
            setTextColor(0xFF252525.toInt())
            contentDescription = description
            isClickable = true
            isFocusable = true
            setOnClickListener { listener() }
            layoutParams = ViewGroup.LayoutParams(dp(44), dp(48))
        }

    private fun rounded(color: Int, radius: Int, stroke: Int) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = radius.toFloat()
        if (stroke != 0) setStroke(dp(2), stroke)
    }

    private fun dp(value: Int) = (value * density).toInt()

    companion object {
        private const val ADD_ACCOUNT_ID = 10_000
    }
}
