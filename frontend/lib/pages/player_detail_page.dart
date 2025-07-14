import 'package:flutter/material.dart';
import 'package:squads/models/player.dart';
import 'package:squads/services/player_service.dart';
import 'package:squads/models/position.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squads/state/squad_state.dart';
import 'package:squads/state/user_state.dart';
import 'package:squads/state/players_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:squads/widgets/player_stat_widget.dart';
import 'package:squads/widgets/player_stats_carousel.dart';
import '../models/stat_type.dart';
import '../models/stat_type_config.dart';

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

  // Test data for score history
  final List<double> _testScores = [63, 69, 70, 46, 33, 55, 80, 77, 90, 60];

  // Test data for player stats
  final List<Map<String, dynamic>> playerStats = [
    {
      'statType': 'biggest_win',
      'title': 'Biggest Win',
      'date': '2024-06-01',
      'homeName': 'Team A',
      'awayName': 'Team B',
      'homeScore': 5,
      'awayScore': 1,
    },
    {
      'statType': 'biggest_loss',
      'title': 'Biggest Loss',
      'date': '2024-06-02',
      'homeName': 'Team C',
      'awayName': 'Team D',
      'homeScore': 1,
      'awayScore': 6,
    },
    {
      'statType': 'win_ratio',
      'win': 12,
      'draw': 3,
      'loss': 5,
    },
    {
      'statType': 'top_teammate',
      'playerName': 'John Doe',
      'value': 8,
    },
    {
      'statType': 'win_teammate',
      'playerName': 'Jane Smith',
      'value': 5,
    },
    {
      'statType': 'worst_teammate',
      'playerName': 'Mike Brown',
      'value': 2,
    },
    {
      'statType': 'nemezis',
      'left': 2,
      'right': 5,
      'leftName': 'Player',
      'rightName': 'Nemesis',
      'description': 'Wins in direct duels',
    },
    {
      'statType': 'worst_rival',
      'left': 6,
      'right': 1,
      'leftName': 'Player',
      'rightName': 'Worst Rival',
      'description': 'Wins in direct duels',
    },
    {
      'statType': 'h2h',
      'player1': 'Player',
      'player2': 'Opponent',
      'results': ['W', 'L', 'W', 'D', 'L'],
    },
  ];

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
    ref.read(playersProvider.notifier).removePlayer(widget.player.playerId);
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
      body: SingleChildScrollView(
        child: FutureBuilder<PlayerDetailResponse>(
          future: _playerDetailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error:  {snapshot.error}'));
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
              return Padding(
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
                    // Score History section title
                    const Text('Score History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Score History graph
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 100,
                            minX: 0,
                            maxX: (_testScores.length - 1).toDouble(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 20,
                                  getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true, horizontalInterval: 20, verticalInterval: 1),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (int i = 0; i < _testScores.length; i++)
                                    FlSpot(i.toDouble(), _testScores[i]),
                                ],
                                isCurved: false,
                                barWidth: 3,
                                color: Colors.blue,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Player Stats Carousel Section
                    StatsCarousel(
                      stats: playerStats,
                      title: 'Player Stats',
                      getPlayerName: (stat) => stat['playerName'] ?? '',
                      getStatType: (stat) => stat['statType'] ?? '',
                      getStatValue: (stat) => stat['value'] ?? '',
                    ),
                    const SizedBox(height: 16),
                    // Detailed Stats Section (test data)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Detailed Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          _DetailedStatsList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Wide/desktop layout
              return Padding(
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
                    // Score History section title
                    const Text('Score History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Score History graph (desktop)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 100,
                            minX: 0,
                            maxX: (_testScores.length - 1).toDouble(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 20,
                                  getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true, horizontalInterval: 20, verticalInterval: 1),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (int i = 0; i < _testScores.length; i++)
                                    FlSpot(i.toDouble(), _testScores[i]),
                                ],
                                isCurved: false,
                                barWidth: 3,
                                color: Colors.blue,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Player Stats Carousel Section
                    StatsCarousel(
                      stats: playerStats,
                      title: 'Player Stats',
                      getPlayerName: (stat) => stat['playerName'] ?? '',
                      getStatType: (stat) => stat['statType'] ?? '',
                      getStatValue: (stat) => stat['value'] ?? '',
                    ),
                    const SizedBox(height: 32),
                    // Detailed Stats Section (test data)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Detailed Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          _DetailedStatsList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _DetailedStatsList extends StatelessWidget {
  const _DetailedStatsList();

  @override
  Widget build(BuildContext context) {
    // Test data
    final stats = [
      _StatRowData('Base Score', '50'),
      _StatRowData('Score', '63'),
      _StatRowData('Win Streak', '4'),
      _StatRowData('Average Goals', '2.1'),
      _StatRowData('Average Goals Against', '1.3'),
      _StatRowData('Matches', '27'),
      _StatRowData('Total Wins', '15'),
      _StatRowData('Total Loss', '8'),
      _StatRowData('Total Draw', '4'),
    ];
    return Column(
      children: stats.map((stat) => _StatRow(stat: stat)).toList(),
    );
  }
}

class _StatRowData {
  final String title;
  final String value;
  const _StatRowData(this.title, this.value);
}

class _StatRow extends StatelessWidget {
  final _StatRowData stat;
  const _StatRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(stat.title, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate number of dots based on available width
                final dotCount = (constraints.maxWidth / 3).floor() - 1;
                return Text(
                  List.filled(dotCount > 0 ? dotCount : 1, '.').join(),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  overflow: TextOverflow.clip,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(stat.value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
} 