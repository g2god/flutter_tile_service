import 'dart:async';
import 'method_channel_tile_service.dart';
import 'tile.dart';
import 'tile_add_result.dart';
import 'tile_config.dart';
import 'tile_event.dart';
import 'tile_state.dart';

/// Primary public Dart API for managing Android Quick Settings Tiles.
class FlutterTileService {
  FlutterTileService._();

  static MethodChannelTileService _platform = MethodChannelTileService();

  /// For unit testing: overrides the underlying platform service.
  static void setPlatformInstance(MethodChannelTileService platform) {
    _platform = platform;
  }

  /// Checks if Quick Settings Tiles are supported on this device (Android 7.0 / API 24+).
  static Future<bool> isSupported() => _platform.isSupported();

  /// Initializes the tile service plugin and syncs native storage.
  static Future<void> initialize() => _platform.initialize();

  /// Registers a Quick Settings Tile with the given configuration.
  ///
  /// Allocates one of the pre-declared native service slots (up to the manifest maximum).
  /// If a tile with [config.id] already exists, it is updated in place.
  static Future<TileSnapshot> registerTile(TileConfig config) {
    return _platform.registerTile(config);
  }

  /// Unregisters a tile with the given [tileId] and frees its service slot.
  static Future<bool> unregisterTile(String tileId) {
    return _platform.unregisterTile(tileId);
  }

  /// Updates a registered tile's state, label, or subtitle dynamically.
  ///
  /// This instantly updates native storage and triggers `Tile.updateTile()` in Android.
  static Future<TileSnapshot> updateTile({
    required String id,
    TileState? state,
    String? label,
    String? description,
    String? iconResourceName,
  }) {
    return _platform.updateTile(
      id: id,
      state: state,
      label: label,
      description: description,
      iconResourceName: iconResourceName,
    );
  }

  /// Gets the current native snapshot of a specific registered tile.
  static Future<TileSnapshot?> getTile(String tileId) {
    return _platform.getTile(tileId);
  }

  /// Gets all registered tile snapshots currently persisted in native storage.
  static Future<List<TileSnapshot>> getTiles() {
    return _platform.getTiles();
  }

  /// Requests the Android system to prompt the user to add the tile to their Quick Settings panel.
  ///
  /// Requires Android 13 (API 33)+. On older Android versions, returns [TileAddResult.unavailable].
  static Future<TileAddResult> requestAddTile(String tileId) {
    return _platform.requestAddTile(tileId);
  }

  /// Global broadcast stream of native Quick Settings tile events.
  ///
  /// Yields typed events:
  /// - [TileClickedEvent]
  /// - [TileAddedEvent]
  /// - [TileRemovedEvent]
  /// - [TileListeningStartedEvent]
  /// - [TileListeningStoppedEvent]
  static Stream<TileEvent> get events => _platform.events;
}
