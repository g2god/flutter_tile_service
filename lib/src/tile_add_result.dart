/// Result of requesting the system to add a Quick Settings Tile (Android 13+ / API 33+).
enum TileAddResult {
  /// The tile was added to the Quick Settings panel by the user.
  added,

  /// The tile is already present in the Quick Settings panel.
  alreadyAdded,

  /// The system displayed the dialog / prompt requesting the user to add the tile.
  requested,

  /// Tile addition is not supported or not available (e.g. Android < 13 or device does not support QS).
  unavailable,

  /// The user declined or cancelled the request to add the tile.
  denied;

  /// Parses an integer status code or string from Android `requestAddTileService`.
  static TileAddResult fromPlatform(dynamic value) {
    if (value is int) {
      // Android StatusBarManager.TILE_ADD_REQUEST_RESULT_*
      // 0 = TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED
      // 1 = TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED
      // 2 = TILE_ADD_REQUEST_RESULT_TILE_ADDED
      switch (value) {
        case 2:
          return TileAddResult.added;
        case 1:
          return TileAddResult.alreadyAdded;
        case 0:
          return TileAddResult.denied;
        default:
          return TileAddResult.requested;
      }
    } else if (value is String) {
      switch (value.toLowerCase()) {
        case 'added':
          return TileAddResult.added;
        case 'alreadyadded':
        case 'already_added':
          return TileAddResult.alreadyAdded;
        case 'requested':
          return TileAddResult.requested;
        case 'unavailable':
          return TileAddResult.unavailable;
        case 'denied':
          return TileAddResult.denied;
        default:
          return TileAddResult.requested;
      }
    }
    return TileAddResult.unavailable;
  }
}
