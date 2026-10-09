package com.example.web_scanner_pro.history

import android.app.Notification
import android.service.notification.StatusBarNotification
import java.security.MessageDigest

object NotificationTextParser {
    fun parse(notification: StatusBarNotification): List<HistoryMessage> {
        val content = notification.notification
        if (content.flags and Notification.FLAG_GROUP_SUMMARY != 0) return emptyList()
        val title = content.extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val body = (content.extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: content.extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        return listOfNotNull(create(notification, title, body, notification.postTime))
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
