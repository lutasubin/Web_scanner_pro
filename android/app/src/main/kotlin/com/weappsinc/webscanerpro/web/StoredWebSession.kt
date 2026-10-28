package com.weappsinc.webscanerpro.web

data class StoredWebSession(
    val id: String,
    val name: String,
    val isDefault: Boolean = false,
) {
    fun toMap(activeId: String?) = mapOf(
        "id" to id,
        "name" to name,
        "isDefault" to isDefault,
        "isActive" to (id == activeId),
    )
}
