package com.example.web_scanner_pro.web

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

class WebSessionStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun list(): List<StoredWebSession> {
        val saved = preferences.getString(KEY_SESSIONS, null) ?: return emptyList()
        return try {
            val json = JSONArray(saved)
            buildList {
                for (index in 0 until json.length()) {
                    val item = json.getJSONObject(index)
                    val id = item.getString("id")
                    if (isValidId(id)) add(StoredWebSession(id, item.getString("name"), id == DEFAULT_ID))
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun find(id: String): StoredWebSession? = list().firstOrNull { it.id == id }

    fun activeId(): String? {
        val sessions = list()
        val saved = preferences.getString(KEY_ACTIVE_SESSION, null)
        return saved?.takeIf { id -> sessions.any { it.id == id } } ?: sessions.firstOrNull()?.id
    }

    fun select(id: String) {
        require(find(id) != null)
        check(preferences.edit().putString(KEY_ACTIVE_SESSION, id).commit())
    }

    fun create(rawName: String): StoredWebSession {
        val name = rawName.trim()
        require(name.isNotEmpty() && name.length <= MAX_NAME_LENGTH)
        val current = list()
        val session = if (current.isEmpty()) StoredWebSession(DEFAULT_ID, name, true)
        else StoredWebSession("user_${UUID.randomUUID().toString().replace("-", "")}", name)
        save(current + session)
        if (current.isEmpty()) select(session.id)
        return session
    }

    fun rename(id: String, rawName: String): Boolean {
        val name = rawName.trim()
        require(name.isNotEmpty() && name.length <= MAX_NAME_LENGTH)
        val current = list()
        if (current.none { it.id == id }) return false
        save(current.map { if (it.id == id) it.copy(name = name) else it })
        return true
    }

    fun remove(id: String): Boolean {
        val current = list()
        val updated = current.filterNot { it.id == id }
        if (updated.size == current.size) return false
        val wasActive = activeId() == id
        save(updated)
        if (wasActive) {
            val editor = preferences.edit()
            if (updated.isEmpty()) editor.remove(KEY_ACTIVE_SESSION)
            else editor.putString(KEY_ACTIVE_SESSION, updated.first().id)
            check(editor.commit())
        }
        return true
    }

    private fun save(sessions: List<StoredWebSession>) {
        val json = JSONArray()
        sessions.forEach { session ->
            json.put(JSONObject().put("id", session.id).put("name", session.name))
        }
        check(preferences.edit().putString(KEY_SESSIONS, json.toString()).commit())
    }

    companion object {
        const val DEFAULT_ID = "personal"
        private const val PREFERENCES = "web_scanner_sessions"
        private const val KEY_SESSIONS = "sessions"
        private const val KEY_ACTIVE_SESSION = "active_session"
        private const val MAX_NAME_LENGTH = 40
        private val VALID_ID = Regex("[a-z0-9_]{1,64}")
        fun isValidId(id: String) = VALID_ID.matches(id)
    }
}
