import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tile_service/flutter_tile_service.dart';
import 'package:flutter_tile_service/src/method_channel_tile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterTileService and MethodChannelTileService', () {
    const MethodChannel methodChannel =
        MethodChannel(MethodChannelTileService.channelName);
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel,
              (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'isSupported':
            return true;
          case 'initialize':
            return true;
          case 'registerTile':
            final args = methodCall.arguments as Map;
            return {
              'id': args['id'],
              'slot': 0,
              'label': args['label'],
              'state': args['initialState'] ?? 'inactive',
              'currentLabel': args['label'],
              'currentDescription': args['description'],
              'lastUpdatedMillis': 1700000000,
            };
          case 'unregisterTile':
            return true;
          case 'updateTile':
            final args = methodCall.arguments as Map;
            return {
              'id': args['id'],
              'slot': 0,
              'label': args['label'] ?? 'Attendance',
              'state': args['state'] ?? 'active',
              'currentLabel': args['label'] ?? 'Attendance',
              'currentDescription': args['description'],
              'lastUpdatedMillis': 1700000010,
            };
          case 'getTile':
            final args = methodCall.arguments as Map;
            return {
              'id': args['id'],
              'slot': 0,
              'label': 'Attendance',
              'state': 'active',
              'currentLabel': 'Attendance',
              'currentDescription': 'Checked In',
              'lastUpdatedMillis': 1700000000,
            };
          case 'getTiles':
            return [
              {
                'id': 'attendance',
                'slot': 0,
                'label': 'Attendance',
                'state': 'active',
                'currentLabel': 'Attendance',
                'lastUpdatedMillis': 1700000000,
              }
            ];
          case 'requestAddTile':
            return 'added';
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('isSupported calls native channel', () async {
      final supported = await FlutterTileService.isSupported();
      expect(supported, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, 'isSupported');
    });

    test('initialize calls native channel', () async {
      await FlutterTileService.initialize();
      expect(log, hasLength(1));
      expect(log.first.method, 'initialize');
    });

    test('registerTile sends correct payload and parses snapshot', () async {
      const config = TileConfig(
        id: 'attendance',
        label: 'Attendance',
        activeLabel: 'IN',
        inactiveLabel: 'OUT',
        description: 'Tap to mark',
      );

      final snapshot = await FlutterTileService.registerTile(config);
      expect(snapshot.id, 'attendance');
      expect(snapshot.slot, 0);
      expect(snapshot.currentLabel, 'Attendance');

      expect(log, hasLength(1));
      expect(log.first.method, 'registerTile');
      expect(log.first.arguments['id'], 'attendance');
    });

    test('unregisterTile calls native', () async {
      final res = await FlutterTileService.unregisterTile('attendance');
      expect(res, isTrue);
      expect(log.first.method, 'unregisterTile');
      expect(log.first.arguments['id'], 'attendance');
    });

    test('updateTile updates state and returns updated snapshot', () async {
      final snapshot = await FlutterTileService.updateTile(
        id: 'attendance',
        state: TileState.active,
        label: 'IN',
      );

      expect(snapshot.id, 'attendance');
      expect(snapshot.state, TileState.active);
      expect(snapshot.currentLabel, 'IN');
    });

    test('getTile fetches snapshot', () async {
      final snapshot = await FlutterTileService.getTile('attendance');
      expect(snapshot, isNotNull);
      expect(snapshot!.id, 'attendance');
      expect(snapshot.state, TileState.active);
    });

    test('getTiles fetches list of snapshots', () async {
      final tiles = await FlutterTileService.getTiles();
      expect(tiles, hasLength(1));
      expect(tiles.first.id, 'attendance');
    });

    test('requestAddTile parses result', () async {
      final result = await FlutterTileService.requestAddTile('attendance');
      expect(result, TileAddResult.added);
    });
  });
}
