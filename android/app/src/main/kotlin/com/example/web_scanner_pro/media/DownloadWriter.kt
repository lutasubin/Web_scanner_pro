package com.example.web_scanner_pro.media

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.provider.MediaStore
import java.io.IOException
import java.io.OutputStream

internal class DownloadWriter(
    context: Context,
    private val registry: OwnedFileRegistry,
    private val query: OwnedFileQuery,
) {
    private val resolver = context.contentResolver

    fun save(source: MediaRecord) {
        val target = open(source.name, source.mimeType)
        try {
            resolver.openInputStream(source.uri)?.use { input -> input.copyTo(target.output) }
                ?: throw IOException("Cannot read status")
            target.publish()
        } catch (error: Exception) {
            target.abort()
            throw error
        }
    }

    fun open(name: String, mimeType: String): PendingDownload {
        val safeName = safeName(name)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, safeName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType.ifBlank { "application/octet-stream" })
            put(MediaStore.MediaColumns.RELATIVE_PATH, query.directory)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val destination = resolver.insert(query.collection, values) ?: throw IOException("Cannot create download")
        try {
            // Lưu URI trước khi copy để dọn bản ghi pending nếu tiến trình bị dừng.
            registry.add(destination)
            val output = resolver.openOutputStream(destination, "w")
                ?: throw IOException("Cannot write download")
            return PendingDownload(destination, output, resolver, registry)
        } catch (error: Exception) {
            runCatching { resolver.delete(destination, null, null) }
            runCatching { registry.remove(destination) }
            throw error
        }
    }

    private fun safeName(value: String): String {
        val cleaned = value.trim()
            .replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_")
            .trim('.', ' ')
            .takeLast(160)
        return cleaned.ifBlank { "whatsapp_download" }
    }
}

internal class PendingDownload(
    val uri: Uri,
    val output: OutputStream,
    private val resolver: android.content.ContentResolver,
    private val registry: OwnedFileRegistry,
) {
    private var closed = false

    @Synchronized
    fun write(bytes: ByteArray) {
        if (closed) throw IOException("Download is closed")
        output.write(bytes)
    }

    @Synchronized
    fun publish() {
        if (closed) return
        try {
            output.flush()
            output.close()
            val ready = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
            if (resolver.update(uri, ready, null, null) != 1) {
                throw IOException("Cannot publish download")
            }
            closed = true
        } catch (error: Exception) {
            abortInternal()
            throw error
        }
    }

    @Synchronized
    fun abort() {
        if (!closed) abortInternal()
    }

    private fun abortInternal() {
        closed = true
        runCatching { output.close() }
        runCatching { resolver.delete(uri, null, null) }
        runCatching { registry.remove(uri) }
    }
}
