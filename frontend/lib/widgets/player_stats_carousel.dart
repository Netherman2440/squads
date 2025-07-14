import 'dart:async';
import 'package:flutter/material.dart';
import 'package:squads/widgets/player_stat_duel_widget.dart';
import 'package:squads/widgets/player_stat_widget.dart';
import 'package:squads/widgets/player_match_result_widget.dart';
import 'package:squads/widgets/player_h2h_widget.dart';
import 'package:squads/theme/color_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:squads/widgets/player_result_ratio_pie_widget.dart';
import 'package:squads/models/stat_type_config.dart';
import 'package:squads/models/stat_type.dart';

// Example stat data structure
class PlayerStatData {
  final String statType;
  final dynamic statValue;
  final String? playerName; // Added for PlayerStatWidget
  PlayerStatData({required this.statType, required this.statValue, this.playerName});
}

class PlayerStatsCarousel extends StatefulWidget {
  final dynamic player; // PlayerDetailResponse or similar
  const PlayerStatsCarousel({Key? key, required this.player}) : super(key: key);

  @override
  State<PlayerStatsCarousel> createState() => _PlayerStatsCarouselState();
}

class _PlayerStatsCarouselState extends State<PlayerStatsCarousel> {
  int _currentIndex = 0;
  Timer? _autoTimer;
  static const Duration autoDuration = Duration(seconds: 5);
  static const Duration resumeDelay = Duration(seconds: 5);

