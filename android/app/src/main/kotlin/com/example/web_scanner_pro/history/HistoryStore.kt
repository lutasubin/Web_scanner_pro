package com.example.web_scanner_pro.history

import android.content.Context
import android.util.AtomicFile
import org.json.JSONArray
import java.io.File

class HistoryStore(context: Context) {
    private val file = AtomicFile(File(context.noBackupFilesDir, "notification_history.enc"))
    private val cipher = HistoryCipher()

    fun list(): List<HistoryMessage> = synchronized(lock) {
        val original = read()
        val retained = retain(original)
        if (retained.size != original.size) write(retained)
        retained
    }

    fun append(messages: List<HistoryMessage>) = synchronized(lock) {
        val combined = (read() + messages).distinctBy { it.id }
        write(retain(combined))
    }

    fun deleteMessage(id: String) = synchronized(lock) {
        if (id.isBlank()) return
        val remaining = read().filterNot { it.id == id }
        write(retain(remaining))
    }

    fun deleteConversation(title: String, packageName: String) = synchronized(lock) {
        val remaining = read().filterNot {
            it.title == title && (packageName.isBlank() || it.packageName == packageName)
        }
        write(retain(remaining))
    }

    fun clear() = synchronized(lock) {
        file.delete()
        check(!file.baseFile.exists()) { "Không xóa được lịch sử" }
        cipher.deleteKey()
    }

    private fun retain(messages: List<HistoryMessage>): List<HistoryMessage> {
        val cutoff = System.currentTimeMillis() - 30L * 24 * 60 * 60 * 1000
        return messages.filter { it.receivedAt >= cutoff }.sortedByDescending { it.receivedAt }.take(1000)
    }

    private fun read(): List<HistoryMessage> {
        if (!file.baseFile.exists()) return emptyList()
        val data = JSONArray(String(cipher.decrypt(file.readFully()), Charsets.UTF_8))
        return List(data.length()) { HistoryMessage.fromJson(data.getJSONObject(it)) }
    }

    private fun write(messages: List<HistoryMessage>) {
        val json = JSONArray().apply { messages.forEach { put(it.asJson()) } }
        val bytes = cipher.encrypt(json.toString().toByteArray(Charsets.UTF_8))
        val output = file.startWrite()
        try { output.write(bytes); file.finishWrite(output) }
        catch (error: Exception) { file.failWrite(output); throw error }
    }

    companion object { private val lock = Any() }
}
