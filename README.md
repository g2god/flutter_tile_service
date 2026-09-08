# flutter_tile_service

[![pub points](https://img.shields.io/pub/points/flutter_tile_service.svg)](https://pub.dev/packages/flutter_tile_service)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A production-ready Flutter plugin for Android **Quick Settings Tiles** (`android.service.quicksettings.TileService`).

Easily register, configure, update, query, and receive real-time events from Quick Settings Tiles directly in Flutter—without writing Kotlin code or editing `AndroidManifest.xml` in your app.

---

## Features

- **Zero Manifest Boilerplate**: Uses pre-declared manifest service slots (`TileService0`..`TileService3`) that automatically merge into your application.
- **Native Lifecycle Resilience**: Designed from the ground up so Android's `TileService` functions independently when the Flutter app is dead, killed, backgrounded, or after a device reboot.
- **Persistent Native State**: Tile states and configurations are persisted via thread-safe native storage and synchronized back to Dart upon startup.
- **Strongly Typed Dart API**: Fully typed states (`TileState`), polymorphic events (`TileClickedEvent`, `TileListeningStartedEvent`, etc.), and `TileConfig` with rich customization options.
- **Dynamic Tile Updates**: Change title, subtitle/description, active/inactive labels, and state on the fly.
- **Android 13+ Tile Request Prompt**: Support for `requestAddTile` (`StatusBarManager.requestAddTileService`) allowing apps to prompt users to add tiles with a single click.

---

## Architecture Overview

```
                      ┌───────────────────────────────────────┐
                      │        Flutter Dart Application        │
                      │   FlutterTileService.registerTile()   │
                      │   FlutterTileService.updateTile()     │
                      │   FlutterTileService.events stream    │
                      └──────────────────┬────────────────────┘
                                         │ (MethodChannel & EventChannel)
═════════════════════════════════════════╪═════════════════════════════════════
                      ┌──────────────────▼────────────────────┐
                      │      FlutterTileServicePlugin         │
                      └──────────────────┬────────────────────┘
                                         │
                      ┌──────────────────▼────────────────────┐
                      │    Thread-Safe TileStorage (Native)   │
                      │   (JSON / SharedPreferences storage)  │
                      └──────────────────┬────────────────────┘
                                         │
         ┌───────────────────────────────┴───────────────────────────────┐
         │                                                               │
┌────────▼────────┐                                             ┌────────▼────────┐
│  TileService0   │  (Pre-declared in Plugin AndroidManifest)   │  TileService3   │
│ (Attendance ID) │                                             │   (Custom ID)   │
└────────┬────────┘                                             └────────┬────────┘
         │                                                               │
═════════╪═══════════════════════════════════════════════════════════════╪═════
         ▼                                                               ▼
   ┌───────────────────────────────────────────────────────────────────────────┐
   │                    Android Quick Settings Shade Panel                     │
   │               [ Attendance: IN ]       [ VPN: OFF ]                       │
   └───────────────────────────────────────────────────────────────────────────┘
```

---

## Platform Support

| Platform | Min SDK | Supported | Notes |
| :--- | :--- | :--- | :--- |
| **Android** | API 24 (7.0+) | Yes | `requestAddTile` requires Android 13 (API 33+) |
| **iOS** | - | Planned | Architectural structure ready; no fake APIs |

---

## Getting Started

### 1. Installation

Add `flutter_tile_service` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_tile_service: ^0.1.0
```

### 2. Basic Initialization & Registration

Initialize the service and register a Quick Settings Tile in your `main()` or service initialization:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_tile_service/flutter_tile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize the plugin
  await FlutterTileService.initialize();

  // 2. Listen to tile clicks and lifecycle events
  FlutterTileService.events.listen((event) {
    if (event is TileClickedEvent) {
      print('User tapped tile: ${event.tileId}, state is now: ${event.state.name}');
      // Trigger your app logic (e.g. record punch, send network request, etc.)
    }
  });

  // 3. Register a Quick Settings Tile
  await FlutterTileService.registerTile(
    const TileConfig(
      id: 'attendance',
      label: 'Attendance',
      activeLabel: 'IN',
      inactiveLabel: 'OUT',
      description: 'Daily Attendance Punch',
      initialState: TileState.inactive,
      autoToggleState: true, // Native state automatically flips on click even if app is dead
    ),
  );

  runApp(const MyApp());
}
```

---

## Usage Guide

### Updating a Tile Programmatically

Update the tile's state or text whenever your Flutter app state changes:

```dart
await FlutterTileService.updateTile(
  id: 'attendance',
  state: TileState.active,
  label: 'IN',
  description: 'Clocked In at 9:00 AM',
);
```

### Requesting the System to Add a Tile (Android 13+)

On Android 13 (API 33) and above, prompt the user with a system dialog to add the tile directly to their Quick Settings panel:

```dart
final result = await FlutterTileService.requestAddTile('attendance');

switch (result) {
  case TileAddResult.added:
    print('Tile added to Quick Settings!');
    break;
  case TileAddResult.alreadyAdded:
    print('Tile is already in Quick Settings panel.');
    break;
  case TileAddResult.denied:
    print('User declined the prompt.');
    break;
  case TileAddResult.unavailable:
    print('Feature not available (Android < 13 or unsupported device).');
    break;
  case TileAddResult.requested:
    print('Request prompt sent.');
    break;
}
```

### Querying Registered Tiles

Fetch the current native state of all tiles:

```dart
final List<TileSnapshot> tiles = await FlutterTileService.getTiles();
for (final tile in tiles) {
  print('Tile: ${tile.id} (Slot #${tile.slot}) => State: ${tile.state.name}');
}
```

---

## Handling the Flutter Background / App Killed Lifecycle

Android's Quick Settings `TileService` is a system service that can be invoked at any time by the OS, even when your Flutter app is not running.

### How `flutter_tile_service` Handles This:
1. **Zero Dart Dependency For Core Tile Actions**: When a user clicks a tile, `TileServiceBase` instantly updates the native state in `TileStorage` and refreshes `qsTile`.
2. **Auto-Toggle**: When `autoToggleState: true`, the tile switches between `active` and `inactive` natively without requiring an active Flutter engine.
3. **Automatic Resynchronization**: When your Flutter app launches or enters the foreground, it queries `FlutterTileService.getTiles()` to synchronize with the latest native state.
4. **Live Event Dispatch**: If Flutter is running (foreground or background), events are dispatched across the `events` stream in real time.

---

## Custom Tile Icons

To use a custom native drawable icon:
1. Place your vector drawable XML or PNG in your Android project's `android/app/src/main/res/drawable/` folder (e.g. `ic_punch_clock.xml`).
2. Specify the resource name without file extension in `TileConfig`:

```dart
TileConfig(
  id: 'attendance',
  label: 'Attendance',
  iconResourceName: 'ic_punch_clock',
)
```

If not specified or not found, the plugin defaults to a clean, universal checkmark vector icon (`ic_tile_default`).

---

## Multiple Tile Slots

Android requires all `TileService` classes to be declared in `AndroidManifest.xml`. To give you maximum flexibility out of the box without manual XML editing, `flutter_tile_service` pre-declares **4 service slots** (`TileService0` through `TileService3`).

You can register up to 4 distinct tiles simultaneously using logical IDs (`'attendance'`, `'vpn'`, `'meeting_mode'`, etc.). The plugin maps each ID to an available slot automatically.

---

## API Reference

### `FlutterTileService`
- `static Future<bool> isSupported()`
- `static Future<void> initialize()`
- `static Future<TileSnapshot> registerTile(TileConfig config)`
- `static Future<bool> unregisterTile(String tileId)`
- `static Future<TileSnapshot> updateTile({required String id, TileState? state, String? label, String? description, String? iconResourceName})`
- `static Future<TileSnapshot?> getTile(String tileId)`
- `static Future<List<TileSnapshot>> getTiles()`
- `static Future<TileAddResult> requestAddTile(String tileId)`
- `static Stream<TileEvent> get events`

### `TileEvent` Subclasses
- `TileClickedEvent` (`tileId`, `slot`, `state`, `isLocked`, `timestamp`)
- `TileAddedEvent` (`tileId`, `slot`, `timestamp`)
- `TileRemovedEvent` (`tileId`, `slot`, `timestamp`)
- `TileListeningStartedEvent` (`tileId`, `slot`, `timestamp`)
- `TileListeningStoppedEvent` (`tileId`, `slot`, `timestamp`)

---

## Manual Verification Checklist

1. **Install App**: Run `flutter run` on an Android device (API 24+).
2. **Register Tile**: Open app and verify `attendance` is registered.
3. **Add to QS**: Pull down Android Quick Settings panel, tap edit pencil (or tap "Add to Quick Settings" in app on Android 13+), and drag the tile into your active grid.
4. **Tap Tile (App Open)**: Tap the tile in QS shade; verify that the tile turns active ("IN") and the app's live event log reflects the click event.
5. **Kill App**: Swipe away / force close the Flutter app.
6. **Tap Tile (App Killed)**: Tap the QS tile again; verify that it smoothly toggles to inactive ("OUT") in native UI without crashing.
7. **Reopen App**: Launch the Flutter app and verify that the dashboard immediately reflects the updated "OUT" state.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
