package com.example.web_scanner_pro.media

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MediaBridge(activity: Activity) {
    private val folders = StatusFolders(activity.applicationContext)
    private val downloads = OwnedDownloads(activity.applicationContext)
    private val picker = StatusFolderPicker(activity, folders)
    private val actions = MediaActions(activity)

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            "selectStatusFolder" -> picker.select(call.argument<Boolean>("business") ?: false, result)
            "listStatuses" -> MediaTasks.run(result, {
                folders.list(call.argument<Boolean>("business") ?: false).map(MediaRecord::toMap)
            })
            "saveStatus" -> MediaTasks.run(result, {
                downloads.save(folders.find(id(call), call.argument<Boolean>("business") ?: false))
                null
            })
            "listFiles" -> MediaTasks.run(result, { downloads.list().map(MediaRecord::toMap) })
            "deleteFile" -> MediaTasks.run(result, { downloads.delete(id(call)); null })
            "openFile", "shareFile" -> MediaTasks.run(result, {
                val id = id(call)
                if (downloads.contains(id)) downloads.requireOwned(id) else folders.findInSelected(id)
                    ?: throw MediaFailure("file_not_allowed", "Tệp không thuộc thư mục status hoặc bản tải đã cấp quyền.")
            }, { record -> actions.open(record, call.method == "shareFile"); null })
            else -> return false
        }
        return true
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean =
        picker.onActivityResult(requestCode, resultCode, data)

    fun dispose() = picker.dispose()

    private fun id(call: MethodCall): String = call.argument<String>("id")?.takeIf { it.isNotBlank() }
        ?: throw MediaFailure("invalid_argument", "Thiếu địa chỉ tệp.")
}
