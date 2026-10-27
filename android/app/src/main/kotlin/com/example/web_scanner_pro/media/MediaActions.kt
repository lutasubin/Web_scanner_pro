package com.example.web_scanner_pro.media

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import java.io.File

internal class MediaActions(private val activity: Activity) {
    fun open(record: MediaRecord, share: Boolean) {
        val safeUri = if (record.uri.scheme == "file" && record.uri.path != null) {
            runCatching {
                FileProvider.getUriForFile(
                    activity,
                    "${activity.packageName}.fileprovider",
                    File(record.uri.path!!),
                )
            }.getOrDefault(record.uri)
        } else {
            record.uri
        }
        val intent = if (share) {
            Intent(Intent.ACTION_SEND).apply {
                type = record.mimeType
                putExtra(Intent.EXTRA_STREAM, safeUri)
            }
        } else {
            Intent(Intent.ACTION_VIEW).setDataAndType(safeUri, record.mimeType)
        }
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        intent.clipData = ClipData.newRawUri(record.name, safeUri)
        activity.startActivity(if (share) Intent.createChooser(intent, "Chia sẻ tệp") else intent)
    }
}
