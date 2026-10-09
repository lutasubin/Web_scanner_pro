package com.example.web_scanner_pro.web

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.content.res.ColorStateList
import android.text.SpannableString
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import kotlin.math.min

class QrLoginOverlay(
    context: Context,
    private val onHelp: () -> Unit,
    private val onPhoneLogin: () -> Unit,
) : FrameLayout(context) {
    private val density = resources.displayMetrics.density
    private val qrImage = ImageView(context)
    private val qrLoading = ProgressBar(context)

    init {
        setBackgroundColor(BACKGROUND)
        addView(ScrollView(context).apply {
            isFillViewport = true
            isHorizontalScrollBarEnabled = false
            addView(content())
        }, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        addView(floatingCall(), LayoutParams(dp(58), dp(58), Gravity.END or Gravity.BOTTOM).apply {
            marginEnd = dp(18)
            bottomMargin = dp(20)
        })
    }

    fun showLoading() {
        visibility = View.VISIBLE
        qrImage.visibility = View.INVISIBLE
        qrLoading.visibility = View.VISIBLE
    }

    fun showQr(bitmap: Bitmap) {
        qrImage.setImageBitmap(bitmap)
        qrImage.visibility = View.VISIBLE
        qrLoading.visibility = View.GONE
    }

    private fun content() = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(10), dp(8), dp(10), dp(24))
        addView(brand())
        addView(card(), LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(82)
            marginStart = dp(4)
            marginEnd = dp(4)
        })
        addView(footer())
    }

    private fun brand() = LinearLayout(context).apply {
        gravity = Gravity.CENTER_VERTICAL
        addView(brandIcon(BRAND_GREEN), LinearLayout.LayoutParams(dp(19), dp(19)))
        addView(label("WhatsApp", 12f, BRAND_GREEN, true), LinearLayout.LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply { marginStart = dp(4) })
    }

    private fun card() = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        setPadding(dp(22), dp(24), dp(22), dp(22))
        background = rounded(Color.WHITE, dp(20), OUTLINE)
        val screenWidthDp = resources.displayMetrics.widthPixels / density
        val qrSize = dp(min(172f, screenWidthDp - 150f).toInt())
        addView(FrameLayout(context).apply {
            addView(qrImage, LayoutParams(qrSize, qrSize).apply { gravity = Gravity.CENTER })
            addView(qrLoading, LayoutParams(dp(52), dp(52)).apply { gravity = Gravity.CENTER })
            addView(brandIcon(QR_INK).apply {
                setPadding(dp(8), dp(8), dp(8), dp(8))
                background = rounded(Color.WHITE, dp(20), 0)
            }, LayoutParams(dp(40), dp(40)).apply { gravity = Gravity.CENTER })
        }, LinearLayout.LayoutParams(qrSize, qrSize))
        addView(label("Quét mã để đăng nhập", 25f, Color.BLACK, false).apply {
            gravity = Gravity.CENTER
        }, margin(top = 18, bottom = 24))
        addView(step("1", "Quét mã QR bằng camera trên điện thoại", first = true))
        addView(step("2", "Nhấn vào liên kết để mở WhatsApp", showWhatsApp = true))
        addView(step("3", "Quét lại mã QR để liên kết với tài khoản của bạn", last = true))
        addView(link("Bạn cần trợ giúp?", "↗", onHelp), margin(top = 12, bottom = 18))
        addView(divider())
        addView(keepSignedIn(), margin(top = 16))
        addView(link("Đăng nhập bằng số điện thoại", "›", onPhoneLogin), margin(top = 20))
    }

    private fun step(
        number: String,
        text: String,
        first: Boolean = false,
        last: Boolean = false,
        showWhatsApp: Boolean = false,
    ) = LinearLayout(context).apply {
        gravity = Gravity.CENTER_VERTICAL
        addView(numberMarker(number, first, last), LinearLayout.LayoutParams(dp(25), dp(27)))
        addView(label(text, 14f, TEXT_DARK, false), LinearLayout.LayoutParams(
            if (showWhatsApp) LayoutParams.WRAP_CONTENT else 0,
            LayoutParams.WRAP_CONTENT,
            if (showWhatsApp) 0f else 1f,
        ).apply {
            marginStart = dp(10)
        })
        if (showWhatsApp) addView(brandIcon(Color.WHITE).apply {
            setPadding(dp(2), dp(2), dp(2), dp(2))
            background = rounded(BRAND_GREEN, dp(4), 0)
        }, LinearLayout.LayoutParams(dp(17), dp(17)).apply { marginStart = dp(5) })
    }

    private fun numberMarker(number: String, first: Boolean, last: Boolean) = FrameLayout(context).apply {
        addView(View(context).apply { setBackgroundColor(OUTLINE) }, LayoutParams(dp(1),
            if (first || last) dp(14) else LayoutParams.MATCH_PARENT).apply {
            gravity = if (first) Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL else Gravity.TOP or Gravity.CENTER_HORIZONTAL
        })
        addView(TextView(context).apply {
            text = number
            textSize = 12f
            setTextColor(TEXT_DARK)
            gravity = Gravity.CENTER
            background = rounded(Color.WHITE, dp(13), OUTLINE)
        }, LayoutParams(dp(25), dp(25)).apply { gravity = Gravity.CENTER })
    }

    private fun keepSignedIn() = LinearLayout(context).apply {
        gravity = Gravity.CENTER_VERTICAL
        addView(label("✓", 17f, Color.WHITE, true).apply {
            gravity = Gravity.CENTER
            background = rounded(ACTION_GREEN, dp(3), 0)
        }, LinearLayout.LayoutParams(dp(18), dp(18)))
        addView(label("Duy trì đăng nhập trên trình duyệt này  ⓘ", 14f, TEXT_DARK, true),
            LinearLayout.LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f).apply { marginStart = dp(12) })
    }

    private fun footer() = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
        addView(centered("Bạn không có tài khoản WhatsApp?  Bắt đầu ↗", 13f, 0xFF454545.toInt()), margin(top = 18))
        addView(centered("🔒  Tin nhắn cá nhân được mã hóa đầu cuối", 12f, 0xFF777777.toInt()), margin(top = 14))
        addView(centered("Điều khoản và Chính sách quyền riêng tư", 10f, 0xFF999999.toInt()), margin(top = 16))
    }

    private fun floatingCall() = brandIcon(Color.WHITE).apply {
        setPadding(dp(13), dp(13), dp(13), dp(13))
        elevation = dp(6).toFloat()
        background = rounded(0xFF10C878.toInt(), dp(29), 0)
        contentDescription = "Trợ giúp WhatsApp"
        setOnClickListener { onHelp() }
    }

    private fun brandIcon(tint: Int) = ImageView(context).apply {
        setImageResource(com.example.web_scanner_pro.R.drawable.ic_whatsapp_brand)
        imageTintList = ColorStateList.valueOf(tint)
        scaleType = ImageView.ScaleType.FIT_CENTER
    }

    private fun centered(text: String, size: Float, color: Int) = label(text, size, color, false).apply {
        gravity = Gravity.CENTER
    }

    private fun link(label: String, suffix: String, click: () -> Unit) = TextView(context).apply {
        val value = "$label  $suffix"
        text = SpannableString(value).apply {
            setSpan(ColoredUnderlineSpan(ACTION_GREEN, density * 1.5f), 0, label.length, 0)
        }
        textSize = 13f
        setTextColor(TEXT_DARK)
        typeface = Typeface.DEFAULT_BOLD
        setOnClickListener { click() }
    }

    private fun label(text: String, size: Float, color: Int, bold: Boolean) = TextView(context).apply {
        this.text = text
        textSize = size
        setTextColor(color)
        if (bold) typeface = Typeface.DEFAULT_BOLD
    }

    private fun divider() = View(context).apply { setBackgroundColor(0xFFE9EDEF.toInt()) }.also {
        it.layoutParams = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, dp(1))
    }

    private fun margin(top: Int = 0, bottom: Int = 0) =
        LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(top)
            bottomMargin = dp(bottom)
        }

    private fun rounded(color: Int, radius: Int, stroke: Int) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = radius.toFloat()
        if (stroke != 0) setStroke(dp(1), stroke)
    }

    private fun dp(value: Int) = (value * density).toInt()

    companion object {
        private const val BRAND_GREEN = 0xFF25D366.toInt()
        private const val ACTION_GREEN = 0xFF00A884.toInt()
        private const val QR_INK = 0xFF0B3B3D.toInt()
        private const val TEXT_DARK = 0xFF1F2C34.toInt()
        private const val OUTLINE = 0xFF8696A0.toInt()
        private const val BACKGROUND = 0xFFFFFAED.toInt()
    }
}
