package com.example.web_scanner_pro.media

import android.content.ContentValues
import android.content.Context
import android.provider.MediaStore
import java.io.IOException
import java.util.UUID

internal class DownloadWriter(
    context: Context,
    private val registry: OwnedFileRegistry,
    private val query: OwnedFileQuery,
) {
    private val resolver = context.contentResolver

    fun save(source: MediaRecord) {
        val safeName = source.name.replace(Regex("[^a-zA-Z0-9._-]"), "_").takeLast(100)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "${UUID.randomUUID()}_$safeName")
            put(MediaStore.MediaColumns.MIME_TYPE, source.mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, query.directory)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val destination = resolver.insert(query.collection, values) ?: throw IOException("Cannot create download")
        try {
            // Lưu URI trước khi copy để dọn bản ghi pending nếu tiến trình bị dừng.
            registry.add(destination)
            resolver.openInputStream(source.uri)?.use { input ->
                val output = resolver.openOutputStream(destination, "w") ?: throw IOException("Cannot write download")
                output.use { input.copyTo(it) }
            } ?: throw IOException("Cannot read status")
            val ready = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
            if (resolver.update(destination, ready, null, null) != 1) throw IOException("Cannot publish download")
        } catch (error: Exception) {
            runCatching { resolver.delete(destination, null, null) }
            runCatching { registry.remove(destination) }
            throw error
        }
    }
}
