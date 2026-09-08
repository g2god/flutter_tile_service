import 'tile_state.dart';

/// Base class for all Quick Settings Tile lifecycle and interaction events.
sealed class TileEvent {
  /// The ID of the tile associated with this event.
  final String tileId;

  /// The internal Android service slot index (0..3).
  final int slot;

  /// Timestamp in milliseconds when the event occurred.
  final int timestamp;

  const TileEvent({
    required this.tileId,
    required this.slot,
    required this.timestamp,
  });

  /// Factory constructor to parse native platform event maps into strongly-typed [TileEvent]s.
  factory TileEvent.fromMap(Map<dynamic, dynamic> map) {
    final eventType = map['eventType'] as String? ?? 'click';
    final tileId = map['tileId'] as String? ?? '';
    final slot = map['slot'] as int? ?? 0;
    final timestamp =
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    switch (eventType) {
      case 'onClick':
      case 'click':
        return TileClickedEvent(
          tileId: tileId,
          slot: slot,
          timestamp: timestamp,
          state: TileState.fromString(map['state'] as String?),
          isLocked: map['isLocked'] as bool? ?? false,
        );

      case 'onTileAdded':
      case 'tileAdded':
        return TileAddedEvent(
          tileId: tileId,
          slot: slot,
          timestamp: timestamp,
        );

      case 'onTileRemoved':
      case 'tileRemoved':
        return TileRemovedEvent(
          tileId: tileId,
          slot: slot,
          timestamp: timestamp,
        );

      case 'onStartListening':
      case 'startListening':
        return TileListeningStartedEvent(
          tileId: tileId,
          slot: slot,
          timestamp: timestamp,
        );

      case 'onStopListening':
      case 'stopListening':
        return TileListeningStoppedEvent(
          tileId: tileId,
          slot: slot,
          timestamp: timestamp,
        );

      default:
        return TileClickedEvent(
          tileId: tileId,
          slot: slot,
          timestamp: timestamp,
          state: TileState.fromString(map['state'] as String?),
          isLocked: map['isLocked'] as bool? ?? false,
        );
    }
  }
}

/// Fired when the user taps the Quick Settings Tile in their notification shade.
class TileClickedEvent extends TileEvent {
  /// The current native state of the tile immediately following the click.
  final TileState state;

  /// Whether the device is currently locked (keyguard is active).
  final bool isLocked;

  const TileClickedEvent({
    required super.tileId,
    required super.slot,
    required super.timestamp,
    required this.state,
    this.isLocked = false,
  });

  @override
  String toString() =>
      'TileClickedEvent(tileId: $tileId, slot: $slot, state: $state, isLocked: $isLocked)';
}

/// Fired when the user adds this tile to their active Quick Settings grid.
class TileAddedEvent extends TileEvent {
  const TileAddedEvent({
    required super.tileId,
    required super.slot,
    required super.timestamp,
  });

  @override
  String toString() => 'TileAddedEvent(tileId: $tileId, slot: $slot)';
}

/// Fired when the user removes this tile from their active Quick Settings grid.
class TileRemovedEvent extends TileEvent {
  const TileRemovedEvent({
    required super.tileId,
    required super.slot,
    required super.timestamp,
  });

  @override
  String toString() => 'TileRemovedEvent(tileId: $tileId, slot: $slot)';
}

/// Fired when the Quick Settings panel is pulled down and the tile enters the listening window.
class TileListeningStartedEvent extends TileEvent {
  const TileListeningStartedEvent({
    required super.tileId,
    required super.slot,
    required super.timestamp,
  });

  @override
  String toString() =>
      'TileListeningStartedEvent(tileId: $tileId, slot: $slot)';
}

/// Fired when the Quick Settings panel is closed and the tile leaves the listening window.
class TileListeningStoppedEvent extends TileEvent {
  const TileListeningStoppedEvent({
    required super.tileId,
    required super.slot,
    required super.timestamp,
  });

  @override
  String toString() =>
      'TileListeningStoppedEvent(tileId: $tileId, slot: $slot)';
}
