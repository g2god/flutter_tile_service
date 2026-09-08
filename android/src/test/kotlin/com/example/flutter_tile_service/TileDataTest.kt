package com.example.flutter_tile_service

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class TileDataTest {

    @Test
    fun testTileDataSerialization() {
        val tile = TileData(
            id = "attendance",
            slot = 0,
            label = "Attendance",
            activeLabel = "Checked IN",
            inactiveLabel = "Checked OUT",
            description = "Daily shift",
            state = "active",
            iconResourceName = "ic_tile_attendance",
            autoToggleState = true,
            metadataJson = JSONObject(mapOf("shift" to "morning")).toString(),
            lastUpdatedMillis = 1700000000L
        )

        val jsonString = tile.toJson()
        val deserialized = TileData.fromJson(jsonString)

        assertNotNull(deserialized)
        assertEquals(tile.id, deserialized?.id)
        assertEquals(tile.slot, deserialized?.slot)
        assertEquals(tile.label, deserialized?.label)
        assertEquals(tile.activeLabel, deserialized?.activeLabel)
        assertEquals(tile.inactiveLabel, deserialized?.inactiveLabel)
        assertEquals(tile.description, deserialized?.description)
        assertEquals(tile.state, deserialized?.state)
        assertEquals(tile.iconResourceName, deserialized?.iconResourceName)
        assertEquals(tile.autoToggleState, deserialized?.autoToggleState)
        assertEquals(tile.lastUpdatedMillis, deserialized?.lastUpdatedMillis)
        assertEquals("Checked IN", deserialized?.getCurrentLabel())
    }

    @Test
    fun testGetCurrentLabel() {
        val tileActive = TileData(
            id = "test",
            slot = 0,
            label = "Default",
            activeLabel = "Active Label",
            inactiveLabel = "Inactive Label",
            state = "active"
        )
        assertEquals("Active Label", tileActive.getCurrentLabel())

        val tileInactive = tileActive.copy(state = "inactive")
        assertEquals("Inactive Label", tileInactive.getCurrentLabel())

        val tileFallback = TileData(
            id = "test",
            slot = 0,
            label = "Default",
            state = "active"
        )
        assertEquals("Default", tileFallback.getCurrentLabel())
    }
}
