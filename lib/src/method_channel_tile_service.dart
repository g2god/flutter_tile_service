import 'dart:async';
import 'package:flutter/services.dart';
import 'tile.dart';
import 'tile_add_result.dart';
import 'tile_config.dart';
import 'tile_event.dart';
import 'tile_state.dart';

/// Typed exception thrown when a Quick Settings Tile platform operation fails.
class TileServiceException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const TileServiceException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() =>
      'TileServiceException($code): $message ${details != null ? "($details)" : ""}';
}

/// Low-level platform channel interface for `flutter_tile_service`.
class MethodChannelTileService {
  static const String channelName = 'com.example.flutter_tile_service/methods';
  static const String eventChannelName =
      'com.example.flutter_tile_service/events';

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<TileEvent>? _eventsStream;

  MethodChannelTileService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ?? const MethodChannel(channelName),
        _eventChannel = eventChannel ?? const EventChannel(eventChannelName);

  /// Checks if Quick Settings Tiles are supported on the current Android system (API 24+).
  Future<bool> isSupported() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on PlatformException catch (e) {
      throw TileServiceException(
        code: e.code,
        message: e.message ?? 'Failed to check platform support',
        details: e.details,
      );
    }
  }

  /// Initializes the native plugin and returns initial status.
  Future<void> initialize() async {
    try {
      await _methodChannel.invokeMethod<void>('initialize');
    } on PlatformException catch (e) {
      throw TileServiceException(
        code: e.code,
        message: e.message ?? 'Failed to initialize TileService plugin',
        details: e.details,
      );
    }
  }

  /// Registers a tile configuration and allocates a native service slot.
  Future<TileSnapshot> registerTile(TileConfig config) async {
    try {
      final result = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
        'registerTile',
        config.toMap(),
      );
      if (result == null) {
        throw const TileServiceException(
          code: 'NATIVE_ERROR',
          message: 'Native side returned null when registering tile',
        );
      }
      return TileSnapshot.fromMap(result);
    } on PlatformException catch (e) {
      throw TileServiceException(
        code: e.code,
        message: e.message ?? 'Failed to register tile ${config.id}',
        details: e.details,
      );
    }
  }

  /// Unregisters a tile by its logical ID.
  Future<bool> unregisterTile(String tileId) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'unregisterTile',
        {'id': tileId},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw TileServiceException(
        code: e.code,
        message: e.message ?? 'Failed to unregister tile $tileId',
        details: e.details,
      );
    }
  }

  /// Updates the native tile state, label, subtitle, or other attributes.
  Future<TileSnapshot> updateTile({
    required String id,
    TileState? state,
    String? label,
    String? description,
    String? iconResourceName,
  }) async {
    try {
      final params = <String, dynamic>{
        'id': id,
        if (state != null) 'state': state.toValue(),
        if (label != null) 'label': label,
        if (description != null) 'description': description,
        if (iconResourceName != null) 'iconResourceName': iconResourceName,
      };

      final result = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
        'updateTile',
        params,
      );
      if (result == null) {
        throw TileServiceException(
          code: 'TILE_NOT_FOUND',
          message: 'No registered tile with id: $id',
        );
      }
      return TileSnapshot.fromMap(result);
    } on PlatformException catch (e) {
      throw TileServiceException(
        code: e.code,
        message: e.message ?? 'Failed to update tile $id',
        details: e.details,
      );
    }
  }

  /// Retrieves the current snapshot for a single tile.
  Future<TileSnapshot?> getTile(String tileId) async {
    try {
      final result = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
        'getTile',
        {'id': tileId},
      );
      if (result == null) return null;
      return TileSnapshot.fromMap(result);
    } on PlatformException catch (e) {
      throw TileServiceException(
        code: e.code,
        message: e.message ?? 'Failed to fetch tile $tileId',
        details: e.details,
      );
    }
  }

  /// Retrieves all currently registered tiles from native storage.
  Future<List<TileSnapshot>> getTiles() async {
    try {
      final result = await _methodChannel.invokeListMethod<dynamic>('getTiles');
      if (result == null) return [];
      return result
          .whereType<Map<dynamic, dynamic>>()
          .map((map) => TileSnapshot.fromMap(map))
          .toList();
    } on PlatformException catch (e) {
      throw TileServiceException(
        code: e.code,
        message: e.message ?? 'Failed to fetch tiles',
        details: e.details,
      );
    }
  }

  /// Requests the Android system to add the specified tile to Quick Settings (Android 13+).
  Future<TileAddResult> requestAddTile(String tileId) async {
    try {
      final result = await _methodChannel.invokeMethod<dynamic>(
        'requestAddTile',
        {'id': tileId},
      );
      return TileAddResult.fromPlatform(result);
    } on PlatformException catch (e) {
      throw TileServiceException(
        code: e.code,
        message: e.message ?? 'Failed to request adding tile $tileId',
        details: e.details,
      );
    }
  }

  /// Stream of all native tile events (clicks, added, removed, listening).
  Stream<TileEvent> get events {
    _eventsStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((data) => data is Map)
        .map((data) => TileEvent.fromMap(data as Map<dynamic, dynamic>));
    return _eventsStream!;
  }
}
