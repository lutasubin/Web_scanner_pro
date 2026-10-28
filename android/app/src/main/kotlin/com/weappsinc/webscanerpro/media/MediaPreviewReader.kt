package com.weappsinc.webscanerpro.media

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.util.Size
import java.io.ByteArrayOutputStream
import kotlin.math.max

internal class MediaPreviewReader(private val context: Context) {
    private val resolver = context.contentResolver

    fun readThumbnail(record: MediaRecord, maxEdge: Int = 360): ByteArray? {
        if (!record.mimeType.startsWith("image/") && !record.mimeType.startsWith("video/")) {
            return null
        }
        val bitmap = loadBitmap(record.uri, record.mimeType, maxEdge) ?: return null
        return try {
            val out = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 82, out)
            out.toByteArray()
        } finally {
            bitmap.recycle()
        }
    }

    fun readImagePreview(record: MediaRecord, maxEdge: Int = 1440): ByteArray? {
        if (!record.mimeType.startsWith("image/")) {
            return readThumbnail(record, maxEdge)
        }
        // If small enough (< 2.5 MB), return raw bytes directly for crisp display
        if (record.size in 1..(2_500_000)) {
            runCatching {
                resolver.openInputStream(record.uri)?.use { it.readBytes() }
            }.getOrNull()?.let { return it }
        }
        val bitmap = decodeSampledImage(record.uri, maxEdge) ?: return null
        return try {
            val out = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 88, out)
            out.toByteArray()
        } finally {
            bitmap.recycle()
        }
    }

    private fun loadBitmap(uri: Uri, mimeType: String, maxEdge: Int): Bitmap? {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            runCatching {
                resolver.loadThumbnail(uri, Size(maxEdge, maxEdge), null)
            }.getOrNull()?.let { return it }
        }

        return if (mimeType.startsWith("video/")) {
            decodeVideoFrame(uri, maxEdge)
        } else {
            decodeSampledImage(uri, maxEdge)
        }
    }

    private fun decodeVideoFrame(uri: Uri, maxEdge: Int): Bitmap? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            val frame = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                ?: retriever.frameAtTime
                ?: return null
            scaleDown(frame, maxEdge)
        } catch (_: Exception) {
            null
        } finally {
            runCatching { retriever.release() }
        }
    }

    private fun decodeSampledImage(uri: Uri, maxEdge: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var sample = 1
        var longest = max(bounds.outWidth, bounds.outHeight)
        while (longest / 2 >= maxEdge) {
            longest /= 2
            sample *= 2
        }

        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        val decoded = resolver.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, opts)
        } ?: return null
        return scaleDown(decoded, maxEdge)
    }

    private fun scaleDown(bitmap: Bitmap, maxEdge: Int): Bitmap {
        val w = bitmap.width
        val h = bitmap.height
        val longest = max(w, h)
        if (longest <= maxEdge || longest <= 0) return bitmap
        val ratio = maxEdge.toFloat() / longest.toFloat()
        val nw = (w * ratio).toInt().coerceAtLeast(1)
        val nh = (h * ratio).toInt().coerceAtLeast(1)
        val scaled = Bitmap.createScaledBitmap(bitmap, nw, nh, true)
        if (scaled !== bitmap) bitmap.recycle()
        return scaled
    }
}
