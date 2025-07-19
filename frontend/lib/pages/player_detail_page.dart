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
import 'package:squads/widgets/stats_carousel.dart';
import '../models/carousel_type.dart';
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

  String _getStatDescription(String statType) {
    return statTypeConfig[statType]?['description'] ?? '';
  }

  // Convert CarouselStat to the format expected by StatsCarousel
  List<Map<String, dynamic>> _convertCarouselStats(List<CarouselStat> carouselStats) {
    return carouselStats.map((stat) {
      final Map<String, dynamic> convertedStat = {
        'statType': stat.type,
        'value': stat.value,
      };

      // Handle different types of carousel stats
      switch (stat.type) {
        case Carousel_Type.BIGGEST_WIN:
        case Carousel_Type.BIGGEST_LOSS:
          if (stat.ref is MatchRef) {
            final matchRef = stat.ref as MatchRef;
            convertedStat.addAll({
              'title': stat.type == Carousel_Type.BIGGEST_WIN ? 'Biggest Win' : 'Biggest Loss',
              'date': matchRef.matchDate.toString().split(' ')[0],
              'homeName': 'Team A', // These would need to come from match data
              'awayName': 'Team B',
              'homeScore': matchRef.score?[0] ?? 0,
              'awayScore': matchRef.score?[1] ?? 0,
            });
          }
          break;

        case Carousel_Type.WIN_RATIO:
          if (stat.value is List) {
            final values = stat.value as List;
            convertedStat.addAll({
              'win': int.tryParse(values[0].toString()) ?? 0,
              'draw': int.tryParse(values[1].toString()) ?? 0,
              'loss': int.tryParse(values[2].toString()) ?? 0,
            });
          }
          break;

        case Carousel_Type.H2H:
          if (stat.ref is PlayerRef) {
            final playerRef = stat.ref as PlayerRef;
            convertedStat.addAll({
              'player1': widget.player.name,
              'player2': playerRef.playerName,
              'results': stat.value is List 
                  ? (stat.value as List).map((e) => e.toString()).toList()
                  : <String>[],
            });
          }
          break;

        case Carousel_Type.TOP_TEAMMATE:
          if (stat.ref is PlayerRef) {
            final playerRef = stat.ref as PlayerRef;
            convertedStat['playerName'] = playerRef.playerName;
          }
          break;
                case Carousel_Type.WIN_TEAMMATE:
          if (stat.ref is PlayerRef) {
            final playerRef = stat.ref as PlayerRef;
            convertedStat['playerName'] = playerRef.playerName;
            convertedStat['value'] = stat.value.toString() + '% wins';
          }
          break;
        case Carousel_Type.WORST_TEAMMATE:
          if (stat.ref is PlayerRef) {
            final playerRef = stat.ref as PlayerRef;
            convertedStat['playerName'] = playerRef.playerName;
            convertedStat['value'] = stat.value.toString() + '% losses';
          }
          break;
        case Carousel_Type.NEMEZIS:
          if (stat.ref is PlayerRef) {
            final playerRef = stat.ref as PlayerRef;
            convertedStat['leftName'] = widget.player.name;
            convertedStat['rightName'] = playerRef.playerName;
            // stat.value is [wins, losses]
            if (stat.value is List && stat.value.length >= 2) {
              convertedStat['statValue'] = '${stat.value[0]}:${stat.value[1]}';
            } else {
              convertedStat['statValue'] = stat.value.toString();
            }
            convertedStat['description'] = _getStatDescription(stat.type);
          }
          break;
        case Carousel_Type.WORST_RIVAL:
          if (stat.ref is PlayerRef) {
            final playerRef = stat.ref as PlayerRef;
            convertedStat['leftName'] = widget.player.name;
            convertedStat['rightName'] = playerRef.playerName;
            // stat.value is [wins, losses]  
            if (stat.value is List && stat.value.length >= 2) {
              convertedStat['statValue'] = '${stat.value[0]}:${stat.value[1]}';
            } else {
              convertedStat['statValue'] = stat.value.toString();
            }
            convertedStat['description'] = _getStatDescription(stat.type);
          }
          break;
      }

      return convertedStat;
    }).toList();
  }

  // Convert score history to chart data
  List<double> _getScoreHistoryData(List<ScoreHistory> scoreHistory) {
    return scoreHistory.map((history) => history.score.toDouble()).toList();
  }

  // Calculate dynamic Y axis bounds for better visibility of score changes
  Map<String, double> _getYAxisBounds(List<double> scoreData) {
    if (scoreData.isEmpty) {
      return {'minY': 0, 'maxY': 100, 'interval': 5};
    }
    
    final minScore = scoreData.reduce((a, b) => a < b ? a : b);
    final maxScore = scoreData.reduce((a, b) => a > b ? a : b);
    
    // Round down to nearest multiple of 5 for minY, round up for maxY
    final minY = (minScore / 5).floor() * 5.0;
    final maxY = (maxScore / 5).ceil() * 5.0;
    
    // Ensure there's at least 10 point range for visibility
    final adjustedMaxY = maxY - minY < 10 ? minY + 10 : maxY;
    
    return {'minY': minY, 'maxY': adjustedMaxY, 'interval': 5};
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
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data'));
            }
            final player = snapshot.data!;
            final scoreDelta = player.score - player.baseScore;
            final isUp = scoreDelta >= 0;
            final theme = Theme.of(context);

            // Get real data from player stats
            final scoreHistoryData = _getScoreHistoryData(player.stats.scoreHistory);
            final carouselStats = _convertCarouselStats(player.stats.carouselStats);

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
                    // Score History section title (mobile)
                    const Text('Score History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                                        // Score History graph (mobile)
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: scoreHistoryData.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Builder(
                                builder: (context) {
                                  final yBounds = _getYAxisBounds(scoreHistoryData);
                                  return LineChart(
                                    LineChartData(
                                      minY: yBounds['minY']!,
                                      maxY: yBounds['maxY']!,
                                      minX: 0,
                                      maxX: (scoreHistoryData.length - 1).toDouble(),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: yBounds['interval']!,
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
                                  gridData: FlGridData(show: true, horizontalInterval: yBounds['interval']!, verticalInterval: 1),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        for (int i = 0; i < scoreHistoryData.length; i++)
                                          FlSpot(i.toDouble(), scoreHistoryData[i]),
                                      ],
                                      isCurved: false,
                                      barWidth: 3,
                                      color: Colors.blue,
                                      dotData: FlDotData(show: true),
                                    ),
                                  ],
                                ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                'No score history available',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Player Stats Carousel Section - only show if carouselStats exist
                    if (carouselStats.isNotEmpty) ...[
                      StatsCarousel(
                        stats: carouselStats,
                        title: 'Player Stats',
                        getPlayerName: (stat) => stat['playerName'] ?? '',
                        getStatType: (stat) => stat['statType'] ?? '',
                        getStatValue: (stat) => stat['value'] ?? '',
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Detailed Stats Section using real data
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Detailed Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _DetailedStatsList(stats: player.stats),
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
                    // Score History section title (desktop)
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
                      child: scoreHistoryData.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Builder(
                                builder: (context) {
                                  final yBounds = _getYAxisBounds(scoreHistoryData);
                                  return LineChart(
                                    LineChartData(
                                      minY: yBounds['minY']!,
                                      maxY: yBounds['maxY']!,
                                      minX: 0,
                                      maxX: (scoreHistoryData.length - 1).toDouble(),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: yBounds['interval']!,
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
                                  gridData: FlGridData(show: true, horizontalInterval: yBounds['interval']!, verticalInterval: 1),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        for (int i = 0; i < scoreHistoryData.length; i++)
                                          FlSpot(i.toDouble(), scoreHistoryData[i]),
                                      ],
                                      isCurved: false,
                                      barWidth: 3,
                                      color: Colors.blue,
                                      dotData: FlDotData(show: true),
                                    ),
                                  ],
                                ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                'No score history available',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                    // Player Stats Carousel Section - only show if carouselStats exist
                    if (carouselStats.isNotEmpty) ...[
                      StatsCarousel(
                        stats: carouselStats,
                        title: 'Player Stats',
                        getPlayerName: (stat) => stat['playerName'] ?? '',
                        getStatType: (stat) => stat['statType'] ?? '',
                        getStatValue: (stat) => stat['value'] ?? '',
                      ),
                      const SizedBox(height: 32),
                    ],
                    // Detailed Stats Section using real data
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Detailed Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _DetailedStatsList(stats: player.stats),
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
  final PlayerStats stats;
  
  const _DetailedStatsList({required this.stats});

  @override
  Widget build(BuildContext context) {
    final statRows = [
      _StatRowData('Base Score', stats.baseScore.toString()),
      _StatRowData('Current Score', stats.score.toString()),
      _StatRowData('Win Streak', stats.winStreak.toString()),
      _StatRowData('Loss Streak', stats.lossStreak.toString()),
      _StatRowData('Biggest Win Streak', stats.biggestWinStreak.toString()),
      _StatRowData('Biggest Loss Streak', stats.biggestLossStreak.toString()),
      _StatRowData('Goals Scored', stats.goalsScored.toString()),
      _StatRowData('Goals Conceded', stats.goalsConceded.toString()),
      _StatRowData('Average Goals per Match', stats.avgGoalsPerMatch.toStringAsFixed(1)),
              _StatRowData('Average Score', '${stats.avgScore[0].round()} - ${stats.avgScore[1].round()}'),
      _StatRowData('Total Matches', stats.totalMatches.toString()),
      _StatRowData('Total Wins', stats.totalWins.toString()),
      _StatRowData('Total Losses', stats.totalLosses.toString()),
      _StatRowData('Total Draws', stats.totalDraws.toString()),
    ];
    
    return Column(
      children: statRows.map((stat) => _StatRow(stat: stat)).toList(),
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