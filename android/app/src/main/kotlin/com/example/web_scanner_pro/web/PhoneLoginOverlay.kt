package com.example.web_scanner_pro.web

import android.app.AlertDialog
import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/** A fixed-width native shell for WhatsApp's phone-number login form. */
class PhoneLoginOverlay(
    context: Context,
    private val onContinue: (String) -> Unit,
    private val onQrLogin: () -> Unit,
    private val onHelp: () -> Unit,
) : FrameLayout(context) {
    private val density = resources.displayMetrics.density
    private val phoneInput = EditText(context)
    private var selectedCountry = COUNTRIES.first()
    private lateinit var countryValue: TextView
    private lateinit var prefixValue: TextView

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

    fun prepareForDisplay() {
        phoneInput.clearFocus()
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
        setPadding(dp(22), dp(28), dp(22), dp(24))
        background = rounded(Color.WHITE, dp(20), OUTLINE)

        addView(label("Nhập số điện thoại", 25f, TEXT_DARK, false).apply {
            gravity = Gravity.CENTER
        }, fullWidth())
        addView(label("Chọn quốc gia và nhập số điện thoại của bạn.", 13f, 0xFF54656F.toInt(), false).apply {
            gravity = Gravity.CENTER
        }, margin(top = 6, bottom = 24))

        countryValue = label(countryText(), 14f, TEXT_DARK, false).apply {
            gravity = Gravity.CENTER_VERTICAL
        }
        addView(LinearLayout(context).apply {
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16), 0, dp(14), 0)
            background = rounded(Color.WHITE, dp(22), OUTLINE)
            setOnClickListener { chooseCountry() }
            addView(countryValue, LinearLayout.LayoutParams(0, LayoutParams.MATCH_PARENT, 1f))
            addView(label("⌄", 16f, TEXT_DARK, false).apply { gravity = Gravity.CENTER },
                LinearLayout.LayoutParams(dp(24), LayoutParams.MATCH_PARENT))
        }, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, dp(46)))

        addView(LinearLayout(context).apply {
            gravity = Gravity.CENTER_VERTICAL
            background = rounded(Color.WHITE, dp(22), OUTLINE)
            prefixValue = label(selectedCountry.code, 14f, TEXT_DARK, false).apply {
                gravity = Gravity.CENTER
            }
            addView(prefixValue, LinearLayout.LayoutParams(dp(58), LayoutParams.MATCH_PARENT))
            addView(View(context).apply { setBackgroundColor(0xFFE9EDEF.toInt()) },
                LinearLayout.LayoutParams(dp(1), dp(24)))
            addView(phoneInput.apply {
                hint = "Số điện thoại"
                textSize = 14f
                setTextColor(TEXT_DARK)
                setHintTextColor(0xFF8696A0.toInt())
                inputType = InputType.TYPE_CLASS_PHONE
                setSingleLine(true)
                background = null
                setPadding(dp(12), 0, dp(12), 0)
            }, LinearLayout.LayoutParams(0, LayoutParams.MATCH_PARENT, 1f))
        }, LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, dp(46)).apply { topMargin = dp(12) })

        addView(TextView(context).apply {
            text = "Tiếp tục"
            textSize = 14f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = rounded(ACTION_GREEN, dp(22), 0)
            setPadding(dp(22), 0, dp(22), 0)
            setOnClickListener { submit() }
        }, LinearLayout.LayoutParams(LayoutParams.WRAP_CONTENT, dp(44)).apply {
            gravity = Gravity.CENTER_HORIZONTAL
            topMargin = dp(28)
        })

        addView(link("Đăng nhập bằng mã QR", "›", onQrLogin), margin(top = 22))
    }

    private fun chooseCountry() {
        val labels = COUNTRIES.map { "${it.flag}  ${it.name}  (${it.code})" }.toTypedArray()
        AlertDialog.Builder(context)
            .setTitle("Chọn quốc gia")
            .setSingleChoiceItems(labels, COUNTRIES.indexOf(selectedCountry)) { dialog, index ->
                selectedCountry = COUNTRIES[index]
                countryValue.text = countryText()
                prefixValue.text = selectedCountry.code
                dialog.dismiss()
            }
            .setNegativeButton("Hủy", null)
            .show()
    }

    private fun submit() {
        val local = phoneInput.text.toString().filter(Char::isDigit).trimStart('0')
        if (local.length !in 6..14) {
            phoneInput.error = "Nhập số điện thoại hợp lệ"
            phoneInput.requestFocus()
            return
        }
        val international = selectedCountry.code + local
        onContinue(international)
    }

    private fun countryText() = "${selectedCountry.flag}  ${selectedCountry.name}"

    private fun footer() = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
        addView(centered("Bạn chưa có tài khoản WhatsApp?  Bắt đầu ↗", 13f, 0xFF454545.toInt()), margin(top = 18))
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

    private fun link(label: String, suffix: String, click: () -> Unit) = TextView(context).apply {
        val value = "$label  $suffix"
        text = android.text.SpannableString(value).apply {
            setSpan(ColoredUnderlineSpan(ACTION_GREEN, density * 1.5f), 0, label.length, 0)
        }
        textSize = 13f
        setTextColor(TEXT_DARK)
        typeface = Typeface.DEFAULT_BOLD
        gravity = Gravity.CENTER
        setOnClickListener { click() }
    }

    private fun brandIcon(tint: Int) = ImageView(context).apply {
        setImageResource(com.example.web_scanner_pro.R.drawable.ic_whatsapp_brand)
        imageTintList = ColorStateList.valueOf(tint)
        scaleType = ImageView.ScaleType.FIT_CENTER
    }

    private fun centered(text: String, size: Float, color: Int) = label(text, size, color, false).apply {
        gravity = Gravity.CENTER
    }

    private fun label(text: String, size: Float, color: Int, bold: Boolean) = TextView(context).apply {
        this.text = text
        textSize = size
        setTextColor(color)
        if (bold) typeface = Typeface.DEFAULT_BOLD
    }

    private fun fullWidth() = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)

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

    private data class Country(val flag: String, val name: String, val code: String)

    companion object {
        private const val BRAND_GREEN = 0xFF25D366.toInt()
        private const val ACTION_GREEN = 0xFF00A884.toInt()
        private const val TEXT_DARK = 0xFF1F2C34.toInt()
        private const val OUTLINE = 0xFF8696A0.toInt()
        private const val BACKGROUND = 0xFFFFFAED.toInt()

        private val COUNTRIES = listOf(
            Country("🇻🇳", "Việt Nam", "+84"),
            Country("🇺🇸", "Hoa Kỳ", "+1"),
            Country("🇬🇧", "Vương quốc Anh", "+44"),
            Country("🇭🇰", "Hồng Kông", "+852"),
            Country("🇸🇬", "Singapore", "+65"),
            Country("🇹🇭", "Thái Lan", "+66"),
            Country("🇲🇾", "Malaysia", "+60"),
            Country("🇮🇩", "Indonesia", "+62"),
            Country("🇰🇷", "Hàn Quốc", "+82"),
            Country("🇯🇵", "Nhật Bản", "+81"),
        )
    }
}
