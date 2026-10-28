package com.weappsinc.webscanerpro.media

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

        fun fromAnyFile(file: File): MediaRecord? {
            if (!file.isFile || file.length() <= 0L) return null
            val lower = file.name.lowercase()
            if (lower.startsWith(".") || lower.endsWith(".nomedia") || lower.endsWith(".was")) return null
            val type = when {
                lower.endsWith(".mp4") || lower.endsWith(".3gp") || lower.endsWith(".mkv") || lower.endsWith(".webm") || lower.endsWith(".mov") -> "video/mp4"
                lower.endsWith(".png") -> "image/png"
                lower.endsWith(".webp") -> "image/webp"
                lower.endsWith(".gif") -> "image/gif"
                lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".heic") -> "image/jpeg"
                lower.endsWith(".opus") -> "audio/ogg"
                lower.endsWith(".ogg") -> "audio/ogg"
                lower.endsWith(".mp3") -> "audio/mpeg"
                lower.endsWith(".m4a") || lower.endsWith(".aac") -> "audio/mp4"
                lower.endsWith(".wav") -> "audio/wav"
                lower.endsWith(".amr") -> "audio/amr"
                lower.endsWith(".flac") -> "audio/flac"
                lower.endsWith(".pdf") -> "application/pdf"
                lower.endsWith(".txt") -> "text/plain"
                lower.endsWith(".csv") -> "text/csv"
                lower.endsWith(".zip") -> "application/zip"
                lower.endsWith(".doc") || lower.endsWith(".docx") -> "application/msword"
                lower.endsWith(".xls") || lower.endsWith(".xlsx") -> "application/vnd.ms-excel"
                lower.endsWith(".ppt") || lower.endsWith(".pptx") -> "application/vnd.ms-powerpoint"
                else -> "application/octet-stream"
            }
            return MediaRecord(Uri.fromFile(file), file.name, type, file.length(), file.lastModified())
        }
    }
}
