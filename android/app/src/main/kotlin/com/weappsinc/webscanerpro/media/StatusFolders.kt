package com.weappsinc.webscanerpro.media

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.DocumentsContract
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
                val fastRecords = queryStatusesFast(uri, business)
                if (fastRecords != null) {
                    fastRecords.forEach { record ->
                        combined[record.uri.toString()] = record
                    }
                } else {
                    runCatching {
                        statusDirectory(uri).listFiles().mapNotNull(MediaRecord::fromDocument)
                    }.getOrDefault(emptyList()).forEach { record ->
                        combined[record.uri.toString()] = record
                    }
                }
            } else if (combined.isEmpty()) {
                throw MediaFailure("folder_access_lost", "Quyền đọc thư mục đã bị thu hồi. Hãy chọn lại thư mục status.")
            }
        }
        return combined.values.sortedByDescending { it.modifiedAt }
    }

    private fun queryStatusesFast(treeUri: Uri, business: Boolean): List<MediaRecord>? {
        val treeDocId = runCatching { DocumentsContract.getTreeDocumentId(treeUri) }.getOrNull() ?: return null
        val targetDocId = when {
            treeDocId.endsWith(".Statuses") -> treeDocId
            treeDocId == "primary:Android/media" -> if (business) {
                "primary:Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses"
            } else {
                "primary:Android/media/com.whatsapp/WhatsApp/Media/.Statuses"
            }
            else -> return null
        }
        val childrenUri = runCatching {
            DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, targetDocId)
        }.getOrNull() ?: return null

        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        val records = ArrayList<MediaRecord>()
        return try {
            val cursor = resolver.query(childrenUri, projection, null, null, null) ?: return null
            cursor.use { c ->
                val idCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                val nameCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                val mimeCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
                val sizeCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
                val modCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
                while (c.moveToNext()) {
                    val docId = if (idCol >= 0) c.getString(idCol) else null
                    val name = if (nameCol >= 0) c.getString(nameCol) else null
                    val mime = if (mimeCol >= 0) c.getString(mimeCol) else null
                    val size = if (sizeCol >= 0) c.getLong(sizeCol) else 0L
                    val modified = if (modCol >= 0) c.getLong(modCol) else 0L
                    if (docId.isNullOrBlank() || name.isNullOrBlank() || mime.isNullOrBlank()) continue
                    if (name.startsWith(".") || name.endsWith(".was", ignoreCase = true) || size <= 0L) continue
                    if (!(mime.startsWith("image/") || mime.startsWith("video/"))) continue
                    val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                    records.add(MediaRecord(docUri, name, mime, size, modified))
                }
            }
            records
        } catch (_: Exception) {
            null
        }
    }

    fun hasFolderPermission(business: Boolean = false): Boolean {
        if (listDirectPublicWaMedia().isNotEmpty()) {
            return true
        }
        val uri = selected(business) ?: return false
        val hasPerm = resolver.persistedUriPermissions.any { it.uri == uri && it.isReadPermission }
        if (!hasPerm) return false
        val treeDocId = runCatching { DocumentsContract.getTreeDocumentId(uri) }.getOrNull().orEmpty()
        return treeDocId.isNotEmpty() && !treeDocId.endsWith("/.Statuses")
    }

    fun listWaMedia(): List<MediaRecord> {
        val combined = LinkedHashMap<String, MediaRecord>()
        val backupDir = waMediaBackupDir(context)

        // 1. Scan direct public WhatsApp Media folders if readable
        val directFiles = listDirectPublicWaMedia()
        for (record in directFiles) {
            combined[record.name] = record
        }

        // 2. Scan via persisted SAF tree URI (if granted on Android/media or WhatsApp/Media)
        for (business in listOf(false, true)) {
            val uri = selected(business) ?: continue
            val hasPerm = resolver.persistedUriPermissions.any { it.uri == uri && it.isReadPermission }
            if (hasPerm) {
                for (record in queryWaMediaFast(uri, business)) {
                    combined.putIfAbsent(record.name, record)
                }
            }
        }

        // 3. Back up recent media files (<= 15 MB, up to 40 files) into wa_media_backup
        // so that if the sender deletes the message ("Delete for everyone"), the file survives!
        val recentToBackup = combined.values
            .sortedByDescending { it.modifiedAt }
            .take(40)
        for (record in recentToBackup) {
            if (record.size in 1L..(15L * 1024L * 1024L)) {
                val safeName = record.name.replace(Regex("[^a-zA-Z0-9._-]"), "_")
                val target = File(backupDir, safeName)
                if (!target.exists() || target.length() == 0L) {
                    runCatching {
                        resolver.openInputStream(record.uri)?.use { input ->
                            target.outputStream().use { output ->
                                input.copyTo(output)
                            }
                        }
                        if (record.modifiedAt > 0L) {
                            target.setLastModified(record.modifiedAt)
                        }
                    }
                }
            }
        }

        // 4. Include all backed-up files (including ones already deleted from WhatsApp!)
        backupDir.listFiles()?.mapNotNull(MediaRecord::fromAnyFile)?.forEach { backupRecord ->
            combined.putIfAbsent(backupRecord.name, backupRecord)
        }

        // 5. Also include web_statuses / web downloads so media captured from Dual App WebView appears too
        for (record in listWebStatuses()) {
            combined.putIfAbsent(record.name, record)
        }

        return combined.values.sortedByDescending { it.modifiedAt }
    }

    private fun queryWaMediaFast(treeUri: Uri, business: Boolean): List<MediaRecord> {
        val treeDocId = runCatching { DocumentsContract.getTreeDocumentId(treeUri) }.getOrNull()
            ?: return emptyList()
        val baseMediaDocId = when {
            treeDocId == "primary:Android/media" -> if (business) {
                "primary:Android/media/com.whatsapp.w4b/WhatsApp Business/Media"
            } else {
                "primary:Android/media/com.whatsapp/WhatsApp/Media"
            }
            treeDocId.endsWith("/Media") -> treeDocId
            treeDocId.endsWith("/.Statuses") -> treeDocId.removeSuffix("/.Statuses")
            else -> return emptyList()
        }
        val prefix = if (business) "WhatsApp Business" else "WhatsApp"
        val subfolders = listOf(
            "$prefix Images",
            "$prefix Video",
            "$prefix Audio",
            "$prefix Documents",
            "$prefix Voice Notes",
        )
        val results = ArrayList<MediaRecord>()
        for (sub in subfolders) {
            val subDocId = "$baseMediaDocId/$sub"
            val isVoiceNotes = sub.endsWith("Voice Notes")
            queryFolderDocuments(treeUri, subDocId, recurseOneLevel = isVoiceNotes, out = results)
        }
        return results
    }

    private fun queryFolderDocuments(
        treeUri: Uri,
        folderDocId: String,
        recurseOneLevel: Boolean,
        out: MutableList<MediaRecord>,
    ) {
        val childrenUri = runCatching {
            DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, folderDocId)
        }.getOrNull() ?: return

        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        val subDirs = ArrayList<String>()
        try {
            val cursor = resolver.query(childrenUri, projection, null, null, null) ?: return
            cursor.use { c ->
                val idCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                val nameCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                val mimeCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
                val sizeCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
                val modCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
                while (c.moveToNext()) {
                    val docId = if (idCol >= 0) c.getString(idCol) else null
                    val name = if (nameCol >= 0) c.getString(nameCol) else null
                    val mime = if (mimeCol >= 0) c.getString(mimeCol) else null
                    val size = if (sizeCol >= 0) c.getLong(sizeCol) else 0L
                    val modified = if (modCol >= 0) c.getLong(modCol) else 0L
                    if (docId.isNullOrBlank() || name.isNullOrBlank() || mime.isNullOrBlank()) continue
                    if (name.startsWith(".") || name.equals("Sent", ignoreCase = true) || name.equals("Private", ignoreCase = true)) {
                        continue
                    }
                    if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                        if (recurseOneLevel) subDirs.add(docId)
                        continue
                    }
                    if (size <= 0L) continue
                    val normalizedMime = if (name.endsWith(".opus", ignoreCase = true)) "audio/ogg" else mime
                    val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                    out.add(MediaRecord(docUri, name, normalizedMime, size, modified))
                }
            }
        } catch (_: Exception) {
            return
        }
        if (recurseOneLevel) {
            for (subDir in subDirs) {
                queryFolderDocuments(treeUri, subDir, recurseOneLevel = false, out = out)
            }
        }
    }

    private fun listDirectPublicWaMedia(): List<MediaRecord> {
        val ext = runCatching { Environment.getExternalStorageDirectory() }.getOrNull() ?: return emptyList()
        val roots = listOf(
            File(ext, "Android/media/com.whatsapp/WhatsApp/Media") to "WhatsApp",
            File(ext, "WhatsApp/Media") to "WhatsApp",
            File(ext, "Android/media/com.whatsapp.w4b/WhatsApp Business/Media") to "WhatsApp Business",
            File(ext, "WhatsApp Business/Media") to "WhatsApp Business",
        )
        val out = ArrayList<MediaRecord>()
        for ((mediaRoot, prefix) in roots) {
            if (!mediaRoot.isDirectory || !mediaRoot.canRead()) continue
            val subfolders = listOf(
                "$prefix Images",
                "$prefix Video",
                "$prefix Audio",
                "$prefix Documents",
                "$prefix Voice Notes",
            )
            for (sub in subfolders) {
                val dir = File(mediaRoot, sub)
                if (!dir.isDirectory || !dir.canRead()) continue
                val children = dir.listFiles().orEmpty()
                for (child in children) {
                    if (child.name.startsWith(".") ||
                        child.name.equals("Sent", ignoreCase = true) ||
                        child.name.equals("Private", ignoreCase = true)
                    ) continue
                    if (child.isDirectory && sub.endsWith("Voice Notes")) {
                        child.listFiles()?.mapNotNull(MediaRecord::fromAnyFile)?.let(out::addAll)
                    } else if (child.isFile) {
                        MediaRecord.fromAnyFile(child)?.let(out::add)
                    }
                }
            }
        }
        return out
    }

    fun find(id: String, business: Boolean): MediaRecord = list(business).firstOrNull {
        it.uri.toString() == id
    } ?: findInSelected(id)
        ?: throw MediaFailure("status_missing", "Status không còn trong thư mục đã chọn. Hãy tải lại danh sách.")

    fun findInSelected(id: String): MediaRecord? {
        listWebStatuses().firstOrNull { it.uri.toString() == id }?.let { return it }
        waMediaBackupDir(context).listFiles()?.mapNotNull(MediaRecord::fromAnyFile)
            ?.firstOrNull { it.uri.toString() == id }?.let { return it }
        listDirectPublicWaMedia().firstOrNull { it.uri.toString() == id }?.let { return it }
        for (business in listOf(false, true)) {
            listDirectPublicStatuses(business).firstOrNull { it.uri.toString() == id }?.let { return it }
            val selected = selected(business) ?: continue
            val parsed = Uri.parse(id)
            if (parsed.authority != selected.authority) continue
            val match = runCatching { list(business) }.getOrDefault(emptyList())
                .firstOrNull { it.uri.toString() == id }
                ?: runCatching { queryWaMediaFast(selected, business) }.getOrDefault(emptyList())
                    .firstOrNull { it.uri.toString() == id }
            if (match != null) return match
        }
        return null
    }

    private fun listWebStatuses(): List<MediaRecord> =
        webStatusDir(context).listFiles()?.mapNotNull { file ->
            if (file.isFile && !file.name.endsWith(".mp4", ignoreCase = true) && file.length() in 1L..10_239L) {
                runCatching { file.delete() }
                null
            } else {
                MediaRecord.fromFile(file)
            }
        }.orEmpty()

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

        fun waMediaBackupDir(context: Context): File =
            File(context.filesDir, "wa_media_backup").apply { mkdirs() }
    }
}
