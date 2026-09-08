package com.example.flutter_tile_service

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Singleton event bus connecting Android native TileService lifecycle events to Flutter.
 * If Flutter is dead or disconnected, events are safely ignored without crashing or blocking.
 */
object TileEventSink {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        synchronized(this) {
            eventSink = sink
        }
    }

    fun dispatchEvent(
        eventType: String,
        tileId: String,
        slot: Int,
        state: String? = null,
        isLocked: Boolean = false,
        extraData: Map<String, Any?>? = null
    ) {
        val eventMap = mutableMapOf<String, Any?>(
            "eventType" to eventType,
            "tileId" to tileId,
            "slot" to slot,
            "timestamp" to System.currentTimeMillis()
        )
        if (state != null) eventMap["state"] = state
        eventMap["isLocked"] = isLocked
        if (extraData != null) {
            eventMap.putAll(extraData)
        }

        mainHandler.post {
            synchronized(this) {
                try {
                    eventSink?.success(eventMap)
                } catch (e: Exception) {
                    // Flutter engine may be tearing down or closed
                }
            }
        }
    }
}
