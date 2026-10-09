package com.example.web_scanner_pro.media

import android.net.Uri
import androidx.documentfile.provider.DocumentFile

internal data class MediaRecord(
    val uri: Uri,
    val name: String,
    val mimeType: String,
    val size: Long,
    val modifiedAt: Long,
) {
    fun toMap(): Map<String, Any> = mapOf(
        "id" to uri.toString(), "name" to name, "mimeType" to mimeType,
        "size" to size, "modifiedAt" to modifiedAt,
    )

    companion object {
        fun fromDocument(file: DocumentFile): MediaRecord? {
            val type = file.type ?: return null
            if (!file.isFile || !(type.startsWith("image/") || type.startsWith("video/"))) return null
            return MediaRecord(file.uri, file.name ?: "Status", type, file.length(), file.lastModified())
        }
    }
}
