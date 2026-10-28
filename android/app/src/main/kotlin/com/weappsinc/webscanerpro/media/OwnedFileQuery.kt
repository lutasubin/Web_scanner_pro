package com.weappsinc.webscanerpro.media

import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File

internal class OwnedFileQuery(private val context: Context) {
    val collection: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
    } else {
        null
    }
    val directory = "${Environment.DIRECTORY_DOWNLOADS}/WebScannerPro/"
    val legacyDir: File by lazy {
        val base = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: File(context.filesDir, "downloads")
        File(base, "WebScannerPro").apply { mkdirs() }
    }

    fun read(uri: Uri): Pair<MediaRecord, Boolean>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            if (uri.scheme != "file") return null
            val path = uri.path ?: return null
            val file = File(path)
            if (!file.exists() || !file.isFile) return null
            if (!file.canonicalPath.startsWith(legacyDir.canonicalPath)) {
                throw MediaFailure("file_not_owned", "Chỉ thao tác với bản tải do ứng dụng quản lý.")
            }
            val record = MediaRecord.fromAnyFile(file) ?: MediaRecord(
                uri = Uri.fromFile(file),
                name = file.name,
                mimeType = "application/octet-stream",
                size = file.length(),
                modifiedAt = file.lastModified(),
            )
            return record to false
        }

        val col = collection ?: return null
        if (uri.scheme != "content" || uri.authority != "media" ||
            uri.query != null || uri.fragment != null ||
            !uri.toString().startsWith("$col/") || uri.lastPathSegment?.toLongOrNull() == null) {
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
