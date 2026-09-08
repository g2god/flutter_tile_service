import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tile_service/flutter_tile_service.dart';

void main() {
  group('TileEvent parsing', () {
    test('parses TileClickedEvent', () {
      final map = {
        'eventType': 'onClick',
        'tileId': 'attendance',
        'slot': 0,
        'state': 'active',
        'isLocked': false,
        'timestamp': 1700000000,
      };

      final event = TileEvent.fromMap(map);
      expect(event, isA<TileClickedEvent>());
      final clickEvent = event as TileClickedEvent;
      expect(clickEvent.tileId, 'attendance');
      expect(clickEvent.slot, 0);
      expect(clickEvent.state, TileState.active);
      expect(clickEvent.isLocked, isFalse);
      expect(clickEvent.timestamp, 1700000000);
    });

    test('parses TileAddedEvent', () {
      final map = {
        'eventType': 'onTileAdded',
        'tileId': 'attendance',
        'slot': 1,
        'timestamp': 1700000001,
      };

      final event = TileEvent.fromMap(map);
      expect(event, isA<TileAddedEvent>());
      expect(event.tileId, 'attendance');
      expect(event.slot, 1);
    });

    test('parses TileRemovedEvent', () {
      final map = {
        'eventType': 'onTileRemoved',
        'tileId': 'attendance',
        'slot': 1,
        'timestamp': 1700000002,
      };

      final event = TileEvent.fromMap(map);
      expect(event, isA<TileRemovedEvent>());
      expect(event.tileId, 'attendance');
    });

    test('parses TileListeningStartedEvent', () {
      final map = {
        'eventType': 'onStartListening',
        'tileId': 'attendance',
        'slot': 0,
        'timestamp': 1700000003,
      };

      final event = TileEvent.fromMap(map);
      expect(event, isA<TileListeningStartedEvent>());
    });

    test('parses TileListeningStoppedEvent', () {
      final map = {
        'eventType': 'onStopListening',
        'tileId': 'attendance',
        'slot': 0,
        'timestamp': 1700000004,
      };

      final event = TileEvent.fromMap(map);
      expect(event, isA<TileListeningStoppedEvent>());
    });
  });
}
