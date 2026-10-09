package com.example.web_scanner_pro.media

import android.content.Context
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore

internal class OwnedFileQuery(private val context: Context) {
    val collection: Uri = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
    val directory = "${Environment.DIRECTORY_DOWNLOADS}/WebScannerPro/"

    fun read(uri: Uri): Pair<MediaRecord, Boolean>? {
        if (uri.scheme != "content" || uri.authority != "media" ||
            uri.query != null || uri.fragment != null ||
            !uri.toString().startsWith("$collection/") || uri.lastPathSegment?.toLongOrNull() == null) {
            throw MediaFailure("file_not_owned", "Chỉ thao tác với bản tải do ứng dụng quản lý.")
        }
        val columns = arrayOf(
            MediaStore.MediaColumns.DISPLAY_NAME, MediaStore.MediaColumns.MIME_TYPE,
            MediaStore.MediaColumns.SIZE, MediaStore.MediaColumns.DATE_MODIFIED,
            MediaStore.MediaColumns.OWNER_PACKAGE_NAME, MediaStore.MediaColumns.RELATIVE_PATH,
            MediaStore.MediaColumns.IS_PENDING,
        )
        context.contentResolver.query(uri, columns, null, null, null)?.use { cursor ->
            if (!cursor.moveToFirst()) return null
            if (cursor.getString(4) != context.packageName || cursor.getString(5) != directory) {
                throw MediaFailure("file_not_owned", "Tệp này không còn thuộc thư mục do ứng dụng quản lý.")
            }
            val record = MediaRecord(uri, cursor.getString(0) ?: "Tệp đã lưu",
                cursor.getString(1) ?: "application/octet-stream", cursor.getLong(2), cursor.getLong(3) * 1000)
            return record to (cursor.getInt(6) != 0)
        }
        return null
    }
}
