import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tile_service/flutter_tile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TileDemoApp());
}

/// Demonstration presets to easily showcase diverse Quick Settings use cases in demo videos.
class TilePreset {
  final String id;
  final String label;
  final String activeLabel;
  final String inactiveLabel;
  final String description;
  final IconData icon;

  const TilePreset({
    required this.id,
    required this.label,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.description,
    required this.icon,
  });
}

final List<TilePreset> demoPresets = [
  const TilePreset(
    id: 'focus_mode',
    label: 'Focus Mode',
    activeLabel: 'Focus ON',
    inactiveLabel: 'Focus OFF',
    description: 'Do Not Disturb Active',
    icon: Icons.do_not_disturb_on_outlined,
  ),
  const TilePreset(
    id: 'vpn_shield',
    label: 'VPN Shield',
    activeLabel: 'Secured',
    inactiveLabel: 'Unsecured',
    description: 'Ultra Fast Gateway',
    icon: Icons.shield_outlined,
  ),
  const TilePreset(
    id: 'mic_mute',
    label: 'Microphone',
    activeLabel: 'Muted',
    inactiveLabel: 'Live',
    description: 'System Audio Control',
    icon: Icons.mic_off_outlined,
  ),
  const TilePreset(
    id: 'quick_counter',
    label: 'Quick Counter',
    activeLabel: 'Active',
    inactiveLabel: 'Idle',
    description: 'Taps recorded: 0',
    icon: Icons.timer_outlined,
  ),
];

class TileDemoApp extends StatelessWidget {
  const TileDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Settings Tile Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TileControlDashboard(),
    );
  }
}

class TileControlDashboard extends StatefulWidget {
  const TileControlDashboard({super.key});

  @override
  State<TileControlDashboard> createState() => _TileControlDashboardState();
}

class _TileControlDashboardState extends State<TileControlDashboard> {
  bool _isSupported = false;
  bool _isLoading = true;
  List<TileSnapshot> _registeredTiles = [];
  final List<String> _eventLogs = [];
  StreamSubscription<TileEvent>? _eventSubscription;

