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
import '../theme/app_theme.dart';

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
            convertedStat['playerName'] = playerRef.playerName;
            // stat.value is [wins, losses] - for nemezis we want loss percentage
            if (stat.value is List && stat.value.length >= 2) {
              final wins = stat.value[0];
              final losses = stat.value[1];
              final totalMatches = wins + losses;
              if (totalMatches > 0) {
                final lossPercentage = ((losses / totalMatches) * 100).round();
                convertedStat['value'] = '${lossPercentage}% losses';
              } else {
                convertedStat['value'] = '0% losses';
              }
            } else {
              convertedStat['value'] = stat.value.toString() + '% losses';
            }
          }
          break;
        case Carousel_Type.WORST_RIVAL:
          if (stat.ref is PlayerRef) {
            final playerRef = stat.ref as PlayerRef;
            convertedStat['playerName'] = playerRef.playerName;
            // stat.value is [wins, losses] - for worst_rival we want win percentage
            if (stat.value is List && stat.value.length >= 2) {
              final wins = stat.value[0];
              final losses = stat.value[1];
              final totalMatches = wins + losses;
              if (totalMatches > 0) {
                final winPercentage = ((wins / totalMatches) * 100).round();
                convertedStat['value'] = '${winPercentage}% wins';
              } else {
                convertedStat['value'] = '0% wins';
              }
            } else {
              convertedStat['value'] = stat.value.toString() + '% wins';
            }
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
                    // Name row with small photo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Small player image
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.person, size: 32, color: theme.colorScheme.onSecondaryContainer.withOpacity(0.5)),
                        ),
                        const SizedBox(width: 12),
                        // Name (editable)
                        Expanded(
                          child: _isOwner
                              ? GestureDetector(
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
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(player.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Score row (editable)
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
                    // Name row with small photo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Small player image
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.person, size: 40, color: theme.colorScheme.onSecondaryContainer.withOpacity(0.5)),
                        ),
                        const SizedBox(width: 16),
                        // Name (editable)
                        Expanded(
                          child: _isOwner
                              ? GestureDetector(
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
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(player.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Score row (editable)
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
      children: statRows.asMap().entries.map((entry) => 
        _StatRow(stat: entry.value, index: entry.key)).toList(),
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
  final int index;
  const _StatRow({required this.stat, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEven = index % 2 == 0;
    
    // Alternate beige background colors matching app theme
    final backgroundColor = isEven 
        ? (isDark ? AppColors.borderMuted.withOpacity(0.4) : const Color(0xFFF0EBE6)) 
        : (isDark ? AppColors.borderMuted.withOpacity(0.2) : const Color(0xFFF8F5F2));
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(stat.title, style: theme.textTheme.bodyMedium),
          ),
          Text(stat.value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
} 