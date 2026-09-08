/// Represents the state of an Android Quick Settings Tile.
///
/// Corresponds directly to Android's `android.service.quicksettings.Tile` states:
/// - [TileState.active] -> `Tile.STATE_ACTIVE` (enabled / highlighted)
/// - [TileState.inactive] -> `Tile.STATE_INACTIVE` (disabled / normal)
/// - [TileState.unavailable] -> `Tile.STATE_UNAVAILABLE` (greyed out / cannot be toggled)
enum TileState {
  /// The tile is currently active (on/highlighted).
  active,

  /// The tile is currently inactive (off/normal).
  inactive,

  /// The tile is currently unavailable (disabled/unclickable).
  unavailable;

  /// Parses a string representation into a [TileState].
  static TileState fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'active':
        return TileState.active;
      case 'inactive':
        return TileState.inactive;
      case 'unavailable':
        return TileState.unavailable;
      default:
        return TileState.inactive;
    }
  }

  /// Converts this [TileState] to a standard string.
  String toValue() => name;
}
