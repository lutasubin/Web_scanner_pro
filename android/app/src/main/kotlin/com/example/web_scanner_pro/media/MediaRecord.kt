package com.example.web_scanner_pro.media

import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import java.io.File

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

        fun fromFile(file: File): MediaRecord? {
            if (!file.isFile || file.length() <= 0L) return null
            val lower = file.name.lowercase()
            val type = when {
                lower.endsWith(".mp4") || lower.endsWith(".3gp") || lower.endsWith(".mkv") || lower.endsWith(".webm") -> "video/mp4"
                lower.endsWith(".png") -> "image/png"
                lower.endsWith(".webp") -> "image/webp"
                lower.endsWith(".gif") -> "image/gif"
                lower.endsWith(".jpg") || lower.endsWith(".jpeg") -> "image/jpeg"
                else -> return null
            }
            return MediaRecord(Uri.fromFile(file), file.name, type, file.length(), file.lastModified())
        }
    }
}
