package com.weappsinc.webscanerpro.media

import android.content.ActivityNotFoundException
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.concurrent.Executors

internal object MediaTasks {
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun <T> run(result: MethodChannel.Result, work: () -> T, finish: (T) -> Any? = { it }) {
        executor.execute {
            try {
                val value = work()
                main.post {
                    try { result.success(finish(value)) }
                    catch (error: Exception) { fail(result, error) }
                }
            } catch (error: Exception) {
                main.post { fail(result, error) }
            }
        }
    }

    fun fail(result: MethodChannel.Result, error: Exception) {
        val failure = when (error) {
            is MediaFailure -> error
            is SecurityException -> MediaFailure("permission_denied", "Quyền đọc đã hết hạn. Hãy chọn lại thư mục.")
            is ActivityNotFoundException -> MediaFailure("no_viewer", "Chưa có ứng dụng mở loại tệp này.")
            is IOException -> MediaFailure("media_io", "Không đọc hoặc lưu được tệp. Kiểm tra bộ nhớ và thử lại.")
            is IllegalArgumentException -> MediaFailure("invalid_argument", "Thông tin tệp hoặc thư mục không hợp lệ.")
            else -> MediaFailure("media_error", "Không thể hoàn thành thao tác với tệp. Hãy thử lại.")
        }
        result.error(failure.code, failure.message, null)
    }
}
