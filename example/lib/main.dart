import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tile_service/flutter_tile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TileDemoApp());
}

class TileDemoApp extends StatelessWidget {
  const TileDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Settings Tile Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
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

  // Track Attendance Demo State
  bool _isClockedIn = false;

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

        // Automatically register the Attendance reference tile if not present
        await _ensureAttendanceTileRegistered();

        // Refresh snapshot list
        await _refreshTiles();
      }
    } catch (e) {
      _log('Init Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _ensureAttendanceTileRegistered() async {
    final existing = await FlutterTileService.getTile('attendance');
    if (existing == null) {
      await FlutterTileService.registerTile(
        const TileConfig(
          id: 'attendance',
          label: 'Attendance',
          activeLabel: 'IN',
          inactiveLabel: 'OUT',
          description: 'Tap to punch attendance',
          initialState: TileState.inactive,
          autoToggleState: true,
        ),
      );
      _log('Registered default "attendance" tile.');
    } else {
      setState(() {
        _isClockedIn = existing.state == TileState.active;
      });
    }
  }

  Future<void> _refreshTiles() async {
    final tiles = await FlutterTileService.getTiles();
    setState(() {
      _registeredTiles = tiles;
      final attendance = tiles.where((t) => t.id == 'attendance').firstOrNull;
      if (attendance != null) {
        _isClockedIn = attendance.state == TileState.active;
      }
    });
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
          '[$timeStr] CLICKED: tileId="${event.tileId}" state=${event.state.name} isLocked=${event.isLocked}');
      if (event.tileId == 'attendance') {
        setState(() {
          _isClockedIn = event.state == TileState.active;
        });
        // Execute business logic (e.g. record punch timestamp)
        _handleAttendanceBusinessLogic(_isClockedIn);
      }
    } else if (event is TileAddedEvent) {
      _log(
          '[$timeStr] ADDED TO QS: tileId="${event.tileId}" slot=${event.slot}');
    } else if (event is TileRemovedEvent) {
      _log(
          '[$timeStr] REMOVED FROM QS: tileId="${event.tileId}" slot=${event.slot}');
    } else if (event is TileListeningStartedEvent) {
      _log(
          '[$timeStr] LISTENING START: tileId="${event.tileId}" slot=${event.slot}');
    } else if (event is TileListeningStoppedEvent) {
      _log(
          '[$timeStr] LISTENING STOP: tileId="${event.tileId}" slot=${event.slot}');
    }

    _refreshTiles();
  }

  void _handleAttendanceBusinessLogic(bool isClockedIn) {
    final status = isClockedIn ? 'CLOCKED IN' : 'CLOCKED OUT';
    _log('⚡ [App Logic] Attendance status updated: $status');
  }

  void _log(String message) {
    setState(() {
      _eventLogs.insert(0, message);
      if (_eventLogs.length > 50) {
        _eventLogs.removeLast();
      }
    });
  }

  Future<void> _toggleAttendanceFromApp() async {
    final nextState = _isClockedIn ? TileState.inactive : TileState.active;
    final nextLabel = nextState == TileState.active ? 'IN' : 'OUT';
    final nextDesc =
        nextState == TileState.active ? 'Clocked In' : 'Clocked Out';

    try {
      await FlutterTileService.updateTile(
        id: 'attendance',
        state: nextState,
        label: nextLabel,
        description: nextDesc,
      );
      setState(() {
        _isClockedIn = nextState == TileState.active;
      });
      _log('App toggled attendance tile to: ${nextState.name}');
      await _refreshTiles();
    } catch (e) {
      _log('Failed to update attendance tile: $e');
    }
  }

  Future<void> _requestAddTileToSystem(String tileId) async {
    _log('Requesting system to add tile: $tileId...');
    try {
      final result = await FlutterTileService.requestAddTile(tileId);
      _log('System response for $tileId: ${result.name}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quick Settings add request result: ${result.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _log('Error requesting tile addition: $e');
    }
  }

  Future<void> _registerNewCustomTile() async {
    final slotIndex = _registeredTiles.length;
    final id = 'tile_custom_$slotIndex';
    final label = 'Slot $slotIndex Tile';

    try {
      await FlutterTileService.registerTile(
        TileConfig(
          id: id,
          label: label,
          activeLabel: 'ON',
          inactiveLabel: 'OFF',
          description: 'Custom registered tile',
          initialState: TileState.inactive,
        ),
      );
      _log('Registered custom tile "$id"');
      await _refreshTiles();
    } catch (e) {
      _log('Failed to register custom tile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
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
      _log('Failed to unregister tile $id: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isSupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quick Settings Tiles')),
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
                  'Quick Settings Tiles Not Supported',
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
        title: const Text('Quick Settings Tile Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync Native Tiles',
            onPressed: _refreshTiles,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTiles,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Section 1: Reference Attendance Tile Card
            _buildAttendanceHeroCard(theme),
            const SizedBox(height: 16),

            // Section 2: Registered Tiles List
            _buildRegisteredTilesSection(theme),
            const SizedBox(height: 16),

            // Section 3: Live Native Event Logger
            _buildEventLogSection(theme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registerNewCustomTile,
        icon: const Icon(Icons.add_to_home_screen),
        label: const Text('Add Tile Slot'),
      ),
    );
  }

  Widget _buildAttendanceHeroCard(ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isClockedIn
                        ? Colors.green.withAlpha(50)
                        : Colors.grey.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    color: _isClockedIn ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Tile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isClockedIn
                            ? 'Status: CLOCKED IN'
                            : 'Status: CLOCKED OUT',
                        style: TextStyle(
                          color: _isClockedIn ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isClockedIn,
                  onChanged: (_) => _toggleAttendanceFromApp(),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Try pulling down your Android notification shade and tapping the Attendance tile. It updates natively even when this app is closed or backgrounded.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _requestAddTileToSystem('attendance'),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add to Quick Settings (Android 13+)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisteredTilesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Native Tile Slots (${_registeredTiles.length}/4)',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Persisted Natively',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_registeredTiles.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No tiles registered. Tap "+ Add Tile Slot" below.'),
            ),
          )
        else
          ..._registeredTiles.map((tile) => _buildTileCard(tile, theme)),
      ],
    );
  }

  Widget _buildTileCard(TileSnapshot tile, ThemeData theme) {
    final isActive = tile.state == TileState.active;
    final isUnavailable = tile.state == TileState.unavailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnavailable
              ? Colors.grey.shade400
              : (isActive ? theme.colorScheme.primary : Colors.grey.shade700),
          child: Text(
            '#${tile.slot}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          '${tile.config.id} (${tile.currentLabel})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'State: ${tile.state.name.toUpperCase()} • Slot: TileService${tile.slot}\n'
          'Desc: ${tile.currentDescription ?? "None"}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.touch_app_outlined),
              tooltip: 'Toggle state from app',
              onPressed: () async {
                final next = tile.state == TileState.active
                    ? TileState.inactive
                    : TileState.active;
                await FlutterTileService.updateTile(
                  id: tile.id,
                  state: next,
                  label: next == TileState.active ? 'ON' : 'OFF',
                );
                await _refreshTiles();
              },
            ),
            if (tile.id != 'attendance')
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Unregister tile',
                onPressed: () => _unregisterTile(tile.id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLogSection(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Live Event Log',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _eventLogs.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const Divider(),
            if (_eventLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No events received yet. Interact with Quick Settings in Android to see live events.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _eventLogs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        _eventLogs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
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