  // Test data for player stats using all stat types from statTypeConfig
  late final List<PlayerStatData> _stats = [
    PlayerStatData(
      statType: StatType.BIGGEST_WIN,
      statValue: {
        'title': 'Biggest Win',
        'date': '2024-06-01',
        'homeName': 'Team A',
        'awayName': 'Team B',
        'homeScore': 5,
        'awayScore': 1,
      },
    ),
    PlayerStatData(
      statType: StatType.BIGGEST_LOSS,
      statValue: {
        'title': 'Biggest Loss',
        'date': '2024-06-02',
        'homeName': 'Team C',
        'awayName': 'Team D',
        'homeScore': 1,
        'awayScore': 6,
      },
    ),
    PlayerStatData(
      statType: StatType.WIN_RATIO,
      statValue: {
        'win': 12,
        'draw': 3,
        'loss': 5,
      },
    ),
    PlayerStatData(
      statType: StatType.TOP_TEAMMATE,
      statValue: 8,
      playerName: 'John Doe',
    ),
    PlayerStatData(
      statType: StatType.WIN_TEAMMATE,
      statValue: 5,
      playerName: 'Jane Smith',
    ),
    PlayerStatData(
      statType: StatType.WORST_TEAMMATE,
      statValue: 2,
      playerName: 'Mike Brown',
    ),
    PlayerStatData(
      statType: StatType.NEMEZIS,
      statValue: {
        'left': 2,
        'right': 5,
        'leftName': 'Player',
        'rightName': 'Nemesis',
        'description': 'Wins in direct duels',
      },
    ),
    PlayerStatData(
      statType: StatType.WORST_RIVAL,
      statValue: {
        'left': 6,
        'right': 1,
        'leftName': 'Player',
        'rightName': 'Worst Rival',
        'description': 'Wins in direct duels',
      },
    ),
    PlayerStatData(
      statType: StatType.H2H,
      statValue: {
        'player1': 'Player',
        'player2': 'Opponent',
        'results': ['W', 'L', 'W', 'D', 'L'],
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(autoDuration, (_) {
      if (!mounted) return;
      int nextIndex = (_currentIndex + 1) % _stats.length;
      _goToPage(nextIndex);
    });
  }

  void _pauseAndResumeAutoScroll() {
    _autoTimer?.cancel();
    _autoTimer = Timer(resumeDelay, _startAutoScroll);
  }

  void _goToPage(int index) {
    if (index >= 0 && index < _stats.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stat = _stats[_currentIndex];
    final config = statTypeConfig[stat.statType] ?? {'title': stat.statType, 'description': ''};
    final String sectionTitle = config['title'] ?? '';
    // Choose a color for each stat type from the app theme
    final colorScheme = Theme.of(context).colorScheme;
    final Color cardBgColor = colorScheme.outlineVariant;
    final width = MediaQuery.of(context).size.width;
    final double bgHeight = width < 500 ? 240 : 320;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: bgHeight,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Section title
              if (sectionTitle.isNotEmpty)
                Text(
                  sectionTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              if (sectionTitle.isNotEmpty) const SizedBox(height: 6),
              // Carousel content with arrows and stat card
              LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth = constraints.maxWidth < 450 ? constraints.maxWidth - 64 : 400;
                  cardWidth = cardWidth.clamp(220, 400);
                  final bool showArrows = constraints.maxWidth >= 550;
                  Widget cardWidget;
                  if (stat.statType == StatType.NEMEZIS || stat.statType == StatType.WORST_RIVAL) {
                    double duelScale = 1.0;
                    if (constraints.maxWidth < 350) {
                      duelScale = 0.6;
                    } else if (constraints.maxWidth < 400) {
                      duelScale = 0.75;
                    }
                    cardWidget = PlayerStatDuelWidget(
                      playerNameLeft: stat.statValue['leftName'],
                      playerNameRight: stat.statValue['rightName'],
                      statType: stat.statType,
                      statValue: '${stat.statValue['left']} : ${stat.statValue['right']}',
                      scale: duelScale,
                      description: stat.statValue['description'] ?? '',
                      date: stat.statValue['date'] ?? '',
                    );
                  } else if (stat.statType == StatType.H2H) {
                    double h2hScale = 1.0;
                    if (constraints.maxWidth < 350) {
                      h2hScale = 0.6;
                    } else if (constraints.maxWidth < 400) {
                      h2hScale = 0.75;
                    }
                    cardWidget = PlayerH2HWidget(
                      playerName: stat.statValue['player1'] ?? '',
                      results: List<String>.from(stat.statValue['results'] ?? []),
                      scale: h2hScale,
                    );
                  } else if (stat.statType == StatType.WIN_RATIO) {
                    cardWidget = PlayerResultRatioPieWidget(
                      win: stat.statValue['win'] ?? 0,
                      draw: stat.statValue['draw'] ?? 0,
                      loss: stat.statValue['loss'] ?? 0,
                    );
                  } else if (stat.statType == StatType.BIGGEST_WIN || stat.statType == StatType.BIGGEST_LOSS) {
                    cardWidget = PlayerMatchResultWidget(
                      title: stat.statValue['title'] ?? '',
                      date: stat.statValue['date'] ?? '',
                      homeName: stat.statValue['homeName'] ?? '',
                      awayName: stat.statValue['awayName'] ?? '',
                      homeScore: stat.statValue['homeScore'] ?? 0,
                      awayScore: stat.statValue['awayScore'] ?? 0,
                    );
                  } else {
                    cardWidget = PlayerStatWidget(
                      playerName: stat.playerName ?? widget.player.name,
                      statType: stat.statType,
                      statValue: stat.statValue,
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (showArrows)
                        Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_left, size: 36),
                            onPressed: _currentIndex > 0
                                ? () {
                                    _pauseAndResumeAutoScroll();
                                    _goToPage(_currentIndex - 1);
                                  }
                                : null,
                          ),
                        ),
                      // Stat card with animation and gesture
                      SizedBox(
                        width: cardWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: GestureDetector(
                            onPanEnd: (details) {
                              final velocity = details.velocity.pixelsPerSecond.dx;
                              if (velocity < -100 && _currentIndex < _stats.length - 1) {
                                _pauseAndResumeAutoScroll();
                                _goToPage(_currentIndex + 1);
                              } else if (velocity > 100 && _currentIndex > 0) {
                                _pauseAndResumeAutoScroll();
                                _goToPage(_currentIndex - 1);
                              }
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: SizedBox(
                                key: ValueKey(_currentIndex),
                                height: width < 500 ? 170 : 180,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: cardWidget,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (showArrows)
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_right, size: 36),
                            onPressed: _currentIndex < _stats.length - 1
                                ? () {
                                    _pauseAndResumeAutoScroll();
                                    _goToPage(_currentIndex + 1);
                                  }
                                : null,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // Dots indicator (only for wide screens)
              if (width >= 400)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_stats.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index ? Colors.blue : Colors.grey.shade400,
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
        // Dots indicator for narrow screens (below the card)
        if (width < 400)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_stats.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index ? Colors.blue : Colors.grey.shade400,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
} 