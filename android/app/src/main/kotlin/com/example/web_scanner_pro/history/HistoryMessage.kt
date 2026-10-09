package com.example.web_scanner_pro.history

import org.json.JSONObject

data class HistoryMessage(
    val id: String,
    val title: String,
    val body: String,
    val packageName: String,
    val receivedAt: Long,
) {
    fun asMap(): Map<String, Any> = mapOf("id" to id, "title" to title, "body" to body,
        "packageName" to packageName, "receivedAt" to receivedAt)
    fun asJson(): JSONObject = JSONObject(asMap())

    companion object {
        fun fromJson(json: JSONObject): HistoryMessage = HistoryMessage(
            json.getString("id"), json.getString("title"), json.getString("body"),
            json.getString("packageName"), json.getLong("receivedAt"))
    }
}
