package com.example.flutter_tile_service

import android.app.Activity
import android.app.StatusBarManager
import android.content.ComponentName
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.TileService
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import java.util.concurrent.Executor

/**
 * FlutterTileServicePlugin
 *
 * Implements FlutterPlugin, MethodCallHandler, StreamHandler, and ActivityAware.
 */
class FlutterTileServicePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var storage: TileStorage? = null

    companion object {
        private const val METHOD_CHANNEL_NAME = "com.example.flutter_tile_service/methods"
        private const val EVENT_CHANNEL_NAME = "com.example.flutter_tile_service/events"

        val SLOT_CLASSES = arrayOf(
            TileService0::class.java,
            TileService1::class.java,
            TileService2::class.java,
            TileService3::class.java
        )
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        storage = TileStorage.getInstance(flutterPluginBinding.applicationContext)

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context = null
    }

    // --- StreamHandler for EventChannel ---

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        TileEventSink.setEventSink(events)
    }

    override fun onCancel(arguments: Any?) {
        TileEventSink.setEventSink(null)
    }

    // --- ActivityAware ---

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // --- MethodCallHandler ---

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val currentContext = context
        val currentStorage = storage
        if (currentContext == null || currentStorage == null) {
            result.error("NOT_INITIALIZED", "Plugin context is null", null)
            return
        }

        when (call.method) {
            "isSupported" -> {
                val isSupported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N
                result.success(isSupported)
            }

            "initialize" -> {
                result.success(true)
            }

            "registerTile" -> {
                try {
                    val id = call.argument<String>("id")
                    val label = call.argument<String>("label")
                    if (id.isNullOrEmpty() || label.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENTS", "Tile id and label are required", null)
                        return
                    }

                    val slot = currentStorage.allocateSlotForTile(id)
                    if (slot < 0 || slot >= SLOT_CLASSES.size) {
                        result.error(
                            "MAX_SLOTS_REACHED",
                            "All available Quick Settings tile slots (${SLOT_CLASSES.size}) are occupied",
                            null
                        )
                        return
                    }

                    val activeLabel = call.argument<String>("activeLabel")
                    val inactiveLabel = call.argument<String>("inactiveLabel")
                    val description = call.argument<String>("description")
                    val initialState = call.argument<String>("initialState") ?: "inactive"
                    val iconResourceName = call.argument<String>("iconResourceName")
                    val autoToggleState = call.argument<Boolean>("autoToggleState") ?: true
                    val metadata = call.argument<Map<String, Any>>("metadata")

                    val metadataJson = if (metadata != null) JSONObject(metadata).toString() else null

                    val tileData = TileData(
                        id = id,
                        slot = slot,
                        label = label,
                        activeLabel = activeLabel,
                        inactiveLabel = inactiveLabel,
                        description = description,
                        state = initialState,
                        iconResourceName = iconResourceName,
                        autoToggleState = autoToggleState,
                        metadataJson = metadataJson
                    )

                    currentStorage.saveTile(tileData)
                    requestTileListening(slot)

                    result.success(tileData.toMap())
                } catch (e: Exception) {
                    result.error("REGISTER_ERROR", e.message, null)
                }
            }

            "unregisterTile" -> {
                try {
                    val id = call.argument<String>("id")
                    if (id.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENTS", "Tile id is required", null)
                        return
                    }
                    val existing = currentStorage.getTileById(id)
                    val removed = currentStorage.deleteTile(id)
                    if (removed && existing != null) {
                        requestTileListening(existing.slot)
                    }
                    result.success(removed)
                } catch (e: Exception) {
                    result.error("UNREGISTER_ERROR", e.message, null)
                }
            }

            "updateTile" -> {
                try {
                    val id = call.argument<String>("id")
                    if (id.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENTS", "Tile id is required", null)
                        return
                    }

                    val existing = currentStorage.getTileById(id)
                    if (existing == null) {
                        result.error("TILE_NOT_FOUND", "No tile registered with id: $id", null)
                        return
                    }

                    val state = call.argument<String>("state") ?: existing.state
                    val label = call.argument<String>("label") ?: existing.label
                    val description = if (call.hasArgument("description")) call.argument<String>("description") else existing.description
                    val iconResourceName = if (call.hasArgument("iconResourceName")) call.argument<String>("iconResourceName") else existing.iconResourceName

                    val updated = existing.copy(
                        state = state,
                        label = label,
                        description = description,
                        iconResourceName = iconResourceName,
                        lastUpdatedMillis = System.currentTimeMillis()
                    )

                    currentStorage.saveTile(updated)
                    requestTileListening(updated.slot)

                    result.success(updated.toMap())
                } catch (e: Exception) {
                    result.error("UPDATE_ERROR", e.message, null)
                }
            }

            "getTile" -> {
                val id = call.argument<String>("id")
                if (id.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENTS", "Tile id is required", null)
                    return
                }
                val tileData = currentStorage.getTileById(id)
                if (tileData != null) {
                    result.success(tileData.toMap())
                } else {
                    result.success(null)
                }
            }

            "getTiles" -> {
                val tiles = currentStorage.getAllTiles().map { it.toMap() }
                result.success(tiles)
            }

            "requestAddTile" -> {
                handleRequestAddTile(call, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun requestTileListening(slot: Int) {
        val currentContext = context ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && slot in SLOT_CLASSES.indices) {
            val serviceClass = SLOT_CLASSES[slot]
            TileServiceBase.requestListeningState(currentContext, serviceClass)
        }
    }

    private fun handleRequestAddTile(call: MethodCall, result: Result) {
        val currentContext = context ?: return
        val id = call.argument<String>("id")
        if (id.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "Tile id is required", null)
            return
        }

        val tileData = storage?.getTileById(id)
        if (tileData == null) {
            result.error("TILE_NOT_FOUND", "Tile $id is not registered", null)
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            // requestAddTileService was introduced in Android 13 (API 33)
            result.success("unavailable")
            return
        }

        val slot = tileData.slot
        if (slot !in SLOT_CLASSES.indices) {
            result.error("INVALID_SLOT", "Tile has invalid slot: $slot", null)
            return
        }

        val serviceClass = SLOT_CLASSES[slot]
        val componentName = ComponentName(currentContext, serviceClass)

        val statusBarManager = currentContext.getSystemService(Context.STATUS_BAR_SERVICE) as? StatusBarManager
        if (statusBarManager == null) {
            result.success("unavailable")
            return
        }

        // Icon for the dialog
        var icon: Icon? = null
        if (!tileData.iconResourceName.isNullOrEmpty()) {
            val resId = currentContext.resources.getIdentifier(
                tileData.iconResourceName,
                "drawable",
                currentContext.packageName
            )
            if (resId != 0) {
                icon = Icon.createWithResource(currentContext, resId)
            }
        }
        if (icon == null) {
            icon = Icon.createWithResource(currentContext, R.drawable.ic_tile_default)
        }

        val executor = Executor { it.run() }

        try {
            statusBarManager.requestAddTileService(
                componentName,
                tileData.getCurrentLabel(),
                icon,
                executor
            ) { resultCode ->
                // resultCode from StatusBarManager.TILE_ADD_REQUEST_RESULT_*
                // 0 = TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED
                // 1 = TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED
                // 2 = TILE_ADD_REQUEST_RESULT_TILE_ADDED
                val statusString = when (resultCode) {
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED -> "added"
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED -> "alreadyAdded"
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED -> "denied"
                    else -> "requested"
                }
                activity?.runOnUiThread {
                    result.success(statusString)
                } ?: run {
                    result.success(statusString)
                }
            }
        } catch (e: Exception) {
            result.error("REQUEST_ADD_FAILED", e.message, null)
        }
    }
}
