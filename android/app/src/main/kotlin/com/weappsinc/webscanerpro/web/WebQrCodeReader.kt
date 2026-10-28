package com.weappsinc.webscanerpro.web

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import org.json.JSONArray

object WebQrCodeReader {
    const val SCRIPT = "(function(){" +
        "var root=document.querySelector(\"[data-testid='qrcode']\");" +
        "var canvas=(root&&root.querySelector('canvas'))||document.querySelector('canvas');" +
        "if(!canvas||!canvas.width||!canvas.height)return null;" +
        "try{return canvas.toDataURL('image/png');}catch(e){return null;}" +
        "})()"

    fun decode(result: String?): Bitmap? {
        if (result == null || result == "null") return null
        return try {
            val dataUrl = JSONArray("[$result]").getString(0)
            val encoded = dataUrl.substringAfter(',', "")
            if (encoded.isEmpty()) return null
            val bytes = Base64.decode(encoded, Base64.DEFAULT)
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        } catch (_: Exception) {
            null
        }
    }
}
