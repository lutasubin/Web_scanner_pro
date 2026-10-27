package com.example.web_scanner_pro.media

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import androidx.documentfile.provider.DocumentFile
import java.io.File
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
        val combined = LinkedHashMap<String, MediaRecord>()
        for (record in listWebStatuses()) {
            combined[record.uri.toString()] = record
        }
        for (record in listDirectPublicStatuses(business)) {
            combined[record.uri.toString()] = record
        }
        val uri = selected(business)
        if (uri != null) {
            val hasPerm = resolver.persistedUriPermissions.any { it.uri == uri && it.isReadPermission }
            if (hasPerm) {
                runCatching {
                    statusDirectory(uri).listFiles().mapNotNull(MediaRecord::fromDocument)
                }.getOrDefault(emptyList()).forEach { record ->
                    combined[record.uri.toString()] = record
                }
            } else if (combined.isEmpty()) {
                throw MediaFailure("folder_access_lost", "Quyền đọc thư mục đã bị thu hồi. Hãy chọn lại thư mục status.")
            }
        }
        return combined.values.sortedByDescending { it.modifiedAt }
    }

    fun find(id: String, business: Boolean): MediaRecord = list(business).firstOrNull {
        it.uri.toString() == id
    } ?: findInSelected(id)
        ?: throw MediaFailure("status_missing", "Status không còn trong thư mục đã chọn. Hãy tải lại danh sách.")

    fun findInSelected(id: String): MediaRecord? {
        listWebStatuses().firstOrNull { it.uri.toString() == id }?.let { return it }
        for (business in listOf(false, true)) {
            listDirectPublicStatuses(business).firstOrNull { it.uri.toString() == id }?.let { return it }
            val selected = selected(business) ?: continue
            if (Uri.parse(id).authority != selected.authority) continue
            val match = runCatching { list(business) }.getOrDefault(emptyList())
                .firstOrNull { it.uri.toString() == id }
            if (match != null) return match
        }
        return null
    }

    private fun listWebStatuses(): List<MediaRecord> =
        webStatusDir(context).listFiles()?.mapNotNull(MediaRecord::fromFile).orEmpty()

    private fun listDirectPublicStatuses(business: Boolean): List<MediaRecord> {
        val ext = runCatching { Environment.getExternalStorageDirectory() }.getOrNull() ?: return emptyList()
        val candidates = if (business) {
            listOf(
                File(ext, "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses"),
                File(ext, "WhatsApp Business/Media/.Statuses"),
            )
        } else {
            listOf(
                File(ext, "Android/media/com.whatsapp/WhatsApp/Media/.Statuses"),
                File(ext, "WhatsApp/Media/.Statuses"),
            )
        }
        return candidates
            .filter { it.isDirectory && it.canRead() }
            .flatMap { dir -> dir.listFiles()?.mapNotNull(MediaRecord::fromFile).orEmpty() }
    }

    private fun statusDirectory(uri: Uri): DocumentFile {
        val root = DocumentFile.fromTreeUri(context, uri)
            ?: throw MediaFailure("invalid_folder", "Không mở được thư mục đã chọn.")
        val direct = findStatusesDir(root)
        if (direct != null && direct.isDirectory && direct.canRead()) {
            return direct
        }
        if (root.isDirectory && root.canRead()) {
            return root
        }
        throw MediaFailure("invalid_folder", "Hãy chọn thư mục .Statuses hoặc thư mục Media chứa .Statuses.")
    }

    private fun findStatusesDir(root: DocumentFile): DocumentFile? {
        if (root.name == ".Statuses") return root
        root.findFile(".Statuses")?.let { return it }
        root.findFile("Media")?.let { media ->
            media.findFile(".Statuses")?.let { return it }
            return media
        }
        for (waName in listOf("WhatsApp", "WhatsApp Business")) {
            root.findFile(waName)?.let { wa ->
                wa.findFile(".Statuses")?.let { return it }
                wa.findFile("Media")?.let { media ->
                    media.findFile(".Statuses")?.let { return it }
                    return media
                }
            }
        }
        for (pkgName in listOf("com.whatsapp", "com.whatsapp.w4b")) {
            root.findFile(pkgName)?.let { pkg ->
                findStatusesDir(pkg)?.let { return it }
            }
        }
        return null
    }

    companion object {
        fun webStatusDir(context: Context): File =
            File(context.filesDir, "web_statuses").apply { mkdirs() }
    }
}
