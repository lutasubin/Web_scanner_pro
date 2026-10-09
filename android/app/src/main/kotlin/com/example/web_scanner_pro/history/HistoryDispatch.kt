package com.example.web_scanner_pro.history

import android.os.Handler
import android.os.Looper
import java.util.concurrent.Executors

object HistoryDispatch {
    val worker = Executors.newSingleThreadExecutor()
    val main = Handler(Looper.getMainLooper())
}
