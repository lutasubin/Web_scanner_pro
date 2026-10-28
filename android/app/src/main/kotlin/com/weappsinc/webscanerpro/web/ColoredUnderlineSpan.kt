package com.weappsinc.webscanerpro.web

import android.text.TextPaint
import android.text.style.CharacterStyle
import android.text.style.UpdateAppearance

class ColoredUnderlineSpan(
    private val color: Int,
    private val thickness: Float,
) : CharacterStyle(), UpdateAppearance {
    override fun updateDrawState(textPaint: TextPaint) {
        textPaint.isUnderlineText = true
        textPaint.underlineColor = color
        textPaint.underlineThickness = thickness
    }
}
