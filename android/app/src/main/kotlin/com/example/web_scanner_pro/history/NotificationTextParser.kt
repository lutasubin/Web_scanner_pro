package com.example.web_scanner_pro.history

import android.app.Notification
import android.service.notification.StatusBarNotification
import java.security.MessageDigest

object NotificationTextParser {
    private val groupCountSuffix = Regex("""\s*\(\d+\s+(?:messages?|tin nhắn|mensajes?|messages)\)\s*:?\s*$""", RegexOption.IGNORE_CASE)

    fun parse(notification: StatusBarNotification): List<HistoryMessage> {
        val content = notification.notification
        if (content.flags and Notification.FLAG_GROUP_SUMMARY != 0) return emptyList()
        val rawTitle = content.extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()
            ?: content.extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
            .orEmpty()
        val title = normalizeTitle(rawTitle)
        val body = (content.extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: content.extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        return listOfNotNull(create(notification, title, body, notification.postTime))
    }

    internal fun normalizeTitle(rawTitle: String): String {
        val trimmed = rawTitle.trim()
        if (trimmed.isEmpty()) return "WhatsApp"
        // Strip group message count suffixes like "Nhóm ABC (3 tin nhắn): Lan" -> "Nhóm ABC: Lan" or "Nhóm ABC"
        val colonIndex = trimmed.lastIndexOf(':')
        if (colonIndex > 0) {
            val prefix = trimmed.substring(0, colonIndex).replace(groupCountSuffix, "").trim()
            val sender = trimmed.substring(colonIndex + 1).trim()
            if (prefix.isNotEmpty() && sender.isNotEmpty()) {
                return "$prefix · $sender"
            }
        }
        return trimmed.replace(groupCountSuffix, "").trim().ifEmpty { "WhatsApp" }
    }

    private fun create(source: StatusBarNotification, title: String, body: String, time: Long): HistoryMessage? {
        if (body.isBlank()) return null
        val now = System.currentTimeMillis()
        val received = time.takeIf { it in 1..(now + 60_000) } ?: now
        val safeTitle = title.take(300)
        val safeBody = body.take(6000)
        val raw = "${source.packageName}\u0000${source.key}\u0000$received\u0000$safeTitle\u0000$safeBody"
        val id = MessageDigest.getInstance("SHA-256").digest(raw.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
        return HistoryMessage(id, safeTitle, safeBody, source.packageName, received)
    }
}