  // Selected active demo preset for quick presentation
  TilePreset _activePreset = demoPresets[0];
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _initPlugin();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initPlugin() async {
    setState(() => _isLoading = true);
    try {
      final supported = await FlutterTileService.isSupported();
      _isSupported = supported;

      if (supported) {
        await FlutterTileService.initialize();

        // Listen to native Quick Settings Tile events
        _eventSubscription = FlutterTileService.events.listen((event) {
          _onTileEventReceived(event);
        });

        // Ensure initial primary demo tile is registered
        await _applyPreset(_activePreset, notify: false);

        // Refresh snapshot list
        await _refreshTiles();
      }
    } catch (e) {
      _log('Init Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyPreset(TilePreset preset, {bool notify = true}) async {
    setState(() {
      _activePreset = preset;
    });

    try {
      await FlutterTileService.registerTile(
        TileConfig(
          id: preset.id,
          label: preset.label,
          activeLabel: preset.activeLabel,
          inactiveLabel: preset.inactiveLabel,
          description: preset.description,
          initialState: TileState.inactive,
          autoToggleState: true,
        ),
      );
      if (notify) {
        _log('Switched to preset: "${preset.label}" (ID: ${preset.id})');
      }
      await _refreshTiles();
    } catch (e) {
      _log('Failed to apply preset: $e');
    }
  }

  Future<void> _refreshTiles() async {
    try {
      final tiles = await FlutterTileService.getTiles();
      setState(() {
        _registeredTiles = tiles;
      });
    } catch (e) {
      _log('Error fetching tiles: $e');
    }
  }

  void _onTileEventReceived(TileEvent event) {
    final timeStr = DateTime.fromMillisecondsSinceEpoch(event.timestamp)
        .toLocal()
        .toIso8601String()
        .split('T')
        .last
        .substring(0, 8);

    if (event is TileClickedEvent) {
      _log(
          '[$timeStr] 🖱️ CLICKED: "${event.tileId}" (state: ${event.state.name}, locked: ${event.isLocked})');

      if (event.tileId == 'quick_counter') {
        _counter++;
        FlutterTileService.updateTile(
          id: 'quick_counter',
          description: 'Taps recorded: $_counter',
        );
      }
    } else if (event is TileAddedEvent) {
      _log('[$timeStr] ➕ ADDED TO QS: "${event.tileId}" (Slot #${event.slot})');
    } else if (event is TileRemovedEvent) {
      _log(
          '[$timeStr] ➖ REMOVED FROM QS: "${event.tileId}" (Slot #${event.slot})');
    } else if (event is TileListeningStartedEvent) {
      _log('[$timeStr] 👁️ LISTENING START: "${event.tileId}"');
    } else if (event is TileListeningStoppedEvent) {
      _log('[$timeStr] 🛑 LISTENING STOP: "${event.tileId}"');
    }

    _refreshTiles();
  }

  void _log(String message) {
    setState(() {
      _eventLogs.insert(0, message);
      if (_eventLogs.length > 60) {
        _eventLogs.removeLast();
      }
    });
  }

  TileSnapshot? get _primaryTile {
    return _registeredTiles.where((t) => t.id == _activePreset.id).firstOrNull;
  }

  Future<void> _togglePrimaryTile() async {
    final tile = _primaryTile;
    final isCurrentlyActive = tile?.state == TileState.active;
    final nextState = isCurrentlyActive ? TileState.inactive : TileState.active;
    final nextLabel = nextState == TileState.active
        ? _activePreset.activeLabel
        : _activePreset.inactiveLabel;

    try {
      await FlutterTileService.updateTile(
        id: _activePreset.id,
        state: nextState,
        label: nextLabel,
      );
      _log(
          'Toggled "${_activePreset.label}" to ${nextState.name.toUpperCase()}');
      await _refreshTiles();
    } catch (e) {
      _log('Error toggling tile: $e');
    }
  }

  Future<void> _cycleTileState(String tileId, TileState current) async {
    TileState next;
    switch (current) {
      case TileState.inactive:
        next = TileState.active;
        break;
      case TileState.active:
        next = TileState.unavailable;
        break;
      case TileState.unavailable:
        next = TileState.inactive;
        break;
    }

    try {
      await FlutterTileService.updateTile(
        id: tileId,
        state: next,
      );
      _log('Updated "$tileId" state -> ${next.name.toUpperCase()}');
      await _refreshTiles();
    } catch (e) {
      _log('Error cycling state: $e');
    }
  }

  Future<void> _requestAddToSystem(String tileId) async {
    _log('Requesting Android system prompt for: $tileId...');
    try {
      final result = await FlutterTileService.requestAddTile(tileId);
      _log('System prompt response: ${result.name}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Add Tile Prompt Result: ${result.name}'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _log('Add request error: $e');
    }
  }

  Future<void> _addNewCustomTile() async {
    final slotIndex = _registeredTiles.length + 1;
    final id = 'custom_tile_$slotIndex';
    final label = 'Quick Slot $slotIndex';

    try {
      await FlutterTileService.registerTile(
        TileConfig(
          id: id,
          label: label,
          activeLabel: 'Active',
          inactiveLabel: 'Standby',
          description: 'Custom registered slot',
          initialState: TileState.inactive,
          autoToggleState: true,
        ),
      );
      _log('Registered new slot: "$id"');
      await _refreshTiles();
    } catch (e) {
      _log('Registration failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _unregisterTile(String id) async {
    try {
      await FlutterTileService.unregisterTile(id);
      _log('Unregistered tile "$id"');
      await _refreshTiles();
    } catch (e) {
      _log('Failed to unregister "$id": $e');
    }
  }

  void _showEditTileDialog(TileSnapshot tile) {
    final labelController = TextEditingController(text: tile.currentLabel);
    final descController =
        TextEditingController(text: tile.currentDescription ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Tile "${tile.id}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Display Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Subtitle / Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FlutterTileService.updateTile(
                id: tile.id,
                label: labelController.text.trim(),
                description: descController.text.trim(),
              );
              _log('Updated metadata for "${tile.id}"');
              await _refreshTiles();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing Quick Settings Service...'),
            ],
          ),
        ),
      );
    }

    if (!_isSupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quick Settings Showcase')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'Quick Settings Not Supported',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quick Settings Tiles require Android 7.0 (API 24) or higher.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 22),
            SizedBox(width: 8),
            Text('Quick Settings Tile Demo'),
          ],
        ),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Native Tile State',
            onPressed: _refreshTiles,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTiles,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // 1. Preset Switcher for Demo Showcase
            _buildPresetSelector(theme),
            const SizedBox(height: 12),

            // 2. Interactive Android QS Tile Visual Simulator & Controller
            _buildInteractiveSimulatorCard(theme),
            const SizedBox(height: 16),

            // 3. Registered Native Slots Section
            _buildRegisteredSlotsSection(theme),
            const SizedBox(height: 16),

