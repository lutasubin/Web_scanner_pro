package com.example.web_scanner_pro.web

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

class WebSessionStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun list(): List<StoredWebSession> {
        val saved = preferences.getString(KEY_SESSIONS, null) ?: return defaults().also(::save)
        return try {
            val json = JSONArray(saved)
            buildList {
                for (index in 0 until json.length()) {
                    val item = json.getJSONObject(index)
                    val id = item.getString("id")
                    if (isValidId(id)) add(StoredWebSession(id, item.getString("name"), id == DEFAULT_ID))
                }
            }.ifEmpty { defaults().also(::save) }
        } catch (_: Exception) {
            defaults().also(::save)
        }
    }

    fun find(id: String): StoredWebSession? = list().firstOrNull { it.id == id }

    fun create(rawName: String): StoredWebSession {
        val name = rawName.trim()
        require(name.isNotEmpty() && name.length <= MAX_NAME_LENGTH)
        val session = StoredWebSession("user_${UUID.randomUUID().toString().replace("-", "")}", name)
        save(list() + session)
        return session
    }

    fun remove(id: String): Boolean {
        if (id == DEFAULT_ID) return false
        val current = list()
        val updated = current.filterNot { it.id == id }
        if (updated.size == current.size) return false
        save(updated)
        return true
    }

    private fun save(sessions: List<StoredWebSession>) {
        val json = JSONArray()
        sessions.forEach { session ->
            json.put(JSONObject().put("id", session.id).put("name", session.name))
        }
        check(preferences.edit().putString(KEY_SESSIONS, json.toString()).commit())
    }

    private fun defaults() = listOf(
        StoredWebSession(DEFAULT_ID, "Cá nhân", true),
        StoredWebSession("business", "Công việc"),
    )

    companion object {
        const val DEFAULT_ID = "personal"
        private const val PREFERENCES = "web_scanner_sessions"
        private const val KEY_SESSIONS = "sessions"
        private const val MAX_NAME_LENGTH = 40
        private val VALID_ID = Regex("[a-z0-9_]{1,64}")
        fun isValidId(id: String) = VALID_ID.matches(id)
    }
}
