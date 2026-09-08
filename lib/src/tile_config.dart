import 'tile_state.dart';

/// Configuration for registering or updating an Android Quick Settings Tile.
class TileConfig {
  /// Unique identifier for this tile in your Flutter app (e.g. 'attendance', 'vpn_toggle').
  final String id;

  /// The default or primary label displayed on the tile.
  final String label;

  /// Optional label displayed when the tile is in [TileState.active] state.
  /// If null, [label] will be used.
  final String? activeLabel;

  /// Optional label displayed when the tile is in [TileState.inactive] state.
  /// If null, [label] will be used.
  final String? inactiveLabel;

  /// Optional secondary label or subtitle (supported on Android 10+ / API 29+).
  final String? description;

  /// Initial state when the tile is registered. Defaults to [TileState.inactive].
  final TileState initialState;

  /// Name of the Android drawable resource to use as the icon (e.g., 'ic_tile_attendance').
  ///
  /// If null, the plugin's default tile icon is used.
  final String? iconResourceName;

  /// Whether tapping the tile should auto-toggle native state between
  /// [TileState.active] and [TileState.inactive] even if Flutter is dead.
  ///
  /// Defaults to `true`.
  final bool autoToggleState;

  /// Optional custom metadata attached to the tile.
  final Map<String, dynamic>? metadata;

  const TileConfig({
    required this.id,
    required this.label,
    this.activeLabel,
    this.inactiveLabel,
    this.description,
    this.initialState = TileState.inactive,
    this.iconResourceName,
    this.autoToggleState = true,
    this.metadata,
  })  : assert(id.length > 0, 'Tile ID cannot be empty'),
        assert(label.length > 0, 'Tile label cannot be empty');

  /// Creates a [TileConfig] from a serialized map.
  factory TileConfig.fromMap(Map<dynamic, dynamic> map) {
    return TileConfig(
      id: map['id'] as String,
      label: map['label'] as String,
      activeLabel: map['activeLabel'] as String?,
      inactiveLabel: map['inactiveLabel'] as String?,
      description: map['description'] as String?,
      initialState: TileState.fromString(map['initialState'] as String?),
      iconResourceName: map['iconResourceName'] as String?,
      autoToggleState: map['autoToggleState'] as bool? ?? true,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  /// Converts this [TileConfig] to a map for platform channel serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'activeLabel': activeLabel,
      'inactiveLabel': inactiveLabel,
      'description': description,
      'initialState': initialState.toValue(),
      'iconResourceName': iconResourceName,
      'autoToggleState': autoToggleState,
      'metadata': metadata,
    };
  }

  /// Creates a copy of this [TileConfig] with given fields replaced.
  TileConfig copyWith({
    String? id,
    String? label,
    String? activeLabel,
    String? inactiveLabel,
    String? description,
    TileState? initialState,
    String? iconResourceName,
    bool? autoToggleState,
    Map<String, dynamic>? metadata,
  }) {
    return TileConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      activeLabel: activeLabel ?? this.activeLabel,
      inactiveLabel: inactiveLabel ?? this.inactiveLabel,
      description: description ?? this.description,
      initialState: initialState ?? this.initialState,
      iconResourceName: iconResourceName ?? this.iconResourceName,
      autoToggleState: autoToggleState ?? this.autoToggleState,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          activeLabel == other.activeLabel &&
          inactiveLabel == other.inactiveLabel &&
          description == other.description &&
          initialState == other.initialState &&
          iconResourceName == other.iconResourceName &&
          autoToggleState == other.autoToggleState;

  @override
  int get hashCode =>
      id.hashCode ^
      label.hashCode ^
      activeLabel.hashCode ^
      inactiveLabel.hashCode ^
      description.hashCode ^
      initialState.hashCode ^
      iconResourceName.hashCode ^
      autoToggleState.hashCode;

  @override
  String toString() {
    return 'TileConfig(id: $id, label: $label, state: $initialState, description: $description)';
  }
}
