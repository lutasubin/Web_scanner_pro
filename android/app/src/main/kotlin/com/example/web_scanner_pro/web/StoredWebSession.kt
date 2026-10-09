package com.example.web_scanner_pro.web

data class StoredWebSession(
    val id: String,
    val name: String,
    val isDefault: Boolean = false,
) {
    fun toMap() = mapOf("id" to id, "name" to name, "isDefault" to isDefault)
}
