package com.example.web_scanner_pro.media

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import java.io.IOException

internal class StatusFolders(private val context: Context) {
    private val preferences = context.getSharedPreferences("web_scanner_media", Context.MODE_PRIVATE)
    private val resolver = context.contentResolver

    private fun key(business: Boolean) = if (business) "business_status_tree" else "personal_status_tree"

    fun selected(business: Boolean): Uri? = preferences.getString(key(business), null)?.let(Uri::parse)

    fun persist(uri: Uri, business: Boolean, flags: Int) {
        if (uri.scheme != "content" || flags and Intent.FLAG_GRANT_READ_URI_PERMISSION == 0) {
            throw MediaFailure("invalid_folder", "Thư mục phải cho phép đọc qua trình chọn tệp Android.")
        }
        statusDirectory(uri)
        val previous = selected(business)
        resolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        if (!preferences.edit().putString(key(business), uri.toString()).commit()) {
            throw IOException("Cannot save selected folder")
        }
        if (previous != null && previous != uri && previous != selected(!business)) {
            runCatching { resolver.releasePersistableUriPermission(previous, Intent.FLAG_GRANT_READ_URI_PERMISSION) }
        }
    }

    fun list(business: Boolean): List<MediaRecord> {
        val uri = selected(business) ?: return emptyList()
        if (resolver.persistedUriPermissions.none { it.uri == uri && it.isReadPermission }) {
            throw MediaFailure("folder_access_lost", "Quyền đọc thư mục đã bị thu hồi. Hãy chọn lại thư mục status.")
        }
        return statusDirectory(uri).listFiles().mapNotNull(MediaRecord::fromDocument)
            .sortedByDescending { it.modifiedAt }
    }

    fun find(id: String, business: Boolean): MediaRecord = list(business).firstOrNull {
        it.uri.toString() == id
    } ?: throw MediaFailure("status_missing", "Status không còn trong thư mục đã chọn. Hãy tải lại danh sách.")

    fun findInSelected(id: String): MediaRecord? {
        for (business in listOf(false, true)) {
            val selected = selected(business) ?: continue
            if (Uri.parse(id).authority != selected.authority) continue
            val match = list(business).firstOrNull { it.uri.toString() == id }
            if (match != null) return match
        }
        return null
    }

    private fun statusDirectory(uri: Uri): DocumentFile {
        val root = DocumentFile.fromTreeUri(context, uri)
            ?: throw MediaFailure("invalid_folder", "Không mở được thư mục đã chọn.")
        // Chỉ tìm một cấp .Statuses; không quét toàn bộ bộ nhớ người dùng.
        val directory = if (root.name == ".Statuses") root else root.findFile(".Statuses")
        if (directory == null || !directory.isDirectory || !directory.canRead()) {
            throw MediaFailure("invalid_folder", "Hãy chọn thư mục .Statuses hoặc thư mục Media chứa .Statuses.")
        }
        return directory
    }
}
