package com.weappsinc.webscanerpro.web

import android.content.Context
import android.webkit.WebView

class FixedWidthWebView(context: Context) : WebView(context) {
    var allowHorizontalScroll: Boolean = false

    override fun scrollTo(x: Int, y: Int) =
        super.scrollTo(if (allowHorizontalScroll) x else 0, y)

    override fun scrollBy(x: Int, y: Int) =
        super.scrollBy(if (allowHorizontalScroll) x else 0, y)

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
        if (allowHorizontalScroll) deltaX else 0,
        deltaY,
        if (allowHorizontalScroll) scrollX else 0,
        scrollY,
        if (allowHorizontalScroll) scrollRangeX else 0,
        scrollRangeY,
        if (allowHorizontalScroll) maxOverScrollX else 0,
        maxOverScrollY,
        isTouchEvent,
    )
}
