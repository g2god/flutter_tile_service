package com.example.flutter_tile_service

import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log

/**
 * Base TileService implementation handling lifecycle, native updates, and Flutter event routing.
 * Does NOT require Flutter engine to be alive.
 */
abstract class TileServiceBase : TileService() {
    companion object {
        private const val TAG = "TileServiceBase"

        /**
         * Requests the system to update a specific tile service class.
         */
        fun requestListeningState(context: android.content.Context, serviceClass: Class<out TileService>) {
            try {
                requestListeningState(context, android.content.ComponentName(context, serviceClass))
            } catch (e: Exception) {
                Log.e(TAG, "Failed to requestListeningState for ${serviceClass.simpleName}", e)
            }
        }
    }

    /**
     * The fixed slot number assigned to this concrete TileService subclass (0..3).
     */
    abstract val slot: Int

    private val storage: TileStorage by lazy { TileStorage.getInstance(this) }

    override fun onStartListening() {
        super.onStartListening()
        updateTileFromStorage()
        val tileData = storage.getTileBySlot(slot)
        if (tileData != null) {
            TileEventSink.dispatchEvent(
                eventType = "onStartListening",
                tileId = tileData.id,
                slot = slot
            )
        }
    }

    override fun onStopListening() {
        super.onStopListening()
        val tileData = storage.getTileBySlot(slot)
        if (tileData != null) {
            TileEventSink.dispatchEvent(
                eventType = "onStopListening",
                tileId = tileData.id,
                slot = slot
            )
        }
    }

    override fun onTileAdded() {
        super.onTileAdded()
        updateTileFromStorage()
        val tileData = storage.getTileBySlot(slot)
        if (tileData != null) {
            TileEventSink.dispatchEvent(
                eventType = "onTileAdded",
                tileId = tileData.id,
                slot = slot
            )
        }
    }

    override fun onTileRemoved() {
        super.onTileRemoved()
        val tileData = storage.getTileBySlot(slot)
        if (tileData != null) {
            TileEventSink.dispatchEvent(
                eventType = "onTileRemoved",
                tileId = tileData.id,
                slot = slot
            )
        }
    }

    override fun onClick() {
        super.onClick()
        val tileData = storage.getTileBySlot(slot)
        if (tileData == null) {
            // Tile not configured yet; refresh UI
            updateTileFromStorage()
            return
        }

        var currentData = tileData

        // If auto-toggle is enabled, toggle state natively first
        if (tileData.autoToggleState) {
            val updated = storage.toggleTileState(tileData.id)
            if (updated != null) {
                currentData = updated
            }
        }

        // Apply updated state to the system Quick Settings Tile immediately
        applyTileData(currentData)

        val isLocked = isLocked

        // Notify Flutter if it is alive (non-blocking)
        TileEventSink.dispatchEvent(
            eventType = "onClick",
            tileId = currentData.id,
            slot = slot,
            state = currentData.state,
            isLocked = isLocked
        )
    }

    /**
     * Refreshes the visual representation of this QS Tile using data from persistent storage.
     */
    fun updateTileFromStorage() {
        val tileData = storage.getTileBySlot(slot)
        applyTileData(tileData)
    }

    private fun applyTileData(tileData: TileData?) {
        val tile = qsTile ?: return

        if (tileData == null) {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "Tile $slot"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tile.subtitle = null
            }
            tile.updateTile()
            return
        }

        // Set tile state
        when (tileData.state.lowercase()) {
            "active" -> tile.state = Tile.STATE_ACTIVE
            "unavailable" -> tile.state = Tile.STATE_UNAVAILABLE
            else -> tile.state = Tile.STATE_INACTIVE
        }

        // Set label based on active/inactive state
        tile.label = tileData.getCurrentLabel()

        // Set description / subtitle (Android 10+ / API 29+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = tileData.description
        }

        // Set custom icon if configured
        if (!tileData.iconResourceName.isNullOrEmpty()) {
            try {
                val resId = resources.getIdentifier(
                    tileData.iconResourceName,
                    "drawable",
                    packageName
                )
                if (resId != 0) {
                    tile.icon = Icon.createWithResource(this, resId)
                }
            } catch (e: Exception) {
                Log.w(TAG, "Could not load icon resource ${tileData.iconResourceName}", e)
            }
        }

        tile.updateTile()
    }
}