            // 4. Real-time Live Event Log
            _buildLiveEventLogSection(theme),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registeredTiles.length >= 4 ? null : _addNewCustomTile,
        icon: const Icon(Icons.add_to_home_screen),
        label: Text(
          _registeredTiles.length >= 4 ? 'Max Slots Reached' : 'Add Tile Slot',
        ),
      ),
    );
  }

  /// Preset selector chips to easily switch use-cases on camera during a demo.
  Widget _buildPresetSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'DEMO PRESETS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: demoPresets.map((preset) {
              final isSelected = _activePreset.id == preset.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  avatar: Icon(
                    preset.icon,
                    size: 18,
                    color: isSelected ? theme.colorScheme.onPrimary : null,
                  ),
                  label: Text(preset.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _applyPreset(preset);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Interactive Card containing a simulated native Android Quick Settings pill tile
  /// along with one-tap demo triggers.
  Widget _buildInteractiveSimulatorCard(ThemeData theme) {
    final tile = _primaryTile;
    final currentState = tile?.state ?? TileState.inactive;
    final isActive = currentState == TileState.active;
    final isUnavailable = currentState == TileState.unavailable;

    // Simulated Quick Settings visual style
    Color tileBgColor;
    Color tileFgColor;
    if (isActive) {
      tileBgColor = theme.colorScheme.primary;
      tileFgColor = theme.colorScheme.onPrimary;
    } else if (isUnavailable) {
      tileBgColor = theme.colorScheme.surfaceContainerHighest.withAlpha(120);
      tileFgColor = theme.colorScheme.outline;
    } else {
      tileBgColor = theme.colorScheme.surfaceContainerHighest;
      tileFgColor = theme.colorScheme.onSurface;
    }

    final displayLabel = tile?.currentLabel ?? _activePreset.label;
    final displayDesc = tile?.currentDescription ?? _activePreset.description;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Tile Simulator',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Live sync with Android Quick Settings shade',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withAlpha(40)
                        : (isUnavailable
                            ? Colors.grey.withAlpha(40)
                            : Colors.blueGrey.withAlpha(40)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentState.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.green
                          : (isUnavailable ? Colors.grey : Colors.blueGrey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Android QS Tile Visual Pill
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 340),
                decoration: BoxDecoration(
                  color: tileBgColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withAlpha(80),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _togglePrimaryTile,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18.0, vertical: 14.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withAlpha(50)
                                  : theme.colorScheme.surface.withAlpha(150),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _activePreset.icon,
                              color: tileFgColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayLabel,
                                  style: TextStyle(
                                    color: tileFgColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  displayDesc,
                                  style: TextStyle(
                                    color: tileFgColor.withAlpha(200),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.touch_app_rounded,
                            color: tileFgColor.withAlpha(160),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Demo Control Action Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip.elevated(
                  avatar: const Icon(Icons.sync_alt, size: 16),
                  label: const Text('Toggle State'),
                  onPressed: _togglePrimaryTile,
                ),
                ActionChip.elevated(
                  avatar: const Icon(Icons.change_circle_outlined, size: 16),
                  label: const Text('Cycle State (Active/Inactive/Off)'),
                  onPressed: () =>
                      _cycleTileState(_activePreset.id, currentState),
                ),
                ActionChip.elevated(
                  avatar:
                      const Icon(Icons.add_to_home_screen_outlined, size: 16),
                  label: const Text('Add to System QS (Android 13+)'),
                  onPressed: () => _requestAddToSystem(_activePreset.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Registered native slots overview
  Widget _buildRegisteredSlotsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Registered Native Slots (${_registeredTiles.length}/4)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Persisted Natively',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_registeredTiles.isEmpty)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child:
                    Text('No tiles registered. Tap "+ Add Tile Slot" below.'),
              ),
            ),
          )
        else
          ..._registeredTiles.map((tile) => _buildSlotCard(tile, theme)),
      ],
    );
  }

  Widget _buildSlotCard(TileSnapshot tile, ThemeData theme) {
    final isActive = tile.state == TileState.active;
    final isUnavailable = tile.state == TileState.unavailable;

    Color badgeColor;
    if (isActive) {
      badgeColor = Colors.green;
    } else if (isUnavailable) {
      badgeColor = Colors.grey;
    } else {
      badgeColor = Colors.blueGrey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor.withAlpha(40),
          child: Text(
            '#${tile.slot}',
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                tile.currentLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tile.state.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'ID: ${tile.id} • Slot: Service${tile.slot}\n'
            'Subtitle: ${tile.currentDescription ?? "None"}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit Tile Metadata',
              onPressed: () => _showEditTileDialog(tile),
            ),
            IconButton(
              icon: const Icon(Icons.sync_alt, size: 20),
              tooltip: 'Toggle state',
              onPressed: () => _cycleTileState(tile.id, tile.state),
            ),
            if (tile.id != _activePreset.id)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.redAccent),
                tooltip: 'Unregister tile slot',
                onPressed: () => _unregisterTile(tile.id),
              ),
          ],
        ),
      ),
    );
  }

  /// Real-time live event log section with clear, colored logs
  Widget _buildLiveEventLogSection(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.sensors,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Live Event Feed',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _eventLogs.clear()),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const Divider(height: 16),
            if (_eventLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'No events yet. Pull down Android notification shade or tap simulator above.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _eventLogs.length,
                  itemBuilder: (context, index) {
                    final log = _eventLogs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        log,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
