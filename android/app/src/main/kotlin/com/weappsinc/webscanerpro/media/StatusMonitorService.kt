package com.weappsinc.webscanerpro.media

import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.FileObserver
import android.os.Handler
import android.os.Looper
import java.io.File
import java.util.Collections
import java.util.concurrent.CopyOnWriteArraySet
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

object StatusMonitorService {
    private val observers = mutableListOf<FileObserver>()
    private var poller: ScheduledExecutorService? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val listeners = CopyOnWriteArraySet<() -> Unit>()
    private val seenStatusNames: MutableSet<String> =
        Collections.synchronizedSet(HashSet<String>())
    private val seenWaMediaNames: MutableSet<String> =
        Collections.synchronizedSet(HashSet<String>())
    @Volatile
    private var initialSnapshotReady = false
    @Volatile
    private var lastNotificationAtMs = 0L

    fun addListener(listener: () -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: () -> Unit) {
        listeners.remove(listener)
    }

    @Synchronized
    fun ensureRunning(context: Context, refreshWatchers: Boolean = false) {
        val appContext = context.applicationContext
        val activePoller = poller
        if (refreshWatchers || activePoller == null || activePoller.isShutdown) {
            stopWatching()
            startWatching(appContext)
        } else {
            activePoller.execute {
                runCatching { pollForChanges(appContext) }
            }
        }
    }

    private fun startWatching(appContext: Context) {
        val executor = Executors.newSingleThreadScheduledExecutor()
        poller = executor
        executor.execute {
            runCatching {
                seedExistingStatuses(appContext)
                val watchDirs = LinkedHashSet<File>()
                watchDirs.add(StatusFolders.webStatusDir(appContext))
                val ext = runCatching { Environment.getExternalStorageDirectory() }.getOrNull()
                if (ext != null) {
                    watchDirs.add(File(ext, "Android/media/com.whatsapp/WhatsApp/Media/.Statuses"))
                    watchDirs.add(File(ext, "WhatsApp/Media/.Statuses"))
                    watchDirs.add(File(ext, "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses"))
                    watchDirs.add(File(ext, "WhatsApp Business/Media/.Statuses"))
                }

                val mask = FileObserver.MOVED_TO or
                    FileObserver.CLOSE_WRITE or
                    FileObserver.DELETE or
                    FileObserver.DELETE_SELF

                for (dir in watchDirs) {
                    if (!dir.exists() && dir != StatusFolders.webStatusDir(appContext)) continue
                    runCatching {
                        val observer = createDirectoryObserver(appContext, dir, mask)
                        observer.startWatching()
                        synchronized(observers) {
                            observers.add(observer)
                        }
                    }
                }
            }
        }
        executor.scheduleWithFixedDelay(
            { runCatching { pollForChanges(appContext) } },
            1500L,
            1500L,
            TimeUnit.MILLISECONDS,
        )
    }

    @Synchronized
    private fun stopWatching() {
        synchronized(observers) {
            for (observer in observers) {
                runCatching { observer.stopWatching() }
            }
            observers.clear()
        }
        poller?.shutdownNow()
        poller = null
    }

