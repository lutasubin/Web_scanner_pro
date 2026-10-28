package com.weappsinc.webscanerpro.web

import android.app.Activity
import android.app.Dialog
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.text.SpannableString
import android.text.style.StyleSpan
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.ScrollView
import android.widget.TextView
import com.weappsinc.webscanerpro.R
import kotlin.math.min

/**
 * Dialogs and BottomSheets matching the original app's WebActivity UI:
 * 1. Illustrated Help BottomSheet (Android & iOS tabs, QR & Phone Code modes)
 * 2. Switch Display Mode Dialog (Advanced Mobile Mode vs Basic Desktop Mode)
 * 3. First-Login Security Reminder Dialog (Dual WA ready / Mute notification guide)
 */
object WebHelpDialogs {

    fun showHelpSheet(
        activity: Activity,
        initialMode: String,
        onSwitchLoginMode: ((String) -> Unit)? = null,
        onDismiss: (() -> Unit)? = null,
    ) {
        if (activity.isFinishing || activity.isDestroyed) return
        val density = activity.resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        var currentMode = if (initialMode == WebMobileLayout.MODE_CODE) {
            WebMobileLayout.MODE_CODE
        } else {
            WebMobileLayout.MODE_QR
        }
        var isAndroidTab = true

        val dialog = Dialog(activity)
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)

