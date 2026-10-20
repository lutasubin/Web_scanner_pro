package com.example.web_scanner_pro.media

import android.content.Context
import android.net.Uri
import java.io.IOException

internal class OwnedFileRegistry(context: Context) {
    private val preferences = context.getSharedPreferences("web_scanner_media", Context.MODE_PRIVATE)

    fun all(): Set<String> = synchronized(lock) { allLocked() }

    fun contains(uri: Uri): Boolean = all().contains(uri.toString())

    fun add(uri: Uri) = synchronized(lock) { write(allLocked() + uri.toString()) }

    fun remove(uri: Uri) = synchronized(lock) { write(allLocked() - uri.toString()) }

    private fun allLocked(): Set<String> =
        preferences.getStringSet("owned_downloads", emptySet())!!.toSet()

    private fun write(uris: Set<String>) {
        if (!preferences.edit().putStringSet("owned_downloads", uris).commit()) {
            throw IOException("Cannot save file registry")
        }
    }

    companion object {
        private val lock = Any()
    }
}
