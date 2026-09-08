import 'tile_config.dart';
import 'tile_state.dart';

/// Represents the runtime snapshot of a registered Quick Settings Tile.
class TileSnapshot {
  /// The unique logical ID of the tile.
  final String id;

  /// The internal Android service slot index (0..3).
  final int slot;

  /// The full configuration of the tile.
  final TileConfig config;

  /// The current state of the tile.
  final TileState state;

  /// The currently displayed label on the tile.
  final String currentLabel;

  /// The currently displayed subtitle/description on the tile.
  final String? currentDescription;

  /// Timestamp in milliseconds when the state was last updated.
  final int lastUpdatedMillis;

  const TileSnapshot({
    required this.id,
    required this.slot,
    required this.config,
    required this.state,
    required this.currentLabel,
    this.currentDescription,
    required this.lastUpdatedMillis,
  });

  /// Creates a [TileSnapshot] from a serialized map.
  factory TileSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final configMap = map['config'] != null
        ? Map<dynamic, dynamic>.from(map['config'] as Map)
        : map;
    return TileSnapshot(
      id: map['id'] as String,
      slot: map['slot'] as int? ?? 0,
      config: TileConfig.fromMap(configMap),
      state: TileState.fromString(map['state'] as String?),
      currentLabel:
          map['currentLabel'] as String? ?? (map['label'] as String? ?? ''),
      currentDescription: map['currentDescription'] as String? ??
          (map['description'] as String?),
      lastUpdatedMillis: map['lastUpdatedMillis'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'TileSnapshot(id: $id, slot: $slot, state: $state, label: $currentLabel)';
  }
}
