package com.example.flutter_tile_service

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Data model for a tile's persistent state.
 */
data class TileData(
    val id: String,
    val slot: Int,
    val label: String,
    val activeLabel: String? = null,
    val inactiveLabel: String? = null,
    val description: String? = null,
    val state: String = "inactive", // "active", "inactive", "unavailable"
    val iconResourceName: String? = null,
    val autoToggleState: Boolean = true,
    val metadataJson: String? = null,
    val lastUpdatedMillis: Long = System.currentTimeMillis()
) {
    fun toMap(): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "id" to id,
            "slot" to slot,
            "label" to label,
            "activeLabel" to activeLabel,
            "inactiveLabel" to inactiveLabel,
            "description" to description,
            "state" to state,
            "iconResourceName" to iconResourceName,
            "autoToggleState" to autoToggleState,
            "lastUpdatedMillis" to lastUpdatedMillis,
            "currentLabel" to getCurrentLabel(),
            "currentDescription" to description
        )
        if (metadataJson != null) {
            try {
                val jsonObject = JSONObject(metadataJson)
                val metaMap = mutableMapOf<String, Any>()
                val keys = jsonObject.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    metaMap[key] = jsonObject.get(key)
                }
                map["metadata"] = metaMap
            } catch (_: Exception) {}
        }
        return map
    }

    fun getCurrentLabel(): String {
        return when (state.lowercase()) {
            "active" -> activeLabel?.takeIf { it.isNotEmpty() } ?: label
            "inactive" -> inactiveLabel?.takeIf { it.isNotEmpty() } ?: label
            else -> label
        }
    }

    fun toJson(): String {
        val json = JSONObject()
        json.put("id", id)
        json.put("slot", slot)
        json.put("label", label)
        json.put("activeLabel", activeLabel ?: JSONObject.NULL)
        json.put("inactiveLabel", inactiveLabel ?: JSONObject.NULL)
        json.put("description", description ?: JSONObject.NULL)
        json.put("state", state)
        json.put("iconResourceName", iconResourceName ?: JSONObject.NULL)
        json.put("autoToggleState", autoToggleState)
        json.put("metadataJson", metadataJson ?: JSONObject.NULL)
        json.put("lastUpdatedMillis", lastUpdatedMillis)
        return json.toString()
    }

    companion object {
        fun fromJson(jsonStr: String): TileData? {
            return try {
                val json = JSONObject(jsonStr)
                TileData(
                    id = json.getString("id"),
                    slot = json.getInt("slot"),
                    label = json.getString("label"),
                    activeLabel = if (json.isNull("activeLabel")) null else json.optString("activeLabel"),
                    inactiveLabel = if (json.isNull("inactiveLabel")) null else json.optString("inactiveLabel"),
                    description = if (json.isNull("description")) null else json.optString("description"),
                    state = json.optString("state", "inactive"),
                    iconResourceName = if (json.isNull("iconResourceName")) null else json.optString("iconResourceName"),
                    autoToggleState = json.optBoolean("autoToggleState", true),
                    metadataJson = if (json.isNull("metadataJson")) null else json.optString("metadataJson"),
                    lastUpdatedMillis = json.optLong("lastUpdatedMillis", System.currentTimeMillis())
                )
            } catch (e: Exception) {
                null
            }
        }
    }
}

/**
 * Thread-safe persistent storage for Quick Settings tile configurations and states.
 * Operates independently of Flutter engines.
 */
class TileStorage(context: Context) {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    companion object {
        private const val PREFS_NAME = "flutter_tile_service_storage"
        private const val KEY_TILES = "registered_tiles"
        const val MAX_SLOTS = 4

        @Volatile
        private var INSTANCE: TileStorage? = null

        fun getInstance(context: Context): TileStorage {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: TileStorage(context).also { INSTANCE = it }
            }
        }
    }

    @Synchronized
    fun saveTile(tileData: TileData): Boolean {
        val currentTiles = getAllTilesInternal().toMutableList()
        val index = currentTiles.indexOfFirst { it.id == tileData.id }
        if (index >= 0) {
            currentTiles[index] = tileData
        } else {
            currentTiles.add(tileData)
        }
        return persistTiles(currentTiles)
    }

    @Synchronized
    fun allocateSlotForTile(id: String): Int {
        val existing = getTileById(id)
        if (existing != null) {
            return existing.slot
        }
        val allTiles = getAllTilesInternal()
        val usedSlots = allTiles.map { it.slot }.toSet()
        for (slot in 0 until MAX_SLOTS) {
            if (!usedSlots.contains(slot)) {
                return slot
            }
        }
        return -1 // All slots occupied
    }

    @Synchronized
    fun getTileById(id: String): TileData? {
        return getAllTilesInternal().firstOrNull { it.id == id }
    }

    @Synchronized
    fun getTileBySlot(slot: Int): TileData? {
        return getAllTilesInternal().firstOrNull { it.slot == slot }
    }

    @Synchronized
    fun getAllTiles(): List<TileData> {
        return getAllTilesInternal()
    }

    @Synchronized
    fun deleteTile(id: String): Boolean {
        val currentTiles = getAllTilesInternal().toMutableList()
        val removed = currentTiles.removeAll { it.id == id }
        if (removed) {
            persistTiles(currentTiles)
        }
        return removed
    }

    @Synchronized
    fun updateTileState(id: String, newState: String): TileData? {
        val existing = getTileById(id) ?: return null
        val updated = existing.copy(
            state = newState,
            lastUpdatedMillis = System.currentTimeMillis()
        )
        saveTile(updated)
        return updated
    }

    @Synchronized
    fun toggleTileState(id: String): TileData? {
        val existing = getTileById(id) ?: return null
        val nextState = if (existing.state.equals("active", ignoreCase = true)) "inactive" else "active"
        return updateTileState(id, nextState)
    }

    private fun getAllTilesInternal(): List<TileData> {
        val jsonStr = prefs.getString(KEY_TILES, null) ?: return emptyList()
        val list = mutableListOf<TileData>()
        try {
            val jsonArray = JSONArray(jsonStr)
            for (i in 0 until jsonArray.length()) {
                val tileJson = jsonArray.getString(i)
                val tile = TileData.fromJson(tileJson)
                if (tile != null) {
                    list.add(tile)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return list
    }

    private fun persistTiles(tiles: List<TileData>): Boolean {
        val jsonArray = JSONArray()
        for (tile in tiles) {
            jsonArray.put(tile.toJson())
        }
        return prefs.edit().putString(KEY_TILES, jsonArray.toString()).commit()
    }
}
