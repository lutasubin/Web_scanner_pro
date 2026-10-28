package com.weappsinc.webscanerpro.media

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodChannel

internal class StatusFolderPicker(private val activity: Activity, private val folders: StatusFolders) {
    private var pending: MethodChannel.Result? = null
    private var pendingBusiness = false
    private val requestCode = 7419

    fun select(business: Boolean, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("picker_busy", "Trình chọn thư mục đang mở.", null)
            return
        }
        pending = result
        pendingBusiness = business
        val defaultTreeUri = Uri.parse(
            "content://com.android.externalstorage.documents/document/primary%3AAndroid%2Fmedia",
        )
        val existing = folders.selected(business)
        val initialUri = if (existing != null && !existing.toString().endsWith("%2F.Statuses")) {
            existing
        } else {
            defaultTreeUri
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            putExtra(Intent.EXTRA_LOCAL_ONLY, true)
            putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri)
        }
        try {
            activity.startActivityForResult(intent, requestCode)
        } catch (error: Exception) {
            pending = null
            MediaTasks.fail(result, error)
        }
    }

    fun onActivityResult(request: Int, code: Int, data: Intent?): Boolean {
        if (request != requestCode) return false
        val result = pending ?: return true
        val business = pendingBusiness
        pending = null
        val uri = data?.data
        if (code != Activity.RESULT_OK || uri == null) {
            result.success(false)
            return true
        }
        MediaTasks.run(result, {
            folders.persist(uri, business, data.flags)
            StatusMonitorService.ensureRunning(activity, refreshWatchers = true)
            true
        })
        return true
    }

    fun dispose() {
        pending?.error("picker_interrupted", "Trình chọn thư mục đã đóng. Hãy thử lại.", null)
        pending = null
    }
}
