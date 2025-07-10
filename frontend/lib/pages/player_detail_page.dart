import 'package:flutter/material.dart';
import 'package:squads/models/player.dart';
import 'package:squads/services/player_service.dart';
import 'package:squads/models/position.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squads/state/squad_state.dart';
import 'package:squads/state/user_state.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  final Player player;

  const PlayerDetailPage({Key? key, required this.player}) : super(key: key);

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage> {
  late Future<PlayerDetailResponse> _playerDetailFuture;
  bool _isEditingName = false;
  bool _isEditingScore = false;
  bool _isEditingPosition = false;
  final _nameController = TextEditingController();
  final _scoreController = TextEditingController();
  Position? _selectedPosition;
  bool _isDeleting = false;
  bool get _isOwner {
    final squadState = ref.watch(squadProvider);
    final userId = ref.watch(userSessionProvider).user?.userId ?? '';
    return squadState.isOwner(userId);
  }

  @override
  void initState() {
    super.initState();
    _playerDetailFuture = PlayerService.instance.getPlayer(widget.player.squadId, widget.player.playerId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _refresh() {
    setState(() {
      _playerDetailFuture = PlayerService.instance.getPlayer(widget.player.squadId, widget.player.playerId);
    });
  }

  Future<void> _updateName(String newName) async {
    if (!_isOwner) return;
    await PlayerService.instance.updatePlayerName(widget.player.squadId, widget.player.playerId, newName);
    _refresh();
  }

  Future<void> _updateScore(int newScore) async {
    if (!_isOwner) return;
    await PlayerService.instance.updatePlayerScore(widget.player.squadId, widget.player.playerId, newScore);
    _refresh();
  }

  Future<void> _updatePosition(Position newPosition) async {
    if (!_isOwner) return;
    await PlayerService.instance.updatePlayerPosition(widget.player.squadId, widget.player.playerId, newPosition);
    _refresh();
  }

  Future<void> _deletePlayer() async {
    if (!_isOwner) return;
    setState(() { _isDeleting = true; });
    await PlayerService.instance.deletePlayer(widget.player.squadId, widget.player.playerId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Details'),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isDeleting ? null : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Player'),
                    content: const Text('Are you sure you want to delete this player?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _deletePlayer();
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<PlayerDetailResponse>(
        future: _playerDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          }
          final player = snapshot.data!;
          final scoreDelta = player.score - player.baseScore;
          final isUp = scoreDelta >= 0;
          final theme = Theme.of(context);

          // Responsive layout: grid for narrow screens, current layout for wide screens
          if (isNarrow) {
            // Mobile/narrow layout: grid style
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  _isEditingName = false;
                  _isEditingScore = false;
                  _isEditingPosition = false;
                });
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Player image on the left
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.person, size: 80, color: theme.colorScheme.onSecondaryContainer.withOpacity(0.5)),
                        ),
                        const SizedBox(width: 16),
                        // Name and score on the right, flexible for editing
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name row, editable
                              if (_isOwner)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isEditingName = true;
                                      _isEditingScore = false;
                                      _isEditingPosition = false;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.transparent,
                                        width: _isEditingName ? 2 : 0,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _isEditingName
                                        ? Row(
                                            children: [
                                              // Flexible text field for name
                                              Flexible(
                                                child: TextField(
                                                  controller: _nameController..text = player.name,
                                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                                  style: theme.textTheme.titleLarge,
                                                  autofocus: true,
                                                  onSubmitted: (val) async {
                                                    await _updateName(val);
                                                    setState(() { _isEditingName = false; });
                                                  },
                                                  enabled: _isOwner,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.check, color: Colors.green),
                                                onPressed: () async {
                                                  await _updateName(_nameController.text);
                                                  setState(() { _isEditingName = false; });
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, color: Colors.red),
                                                onPressed: () => setState(() { _isEditingName = false; }),
                                              ),
                                            ],
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Text(player.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                          ),
                                  ),
                                ),
                              if (!_isOwner)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(player.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                              const SizedBox(height: 8),
                              // Score row, editable
                              if (_isOwner)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isEditingScore = true;
                                      _isEditingName = false;
                                      _isEditingPosition = false;
                                    });
                                  },
                                  child: _isEditingScore
                                      ? Row(
                                          children: [
                                            Flexible(
                                              child: TextField(
                                                controller: _scoreController..text = player.score.toString(),
                                                keyboardType: TextInputType.number,
                                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                                autofocus: true,
                                                onSubmitted: (val) async {
                                                  final newScore = int.tryParse(val);
                                                  if (newScore != null) {
                                                    await _updateScore(newScore);
                                                  }
                                                  setState(() { _isEditingScore = false; });
                                                },
                                                enabled: _isOwner,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.check, color: Colors.green),
                                              onPressed: () async {
                                                final newScore = int.tryParse(_scoreController.text);
                                                if (newScore != null) {
                                                  await _updateScore(newScore);
                                                }
                                                setState(() { _isEditingScore = false; });
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              onPressed: () => setState(() { _isEditingScore = false; }),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Text(
                                              player.score.toStringAsFixed(1),
                                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              isUp ? Icons.arrow_upward : Icons.arrow_downward,
                                              color: isUp ? Colors.green : Colors.red,
                                              size: 20,
                                            ),
                                            Text(
                                              (isUp ? '+' : '') + scoreDelta.toStringAsFixed(1),
                                              style: TextStyle(
                                                color: isUp ? Colors.green : Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              if (!_isOwner)
                                Row(
                                  children: [
                                    Text(
                                      player.score.toStringAsFixed(1),
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isUp ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: isUp ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                    Text(
                                      (isUp ? '+' : '') + scoreDelta.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: isUp ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Row with position and matches played
                    Row(
                      children: [
                        // Position (editable)
                        if (_isOwner)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEditingPosition = true;
                                _isEditingName = false;
                                _isEditingScore = false;
                              });
                            },
                            child: Row(
                              children: [
                                Text('Position: ', style: theme.textTheme.bodyMedium),
                                _isEditingPosition
                                    ? Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: theme.colorScheme.primary, width: 2),
                                              borderRadius: BorderRadius.circular(8),
                                              color: theme.colorScheme.surface,
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: DropdownButton<Position>(
                                              value: _selectedPosition ?? player.position,
                                              items: Position.values.map((pos) => DropdownMenuItem(
                                                value: pos,
                                                child: Text(pos.name),
                                              )).toList(),
                                              onChanged: (pos) => setState(() { _selectedPosition = pos; }),
                                              underline: const SizedBox(),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check, color: Colors.green),
                                            onPressed: () async {
                                              if (_selectedPosition != null) {
                                                await _updatePosition(_selectedPosition!);
                                              }
                                              setState(() { _isEditingPosition = false; _selectedPosition = null; });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            onPressed: () => setState(() { _isEditingPosition = false; _selectedPosition = null; }),
                                          ),
                                        ],
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.transparent, width: 2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Text(player.position.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      ),
                              ],
                            ),
                          ),
                        if (!_isOwner)
                          Row(
                            children: [
                              Text('Position: ', style: theme.textTheme.bodyMedium),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.transparent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(player.position.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        const SizedBox(width: 16),
                        // Matches played
                        Icon(Icons.people, size: 18, color: theme.colorScheme.onBackground.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text('Matches played: ${player.matchesPlayed}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Placeholder for Score History graph
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Score History (coming soon)', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 16),
                    // Placeholder for extra stats
                    Container(
                      height: 70,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Additional stats (coming soon)', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Wide/desktop layout
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  _isEditingName = false;
                  _isEditingScore = false;
                  _isEditingPosition = false;
                });
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Player image placeholder, large square, full height of data section
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(Icons.person, size: 200, color: theme.colorScheme.onSecondaryContainer.withOpacity(0.5)),
                        ),
                        const SizedBox(width: 32),
                        // Main info, left-aligned
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name row, click to edit, always in border if editing
                              if (_isOwner)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isEditingName = true;
                                      _isEditingScore = false;
                                      _isEditingPosition = false;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.transparent,
                                        width: _isEditingName ? 3 : 0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: _isEditingName
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 220,
                                                child: TextField(
                                                  controller: _nameController..text = player.name,
                                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                                  style: theme.textTheme.headlineSmall,
                                                  autofocus: true,
                                                  onSubmitted: (val) async {
                                                    await _updateName(val);
                                                    setState(() { _isEditingName = false; });
                                                  },
                                                  enabled: _isOwner,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.check, color: Colors.green),
                                                onPressed: () async {
                                                  await _updateName(_nameController.text);
                                                  setState(() { _isEditingName = false; });
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, color: Colors.red),
                                                onPressed: () => setState(() { _isEditingName = false; }),
                                              ),
                                            ],
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Text(player.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                          ),
                                ),
                              ),
                              if (!_isOwner)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(player.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                              const SizedBox(height: 24),
                              // Score row, click to edit, left-aligned, no container
                              if (_isOwner)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isEditingScore = true;
                                      _isEditingName = false;
                                      _isEditingPosition = false;
                                    });
                                  },
                                  child: _isEditingScore
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: SizedBox(
                                                width: 100,
                                                child: TextField(
                                                  controller: _scoreController..text = player.score.toString(),
                                                  keyboardType: TextInputType.number,
                                                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                                  autofocus: true,
                                                  onSubmitted: (val) async {
                                                    final newScore = int.tryParse(val);
                                                    if (newScore != null) {
                                                      await _updateScore(newScore);
                                                    }
                                                    setState(() { _isEditingScore = false; });
                                                  },
                                                  enabled: _isOwner,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.check, color: Colors.green),
                                              onPressed: () async {
                                                final newScore = int.tryParse(_scoreController.text);
                                                if (newScore != null) {
                                                  await _updateScore(newScore);
                                                }
                                                setState(() { _isEditingScore = false; });
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              onPressed: () => setState(() { _isEditingScore = false; }),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              player.score.toStringAsFixed(1),
                                              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 16),
                                            // Score delta as styled text
                                            Row(
                                              children: [
                                                Icon(
                                                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                                                  color: isUp ? Colors.green : Colors.red,
                                                  size: 24,
                                                ),
                                                Text(
                                                  (isUp ? '+' : '') + scoreDelta.toStringAsFixed(1),
                                                  style: TextStyle(
                                                    color: isUp ? Colors.green : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                              if (!_isOwner)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      player.score.toStringAsFixed(1),
                                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: [
                                        Icon(
                                          isUp ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: isUp ? Colors.green : Colors.red,
                                          size: 24,
                                        ),
                                        Text(
                                          (isUp ? '+' : '') + scoreDelta.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: isUp ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 24),
                              // Position and matches played
                              if (_isOwner)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isEditingPosition = true;
                                      _isEditingName = false;
                                      _isEditingScore = false;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Text('Position: ', style: theme.textTheme.bodyMedium),
                                      _isEditingPosition
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: theme.colorScheme.primary, width: 3),
                                                    borderRadius: BorderRadius.circular(10),
                                                    color: theme.colorScheme.surface,
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  child: DropdownButton<Position>(
                                                    value: _selectedPosition ?? player.position,
                                                    items: Position.values.map((pos) => DropdownMenuItem(
                                                      value: pos,
                                                      child: Text(pos.name),
                                                    )).toList(),
                                                    onChanged: (pos) => setState(() { _selectedPosition = pos; }),
                                                    underline: const SizedBox(),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.check, color: Colors.green),
                                                  onPressed: () async {
                                                    if (_selectedPosition != null) {
                                                      await _updatePosition(_selectedPosition!);
                                                    }
                                                    setState(() { _isEditingPosition = false; _selectedPosition = null; });
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close, color: Colors.red),
                                                  onPressed: () => setState(() { _isEditingPosition = false; _selectedPosition = null; }),
                                                ),
                                              ],
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.transparent, width: 3),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              child: Text(player.position.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                            ),
                                    ],
                                  ),
                                ),
                              if (!_isOwner)
                                Row(
                                  children: [
                                    Text('Position: ', style: theme.textTheme.bodyMedium),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.transparent, width: 3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      child: Text(player.position.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.people, size: 20, color: theme.colorScheme.onBackground.withOpacity(0.7)),
                                  const SizedBox(width: 8),
                                  Text('Matches played: ${player.matchesPlayed}', style: theme.textTheme.bodyMedium),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Placeholder for Score History graph
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Score History (coming soon)', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 32),
                    // Placeholder for extra stats
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Additional stats (coming soon)', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
} 