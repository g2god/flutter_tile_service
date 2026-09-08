import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tile_service/flutter_tile_service.dart';

void main() {
  group('TileConfig', () {
    test('instantiates with valid parameters and defaults', () {
      const config = TileConfig(
        id: 'attendance',
        label: 'Attendance',
      );

      expect(config.id, 'attendance');
      expect(config.label, 'Attendance');
      expect(config.initialState, TileState.inactive);
      expect(config.autoToggleState, isTrue);
      expect(config.description, isNull);
    });

    test('serializes and deserializes properly', () {
      const original = TileConfig(
        id: 'vpn_toggle',
        label: 'VPN',
        activeLabel: 'VPN ON',
        inactiveLabel: 'VPN OFF',
        description: 'Office Gateway',
        initialState: TileState.active,
        iconResourceName: 'ic_vpn',
        autoToggleState: false,
        metadata: {'server': 'us-east'},
      );

      final map = original.toMap();
      final deserialized = TileConfig.fromMap(map);

      expect(deserialized.id, original.id);
      expect(deserialized.label, original.label);
      expect(deserialized.activeLabel, original.activeLabel);
      expect(deserialized.inactiveLabel, original.inactiveLabel);
      expect(deserialized.description, original.description);
      expect(deserialized.initialState, original.initialState);
      expect(deserialized.iconResourceName, original.iconResourceName);
      expect(deserialized.autoToggleState, original.autoToggleState);
      expect(deserialized.metadata?['server'], 'us-east');
      expect(deserialized, equals(original));
    });

    test('throws assertion error for empty ID or label', () {
      expect(
        () => TileConfig(id: '', label: 'Test'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => TileConfig(id: 'test', label: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith works correctly', () {
      const original = TileConfig(id: 'test', label: 'Initial');
      final updated = original.copyWith(
        label: 'Updated',
        initialState: TileState.active,
      );

      expect(updated.id, 'test');
      expect(updated.label, 'Updated');
      expect(updated.initialState, TileState.active);
    });
  });
}
