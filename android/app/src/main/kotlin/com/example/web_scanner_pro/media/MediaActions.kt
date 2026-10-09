package com.example.web_scanner_pro.media

import android.app.Activity
import android.content.ClipData
import android.content.Intent

internal class MediaActions(private val activity: Activity) {
    fun open(record: MediaRecord, share: Boolean) {
        val intent = if (share) {
            Intent(Intent.ACTION_SEND).apply {
                type = record.mimeType
                putExtra(Intent.EXTRA_STREAM, record.uri)
            }
        } else {
            Intent(Intent.ACTION_VIEW).setDataAndType(record.uri, record.mimeType)
        }
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        intent.clipData = ClipData.newRawUri(record.name, record.uri)
        activity.startActivity(if (share) Intent.createChooser(intent, "Chia sẻ tệp") else intent)
    }
}
