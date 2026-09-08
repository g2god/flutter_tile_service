import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tile_service/flutter_tile_service.dart';

void main() {
  group('TileState', () {
    test('fromString parses correctly', () {
      expect(TileState.fromString('active'), TileState.active);
      expect(TileState.fromString('ACTIVE'), TileState.active);
      expect(TileState.fromString('inactive'), TileState.inactive);
      expect(TileState.fromString('INACTIVE'), TileState.inactive);
      expect(TileState.fromString('unavailable'), TileState.unavailable);
      expect(TileState.fromString('UNAVAILABLE'), TileState.unavailable);
      expect(TileState.fromString('unknown'), TileState.inactive);
      expect(TileState.fromString(null), TileState.inactive);
    });

    test('toValue returns correct string representation', () {
      expect(TileState.active.toValue(), 'active');
      expect(TileState.inactive.toValue(), 'inactive');
      expect(TileState.unavailable.toValue(), 'unavailable');
    });
  });

  group('TileAddResult', () {
    test('fromPlatform parses int and string values correctly', () {
      expect(TileAddResult.fromPlatform(2), TileAddResult.added);
      expect(TileAddResult.fromPlatform(1), TileAddResult.alreadyAdded);
      expect(TileAddResult.fromPlatform(0), TileAddResult.denied);

      expect(TileAddResult.fromPlatform('added'), TileAddResult.added);
      expect(TileAddResult.fromPlatform('alreadyAdded'),
          TileAddResult.alreadyAdded);
      expect(TileAddResult.fromPlatform('already_added'),
          TileAddResult.alreadyAdded);
      expect(
          TileAddResult.fromPlatform('unavailable'), TileAddResult.unavailable);
      expect(TileAddResult.fromPlatform('denied'), TileAddResult.denied);
      expect(TileAddResult.fromPlatform('requested'), TileAddResult.requested);
    });
  });
}
