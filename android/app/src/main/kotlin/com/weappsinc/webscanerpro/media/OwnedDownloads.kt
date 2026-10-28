package com.weappsinc.webscanerpro.media

import android.content.Context
import android.net.Uri
import java.io.IOException

internal class OwnedDownloads(context: Context) {
    private val registry = OwnedFileRegistry(context)
    private val query = OwnedFileQuery(context)
    private val resolver = context.contentResolver
    private val writer = DownloadWriter(context, registry, query)

    fun contains(id: String): Boolean = registry.contains(Uri.parse(id))

    fun save(source: MediaRecord) = writer.save(source)

    internal fun open(name: String, mimeType: String): PendingDownload =
        writer.open(name, mimeType)

    fun list(): List<MediaRecord> {
        val files = mutableListOf<MediaRecord>()
        for (id in registry.all()) {
            val uri = Uri.parse(id)
            val value = query.read(uri)
            when {
                value == null -> registry.remove(uri)
                value.second -> {
                    // Bản sao bị ngắt chưa công bố; chỉ xóa bản ghi có trong registry.
                    resolver.delete(uri, null, null)
                    registry.remove(uri)
                }
                else -> files.add(value.first)
            }
        }
        return files.sortedByDescending { it.modifiedAt }
    }

    fun requireOwned(id: String): MediaRecord {
        val uri = Uri.parse(id)
        if (!registry.contains(uri)) throw MediaFailure("file_not_owned", "Tệp không thuộc danh sách bản tải của ứng dụng.")
        val value = query.read(uri)
            ?: throw MediaFailure("file_missing", "Tệp đã được chuyển hoặc xóa khỏi bộ nhớ.")
        if (value.second) throw MediaFailure("file_pending", "Tệp chưa lưu xong. Hãy thử lại sau.")
        return value.first
    }

    fun delete(id: String) {
        val record = requireOwned(id)
        if (record.uri.scheme == "file") {
            val file = record.uri.path?.let { java.io.File(it) }
            if (file == null || !file.delete()) throw IOException("Cannot delete download")
        } else {
            if (resolver.delete(record.uri, null, null) < 1) throw IOException("Cannot delete download")
        }
        registry.remove(record.uri)
    }
}
