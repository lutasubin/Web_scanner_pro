package com.example.web_scanner_pro.web

import android.content.Context
import android.webkit.WebView

class FixedWidthWebView(context: Context) : WebView(context) {
    override fun scrollTo(x: Int, y: Int) = super.scrollTo(0, y)

    override fun scrollBy(x: Int, y: Int) = super.scrollBy(0, y)

    override fun overScrollBy(
        deltaX: Int,
        deltaY: Int,
        scrollX: Int,
        scrollY: Int,
        scrollRangeX: Int,
        scrollRangeY: Int,
        maxOverScrollX: Int,
        maxOverScrollY: Int,
        isTouchEvent: Boolean,
    ): Boolean = super.overScrollBy(
        0,
        deltaY,
        0,
        scrollY,
        0,
        scrollRangeY,
        0,
        maxOverScrollY,
        isTouchEvent,
    )
}