    @Suppress("DEPRECATION")
    private fun createDirectoryObserver(
        appContext: Context,
        dir: File,
        mask: Int,
    ): FileObserver {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            object : FileObserver(dir, mask) {
                override fun onEvent(event: Int, path: String?) {
                    handleFileEvent(appContext, dir, event, path)
                }
            }
        } else {
            object : FileObserver(dir.absolutePath, mask) {
                override fun onEvent(event: Int, path: String?) {
                    handleFileEvent(appContext, dir, event, path)
                }
            }
        }
    }

    private fun handleFileEvent(appContext: Context, dir: File, event: Int, path: String?) {
        if (path.isNullOrBlank()) return
        if (path.startsWith(".") || path.endsWith(".was", ignoreCase = true)) return
        if (!isSupportedMediaName(path)) return

        val action = event and FileObserver.ALL_EVENTS
        when (action) {
            FileObserver.MOVED_TO,
            FileObserver.CLOSE_WRITE -> {
                val file = File(dir, path)
                if (file.exists() && file.length() > 0L) {
                    onStatusDetected(appContext, path, notifyUser = true)
                }
            }
            FileObserver.DELETE,
            FileObserver.DELETE_SELF -> {
                seenStatusNames.remove(path)
                dispatchStatusesUpdated()
            }
        }
    }

    private fun pollForChanges(appContext: Context) {
        val folders = StatusFolders(appContext)
        val currentNames = HashSet<String>()
        for (business in listOf(false, true)) {
            val records = runCatching { folders.list(business) }.getOrDefault(emptyList())
            for (record in records) {
                if (isSupportedMediaName(record.name) && record.size > 0L) {
                    currentNames.add(record.name)
                }
            }
        }
        val waMediaRecords = runCatching { folders.listWaMedia() }.getOrDefault(emptyList())
        val currentWaMediaNames = waMediaRecords.mapTo(HashSet()) { it.name }
        val waMediaChanged = synchronized(seenWaMediaNames) {
            if (seenWaMediaNames != currentWaMediaNames) {
                seenWaMediaNames.clear()
                seenWaMediaNames.addAll(currentWaMediaNames)
                true
            } else {
                false
            }
        }

        if (!initialSnapshotReady) {
            seenStatusNames.addAll(currentNames)
            initialSnapshotReady = true
            return
        }

        var foundNew = false
        for (name in currentNames) {
            if (seenStatusNames.add(name)) {
                foundNew = true
            }
        }
        val removed = seenStatusNames.retainAll(currentNames)
        if (foundNew) {
            val now = System.currentTimeMillis()
            if (now - lastNotificationAtMs > 800L) {
                lastNotificationAtMs = now
                StatusNotificationHelper.notifyNewStatus(appContext)
            }
            dispatchStatusesUpdated()
        } else if (removed || waMediaChanged) {
            dispatchStatusesUpdated()
        }
    }

    fun onStatusDetected(context: Context, fileName: String, notifyUser: Boolean = true) {
        val appContext = context.applicationContext
        if (!isSupportedMediaName(fileName)) return
        seedExistingStatuses(appContext)
        val isNew = seenStatusNames.add(fileName)
        if (isNew && notifyUser) {
            val now = System.currentTimeMillis()
            if (now - lastNotificationAtMs > 800L) {
                lastNotificationAtMs = now
                StatusNotificationHelper.notifyNewStatus(appContext)
            }
        }
        dispatchStatusesUpdated()
    }

    private fun seedExistingStatuses(appContext: Context) {
        if (initialSnapshotReady) return
        synchronized(seenStatusNames) {
            if (initialSnapshotReady) return
            val folders = StatusFolders(appContext)
            for (business in listOf(false, true)) {
                val records = runCatching { folders.list(business) }.getOrDefault(emptyList())
                for (record in records) {
                    if (isSupportedMediaName(record.name)) {
                        seenStatusNames.add(record.name)
                    }
                }
            }
            initialSnapshotReady = true
        }
    }

    private fun dispatchStatusesUpdated() {
        mainHandler.post {
            for (listener in listeners) {
                runCatching { listener.invoke() }
            }
        }
        mainHandler.postDelayed({
            for (listener in listeners) {
                runCatching { listener.invoke() }
            }
        }, 400L)
    }

    private fun isSupportedMediaName(name: String): Boolean {
        val lower = name.lowercase()
        if (lower.startsWith(".") || lower.endsWith(".was") || lower.endsWith(".nomedia")) {
            return false
        }
        return lower.endsWith(".jpg") ||
            lower.endsWith(".jpeg") ||
            lower.endsWith(".png") ||
            lower.endsWith(".webp") ||
            lower.endsWith(".gif") ||
            lower.endsWith(".mp4") ||
            lower.endsWith(".3gp") ||
            lower.endsWith(".mkv") ||
            lower.endsWith(".webm")
    }
}
