## 0.1.0

* Initial release of `flutter_tile_service`.
* Core Android Quick Settings `TileService` support (Android 7.0+ / API 24+).
* Zero manifest boilerplate with pre-declared multi-tile service slots (`TileService0`..`TileService3`).
* Native lifecycle resilience with independent state toggling when Flutter is backgrounded or killed.
* Thread-safe native `TileStorage` persistent caching.
* Strongly typed Dart API: `TileConfig`, `TileState`, `TileSnapshot`, `TileAddResult`.
* Polymorphic native tile event streams: `TileClickedEvent`, `TileAddedEvent`, `TileRemovedEvent`, `TileListeningStartedEvent`, `TileListeningStoppedEvent`.
* Android 13+ (API 33+) `requestAddTileService` system prompt support.
* Complete sample application featuring an Attendance tracking reference implementation.
