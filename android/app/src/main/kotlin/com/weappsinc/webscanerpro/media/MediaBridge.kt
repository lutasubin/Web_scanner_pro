package com.weappsinc.webscanerpro.media

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MediaBridge(activity: Activity) {
    private val folders = StatusFolders(activity.applicationContext)
    private val downloads = OwnedDownloads(activity.applicationContext)
    private val picker = StatusFolderPicker(activity, folders)
    private val actions = MediaActions(activity)
    private val previews = MediaPreviewReader(activity.applicationContext)

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            "selectStatusFolder", "selectStatusTree" -> picker.select(call.argument<Boolean>("business") ?: false, result)
            "hasFolderPermission" -> result.success(folders.hasFolderPermission(call.argument<Boolean>("business") ?: false))
            "listStatuses" -> MediaTasks.run(result, {
                folders.list(call.argument<Boolean>("business") ?: false).map(MediaRecord::toMap)
            })
            "listWaMedia" -> MediaTasks.run(result, {
                folders.listWaMedia().map(MediaRecord::toMap)
            })
            "saveStatus" -> MediaTasks.run(result, {
                downloads.save(folders.find(id(call), call.argument<Boolean>("business") ?: false))
                null
            })
            "saveStatuses" -> MediaTasks.run(result, {
                val ids = call.argument<List<String>>("ids").orEmpty()
                val business = call.argument<Boolean>("business") ?: false
                var count = 0
                for (itemId in ids) {
                    if (itemId.isNotBlank()) {
                        runCatching {
                            downloads.save(folders.find(itemId, business))
                            count++
                        }
                    }
                }
                count
            })
            "listFiles" -> MediaTasks.run(result, { downloads.list().map(MediaRecord::toMap) })
            "deleteFile" -> MediaTasks.run(result, { downloads.delete(id(call)); null })
            "deleteFiles" -> MediaTasks.run(result, {
                val ids = call.argument<List<String>>("ids").orEmpty()
                var count = 0
                for (itemId in ids) {
                    if (itemId.isNotBlank()) {
                        runCatching {
                            downloads.delete(itemId)
                            count++
                        }
                    }
                }
                count
            })
            "readThumbnail" -> MediaTasks.run(result, {
                val record = resolveRecord(id(call))
                previews.readThumbnail(record, call.argument<Int>("maxEdge") ?: 360)
            })
            "readImagePreview" -> MediaTasks.run(result, {
                val record = resolveRecord(id(call))
                previews.readImagePreview(record, call.argument<Int>("maxEdge") ?: 1440)
            })
            "openFile", "shareFile" -> MediaTasks.run(result, {
                resolveRecord(id(call))
            }, { record -> actions.open(record, call.method == "shareFile"); null })
            else -> return false
        }
        return true
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean =
        picker.onActivityResult(requestCode, resultCode, data)

    fun dispose() = picker.dispose()

    private fun resolveRecord(id: String): MediaRecord =
        if (downloads.contains(id)) downloads.requireOwned(id)
        else folders.findInSelected(id)
            ?: throw MediaFailure("file_not_allowed", "Tệp không thuộc thư mục status hoặc bản tải đã cấp quyền.")

    private fun id(call: MethodCall): String = call.argument<String>("id")?.takeIf { it.isNotBlank() }
        ?: throw MediaFailure("invalid_argument", "Thiếu địa chỉ tệp.")
}