        val root = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadii = floatArrayOf(
                    dp(24).toFloat(), dp(24).toFloat(),
                    dp(24).toFloat(), dp(24).toFloat(),
                    0f, 0f, 0f, 0f,
                )
            }
            setPadding(dp(20), dp(14), dp(20), dp(20))
        }

        // Drag handle bar
        root.addView(
            View(activity).apply {
                background = rounded(0xFFDADCE0.toInt(), dp(3))
            },
            LinearLayout.LayoutParams(dp(42), dp(5)).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dp(14)
            },
        )

        // Top mode selector pill + Close button row
        val modeIcon = ImageView(activity).apply {
            scaleType = ImageView.ScaleType.FIT_CENTER
        }
        val modeLabel = TextView(activity).apply {
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(TEXT_DARK)
            setPadding(dp(8), 0, dp(16), 0)
        }
        val modeArrow = TextView(activity).apply {
            text = "▼"
            textSize = 11f
            setTextColor(TEXT_MUTED)
        }
        val modePill = LinearLayout(activity).apply {
            gravity = Gravity.CENTER_VERTICAL
            background = rounded(0xFFF3F6F5.toInt(), dp(12), 0xFFE0E5E3.toInt())
            setPadding(dp(12), dp(9), dp(12), dp(9))
            addView(modeIcon, LinearLayout.LayoutParams(dp(20), dp(20)))
            addView(modeLabel)
            addView(modeArrow)
        }

        val titleView = TextView(activity).apply {
            textSize = 20f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(TEXT_DARK)
        }

        val stepsContainer = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
        }

        lateinit var tabAndroid: TextView
        lateinit var tabIos: TextView

        fun updateTabStyles() {
            tabAndroid.apply {
                setTextColor(if (isAndroidTab) Color.WHITE else TEXT_DARK)
                typeface = if (isAndroidTab) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
                background = rounded(if (isAndroidTab) GREEN else Color.TRANSPARENT, dp(10))
            }
            tabIos.apply {
                setTextColor(if (!isAndroidTab) Color.WHITE else TEXT_DARK)
                typeface = if (!isAndroidTab) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
                background = rounded(if (!isAndroidTab) GREEN else Color.TRANSPARENT, dp(10))
            }
        }

        fun renderSteps() {
            val isQr = currentMode == WebMobileLayout.MODE_QR
            modeIcon.setImageResource(
                if (isQr) R.drawable.ic_login_qr else R.drawable.ic_login_code,
            )
            modeLabel.text = if (isQr) "Mã QR" else "Số điện thoại"
            titleView.text = if (isQr) "Cách sử dụng?" else "Nhập mã ở đâu?"
            updateTabStyles()

            stepsContainer.removeAllViews()
            if (isAndroidTab) {
                stepsContainer.addView(
                    stepBlock(
                        activity,
                        dp = ::dp,
                        number = "1",
                        fullText = "Tìm ‘Thiết bị được liên kết’ trong WhatsApp trên điện thoại chính.",
                        boldPart = "‘Thiết bị được liên kết’ trong WhatsApp",
                        imageRes = R.drawable.help_ad_1,
                        badgeLabel = "Thiết bị được liên kết",
                    ),
                )
                stepsContainer.addView(
                    stepBlock(
                        activity,
                        dp = ::dp,
                        number = "2",
                        fullText = "Nhấn ‘Liên kết thiết bị’",
                        boldPart = "‘Liên kết thiết bị’",
                        imageRes = R.drawable.help_step_2,
                        badgeLabel = "Liên kết thiết bị",
                    ),
                )
                if (isQr) {
                    stepsContainer.addView(
                        stepBlock(
                            activity,
                            dp = ::dp,
                            number = "3",
                            fullText = "Quét mã QR hiển thị trong ứng dụng này.",
                            boldPart = "Quét mã QR",
                            imageRes = null,
                        ),
                    )
                } else {
                    stepsContainer.addView(
                        stepBlock(
                            activity,
                            dp = ::dp,
                            number = "3",
                            fullText = "Nhấn ‘Liên kết bằng số điện thoại’ ở dưới màn hình quét rồi nhập mã 8 ký tự.",
                            boldPart = "‘Liên kết bằng số điện thoại’",
                            imageRes = R.drawable.help_and_3,
                            badgeLabel = "Liên kết bằng số điện thoại",
                        ),
                    )
                }
            } else {
                stepsContainer.addView(
                    stepBlock(
                        activity,
                        dp = ::dp,
                        number = "1",
                        fullText = "Tìm cài đặt ‘Thiết bị được liên kết’ trong WhatsApp trên iPhone.",
                        boldPart = "‘Thiết bị được liên kết’ trong WhatsApp",
                        imageRes = R.drawable.help_ios_1,
                        badgeLabel = "Thiết bị được liên kết",
                    ),
                )
                stepsContainer.addView(
                    stepBlock(
                        activity,
                        dp = ::dp,
                        number = "2",
                        fullText = "Nhấn ‘Liên kết thiết bị’",
                        boldPart = "‘Liên kết thiết bị’",
                        imageRes = R.drawable.help_step_2,
                        badgeLabel = "Liên kết thiết bị",
                    ),
                )
                if (isQr) {
                    stepsContainer.addView(
                        stepBlock(
                            activity,
                            dp = ::dp,
                            number = "3",
                            fullText = "Quét mã QR hiển thị trong ứng dụng này.",
                            boldPart = "Quét mã QR",
                            imageRes = null,
                        ),
                    )
                } else {
                    stepsContainer.addView(
                        stepBlock(
                            activity,
                            dp = ::dp,
                            number = "3",
                            fullText = "Nhấn ‘Liên kết bằng số điện thoại’ và nhập mã 8 ký tự đã sao chép.",
                            boldPart = "‘Liên kết bằng số điện thoại’",
                            imageRes = R.drawable.help_ios_3,
                            badgeLabel = "Liên kết bằng số điện thoại",
                        ),
                    )
                }
            }
        }

        modePill.setOnClickListener { anchor ->
            showLoginModePopup(activity, anchor, currentMode) { selectedMode ->
                if (currentMode != selectedMode) {
                    currentMode = selectedMode
                    renderSteps()
                    onSwitchLoginMode?.invoke(selectedMode)
                }
            }
        }

        val topRow = LinearLayout(activity).apply {
            gravity = Gravity.CENTER_VERTICAL
            addView(modePill)
            addView(View(activity), LinearLayout.LayoutParams(0, 1, 1f))
            addView(
                TextView(activity).apply {
                    text = "✕"
                    textSize = 18f
                    setTextColor(TEXT_MUTED)
                    gravity = Gravity.CENTER
                    setPadding(dp(8), dp(4), dp(8), dp(4))
                    setOnClickListener { dialog.dismiss() }
                },
            )
        }
        root.addView(topRow)
        root.addView(
            titleView,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                topMargin = dp(12)
                bottomMargin = dp(12)
            },
        )

        // Android / iOS Segmented Tab Bar
        val tabBar = LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL
            background = rounded(0xFFF1F4F3.toInt(), dp(12))
            setPadding(dp(4), dp(4), dp(4), dp(4))
        }
        tabAndroid = TextView(activity).apply {
            text = "🤖  Android"
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(0, dp(10), 0, dp(10))
            setOnClickListener {
                if (!isAndroidTab) {
                    isAndroidTab = true
                    renderSteps()
                }
            }
        }
        tabIos = TextView(activity).apply {
            text = "📱  iPhone (iOS)"
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(0, dp(10), 0, dp(10))
            setOnClickListener {
                if (isAndroidTab) {
                    isAndroidTab = false
                    renderSteps()
                }
            }
        }
        tabBar.addView(tabAndroid, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        tabBar.addView(tabIos, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        root.addView(
            tabBar,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                bottomMargin = dp(14)
            },
        )

        val scroll = ScrollView(activity).apply {
            isVerticalScrollBarEnabled = false
            addView(stepsContainer)
        }
        val maxScrollHeight = (activity.resources.displayMetrics.heightPixels * 0.56f).toInt()
        root.addView(
            scroll,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, maxScrollHeight),
        )

        // Bottom OK Button
        root.addView(
            TextView(activity).apply {
                text = "Đã hiểu"
                textSize = 17f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                background = rounded(GREEN, dp(14))
                setPadding(0, dp(14), 0, dp(14))
                setOnClickListener { dialog.dismiss() }
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                topMargin = dp(14)
            },
        )

        renderSteps()

        dialog.setContentView(root)
        dialog.setOnDismissListener { onDismiss?.invoke() }
        dialog.window?.apply {
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            setGravity(Gravity.BOTTOM)
        }
        dialog.show()
    }

    fun showLoginModePopup(
        activity: Activity,
        anchor: View,
        currentMode: String,
        onSelect: (String) -> Unit,
    ) {
        val density = activity.resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        lateinit var popup: PopupWindow
        val panel = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(Color.WHITE, dp(12), 0x1A000000)
            setPadding(dp(6), dp(6), dp(6), dp(6))
        }

        fun modeOption(mode: String, iconRes: Int, label: String): View {
            val selected = currentMode == mode
            return LinearLayout(activity).apply {
                gravity = Gravity.CENTER_VERTICAL
                setPadding(dp(12), dp(10), dp(12), dp(10))
                background = rounded(if (selected) PALE_GREEN else Color.TRANSPARENT, dp(8))
                setOnClickListener {
                    popup.dismiss()
                    onSelect(mode)
                }
                addView(
                    ImageView(activity).apply {
                        setImageResource(iconRes)
                        scaleType = ImageView.ScaleType.FIT_CENTER
                    },
                    LinearLayout.LayoutParams(dp(22), dp(22)),
                )
                addView(
                    TextView(activity).apply {
                        text = label
                        textSize = 14f
                        setTextColor(TEXT_DARK)
                        typeface = if (selected) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
                    },
                    LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                        marginStart = dp(10)
                        marginEnd = dp(14)
                    },
                )
                if (selected) {
                    addView(
                        ImageView(activity).apply {
                            setImageResource(R.drawable.ic_web_check)
                        },
                        LinearLayout.LayoutParams(dp(18), dp(18)),
                    )
                }
            }
        }

        panel.addView(modeOption(WebMobileLayout.MODE_QR, R.drawable.ic_login_qr, "Mã QR"))
        panel.addView(modeOption(WebMobileLayout.MODE_CODE, R.drawable.ic_login_code, "Số điện thoại"))

        popup = PopupWindow(
            panel,
            dp(210),
            ViewGroup.LayoutParams.WRAP_CONTENT,
            true,
        ).apply {
            isOutsideTouchable = true
            elevation = dp(8).toFloat()
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        }
        popup.showAsDropDown(anchor, 0, dp(4))
    }

    /**
     * Dialog matching `dialog_mode.xml` in the original app:
     * Switches between Advanced Mode (`webMode = 0`) and Basic Mode (`webMode = 1`).
     */
    fun showDisplayModeDialog(
        activity: Activity,
        currentWebMode: Int,
        onSelectMode: (Int) -> Unit,
    ) {
        if (activity.isFinishing || activity.isDestroyed) return
        val density = activity.resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val dialog = Dialog(activity)
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)

        val root = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadii = floatArrayOf(
                    dp(24).toFloat(), dp(24).toFloat(),
                    dp(24).toFloat(), dp(24).toFloat(),
                    0f, 0f, 0f, 0f,
                )
            }
            setPadding(dp(18), dp(16), dp(18), dp(24))
        }

        root.addView(
            View(activity).apply {
                background = rounded(0xFFDADCE0.toInt(), dp(3))
            },
            LinearLayout.LayoutParams(dp(42), dp(5)).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dp(14)
            },
        )

        root.addView(
            TextView(activity).apply {
                text = "Chuyển chế độ hiển thị"
                textSize = 19f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(TEXT_DARK)
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                bottomMargin = dp(14)
            },
        )

        fun modeCard(
            modeValue: Int,
            imageRes: Int,
            title: String,
            description: String,
        ): View {
            val selected = currentWebMode == modeValue
            return LinearLayout(activity).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(dp(14), dp(14), dp(14), dp(14))
                background = rounded(
                    if (selected) PALE_GREEN else 0xFFF7F9F8.toInt(),
                    dp(16),
                    if (selected) GREEN else 0xFFE1E6E4.toInt(),
                )
                setOnClickListener {
                    dialog.dismiss()
                    if (currentWebMode != modeValue) {
                        onSelectMode(modeValue)
                    }
                }
                addView(
                    ImageView(activity).apply {
                        setImageResource(imageRes)
                        adjustViewBounds = true
                        scaleType = ImageView.ScaleType.FIT_CENTER
                    },
                    LinearLayout.LayoutParams(dp(86), ViewGroup.LayoutParams.WRAP_CONTENT),
                )
                addView(
                    LinearLayout(activity).apply {
                        orientation = LinearLayout.VERTICAL
                        addView(
                            LinearLayout(activity).apply {
                                gravity = Gravity.CENTER_VERTICAL
                                addView(
                                    TextView(activity).apply {
                                        text = title
                                        textSize = 17f
                                        typeface = Typeface.DEFAULT_BOLD
                                        setTextColor(TEXT_DARK)
                                    },
                                    LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f),
                                )
                                if (selected) {
                                    addView(
                                        ImageView(activity).apply {
                                            setImageResource(R.drawable.ic_web_check)
                                        },
                                        LinearLayout.LayoutParams(dp(22), dp(22)),
                                    )
                                }
                            },
                        )
                        addView(
                            TextView(activity).apply {
                                text = description
                                textSize = 13.5f
                                setTextColor(TEXT_MUTED)
                            },
                            LinearLayout.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.WRAP_CONTENT,
                            ).apply {
                                topMargin = dp(6)
                            },
                        )
                    },
                    LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                        marginStart = dp(14)
                    },
                )
            }
        }

        root.addView(
            modeCard(
                modeValue = 0,
                imageRes = R.drawable.advanced_mode,
                title = "Chế độ nâng cao",
                description = "Giao diện cải tiến tối ưu cho màn hình điện thoại (1 cột danh sách & trò chuyện).",
            ),
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                bottomMargin = dp(12)
            },
        )

        root.addView(
            modeCard(
                modeValue = 1,
                imageRes = R.drawable.basic_mode,
                title = "Chế độ cơ bản",
                description = "Giao diện WhatsApp Web tiêu chuẩn giống máy tính. Vuốt ngang để xem toàn bộ.",
            ),
        )

        dialog.setContentView(root)
        dialog.window?.apply {
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            setGravity(Gravity.BOTTOM)
        }
        dialog.show()
    }

    /**
     * Dialog matching `dialog_dual_ready_new.xml` (`f.java`) shown once after the first login.
     */
    fun showFirstLoginSecurityDialog(activity: Activity) {
        if (activity.isFinishing || activity.isDestroyed) return
        val density = activity.resources.displayMetrics.density
        fun dp(v: Int) = (v * density).toInt()

        val dialog = Dialog(activity)
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)

        val root = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            background = rounded(Color.WHITE, dp(20))
            setPadding(dp(20), dp(22), dp(20), dp(20))
        }

        root.addView(
            ImageView(activity).apply {
                setImageResource(R.drawable.ic_notify_hint_new)
                scaleType = ImageView.ScaleType.FIT_CENTER
            },
            LinearLayout.LayoutParams(dp(64), dp(64)),
        )

        root.addView(
            TextView(activity).apply {
                text = "Dual WA đã sẵn sàng!"
                textSize = 20f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(TEXT_DARK)
                gravity = Gravity.CENTER
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                topMargin = dp(14)
            },
        )

        root.addView(
            TextView(activity).apply {
                text = "Trên điện thoại chính của chủ tài khoản:"
                textSize = 15f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(TEXT_DARK)
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                topMargin = dp(18)
                bottomMargin = dp(10)
            },
        )

        fun bulletStep(number: String, full: String, bold: String): View {
            return LinearLayout(activity).apply {
                gravity = Gravity.CENTER_VERTICAL
                background = rounded(0xFFF5F8F7.toInt(), dp(10))
                setPadding(dp(12), dp(10), dp(12), dp(10))
                addView(
                    TextView(activity).apply {
                        text = number
                        textSize = 13f
                        typeface = Typeface.DEFAULT_BOLD
                        setTextColor(Color.WHITE)
                        gravity = Gravity.CENTER
                        background = rounded(GREEN, dp(11))
                    },
                    LinearLayout.LayoutParams(dp(22), dp(22)),
                )
                addView(
                    TextView(activity).apply {
                        text = boldSubstring(full, bold)
                        textSize = 14.5f
                        setTextColor(TEXT_DARK)
                    },
                    LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                        marginStart = dp(10)
                    },
                )
            }
        }

        root.addView(
            bulletStep("1", "Mở Trung tâm thông báo", "Trung tâm thông báo"),
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { bottomMargin = dp(8) },
        )
        root.addView(
            bulletStep("2", "Tìm thông báo “Thiết bị mới được liên kết”", "“Thiết bị mới được liên kết”"),
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { bottomMargin = dp(8) },
        )
        root.addView(
            bulletStep("3", "Xóa hoặc tắt thông báo đó nếu cần", "Xóa"),
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { bottomMargin = dp(14) },
        )

        root.addView(
            LinearLayout(activity).apply {
                orientation = LinearLayout.VERTICAL
                background = rounded(0xFFFFF8E7.toInt(), dp(10))
                setPadding(dp(12), dp(10), dp(12), dp(10))
                addView(
                    TextView(activity).apply {
                        text = "Ghi chú:"
                        textSize = 12.5f
                        typeface = Typeface.DEFAULT_BOLD
                        setTextColor(TEXT_MUTED)
                    },
                )
                addView(
                    TextView(activity).apply {
                        text = "Một thông báo xác nhận liên kết thiết bị được gửi tới điện thoại chính. Hãy kiểm tra để quản lý phiên đăng nhập an toàn."
                        textSize = 12.5f
                        setTextColor(TEXT_MUTED)
                    },
                )
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { bottomMargin = dp(18) },
        )

        root.addView(
            TextView(activity).apply {
                text = "Hoàn tất"
                textSize = 17f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                background = rounded(GREEN, dp(12))
                setPadding(0, dp(13), 0, dp(13))
                setOnClickListener { dialog.dismiss() }
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ),
        )

        dialog.setContentView(root)
        val maxWidth = min(
            (activity.resources.displayMetrics.widthPixels * 0.90f).toInt(),
            dp(380),
        )
        dialog.window?.apply {
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            setLayout(maxWidth, ViewGroup.LayoutParams.WRAP_CONTENT)
            setGravity(Gravity.CENTER)
        }
        dialog.show()
    }

    private fun stepBlock(
        activity: Activity,
        dp: (Int) -> Int,
        number: String,
        fullText: String,
        boldPart: String,
        imageRes: Int?,
        badgeLabel: String? = null,
    ): View = LinearLayout(activity).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(0, dp(6), 0, dp(14))
        addView(
            LinearLayout(activity).apply {
                gravity = Gravity.CENTER_VERTICAL
                addView(
                    TextView(activity).apply {
                        text = number
                        textSize = 13f
                        typeface = Typeface.DEFAULT_BOLD
                        setTextColor(Color.WHITE)
                        gravity = Gravity.CENTER
                        background = rounded(GREEN, dp(11))
                    },
                    LinearLayout.LayoutParams(dp(22), dp(22)),
                )
                addView(
                    TextView(activity).apply {
                        text = boldSubstring(fullText, boldPart)
                        textSize = 15.5f
                        setTextColor(TEXT_DARK)
                    },
                    LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                        marginStart = dp(10)
                    },
                )
            },
        )
        if (imageRes != null) {
            addView(
                FrameLayout(activity).apply {
                    addView(
                        ImageView(activity).apply {
                            setImageResource(imageRes)
                            adjustViewBounds = true
                            scaleType = ImageView.ScaleType.FIT_CENTER
                        },
                        FrameLayout.LayoutParams(
                            dp(236),
                            ViewGroup.LayoutParams.WRAP_CONTENT,
                            Gravity.CENTER,
                        ),
                    )
                    if (!badgeLabel.isNullOrBlank()) {
                        addView(
                            TextView(activity).apply {
                                text = badgeLabel
                                textSize = 11.5f
                                typeface = Typeface.DEFAULT_BOLD
                                setTextColor(Color.WHITE)
                                background = rounded(0xCC00A884.toInt(), dp(8))
                                setPadding(dp(10), dp(4), dp(10), dp(4))
                            },
                            FrameLayout.LayoutParams(
                                ViewGroup.LayoutParams.WRAP_CONTENT,
                                ViewGroup.LayoutParams.WRAP_CONTENT,
                                Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL,
                            ).apply {
                                bottomMargin = dp(10)
                            },
                        )
                    }
                },
                LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                ).apply {
                    topMargin = dp(10)
                },
            )
        }
    }

    private fun boldSubstring(full: String, boldPart: String): CharSequence {
        val index = full.indexOf(boldPart)
        if (index < 0) return full
        return SpannableString(full).apply {
            setSpan(StyleSpan(Typeface.BOLD), index, index + boldPart.length, 0)
        }
    }

    private fun rounded(color: Int, radius: Int, stroke: Int = 0) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = radius.toFloat()
        if (stroke != 0) setStroke(2, stroke)
    }

    private const val GREEN = 0xFF00A884.toInt()
    private const val PALE_GREEN = 0xFFE9F8E7.toInt()
    private const val TEXT_DARK = 0xFF1F2C34.toInt()
    private const val TEXT_MUTED = 0xFF5F6368.toInt()
}
