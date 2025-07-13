import 'dart:async';
import 'package:flutter/material.dart';
import 'package:squads/widgets/player_stat_duel_widget.dart';
import 'package:squads/widgets/player_stat_widget.dart';
import 'package:squads/widgets/player_match_result_widget.dart';
import 'package:squads/widgets/player_h2h_widget.dart';
import 'package:squads/theme/color_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:squads/widgets/player_result_ratio_pie_widget.dart';

// Example stat data structure
class PlayerStatData {
  final String statType;
  final dynamic statValue;
  PlayerStatData({required this.statType, required this.statValue});
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

  // Test data for player stats
  late final List<PlayerStatData> _stats = [
    PlayerStatData(statType: 'matches_won', statValue: 5),
    PlayerStatData(statType: 'goals', statValue: 12),
    PlayerStatData(statType: 'assists', statValue: 7),
    // Test duel stat
    PlayerStatData(statType: 'duel_goals', statValue: {'left': 3, 'right': 4, 'leftName': 'Alice', 'rightName': 'Bob', 'description': 'Goals scored in direct duels between Alice and Bob'}),
    // Test match result panel
    PlayerStatData(
      statType: 'match_result',
      statValue: {
        'homeName': 'Team A',
        'awayName': 'Team B',
        'homeScore': 2,
        'awayScore': 3,
        'date': '2024-06-01',
        'title': 'Match Result',
      },
    ),
    // Test h2h panel
    PlayerStatData(
      statType: 'h2h',
      statValue: {
        'player1': 'Alice',
        'player2': 'Bob',
        'results': ['W', 'L', 'D', 'W', 'X'],
      },
    ),
    // Test result ratio pie chart
    PlayerStatData(
      statType: 'result_ratio',
      statValue: {
        'win': 12,
        'draw': 5,
        'loss': 8,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section title
          if (sectionTitle.isNotEmpty)
            Text(
              sectionTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          if (sectionTitle.isNotEmpty) const SizedBox(height: 12),
          // Carousel content with arrows and stat card
          LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = constraints.maxWidth < 450 ? constraints.maxWidth - 64 : 400;
              cardWidth = cardWidth.clamp(220, 400);
              final bool showArrows = constraints.maxWidth >= 550;
              Widget cardWidget;
              if (stat.statType == 'duel_goals') {
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
                );
              } else if (stat.statType == 'match_result') {
                cardWidget = PlayerMatchResultWidget(
                  title: stat.statValue['title'] ?? '',
                  date: stat.statValue['date'] ?? '',
                  homeName: stat.statValue['homeName'] ?? '',
                  awayName: stat.statValue['awayName'] ?? '',
                  homeScore: stat.statValue['homeScore'] ?? 0,
                  awayScore: stat.statValue['awayScore'] ?? 0,
                );
              } else if (stat.statType == 'h2h') {
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
              } else if (stat.statType == 'result_ratio') {
                cardWidget = PlayerResultRatioPieWidget(
                  win: stat.statValue['win'] ?? 0,
                  draw: stat.statValue['draw'] ?? 0,
                  loss: stat.statValue['loss'] ?? 0,
                );
              } else {
                cardWidget = PlayerStatWidget(
                  playerName: widget.player.name,
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
                    height: 270,
                    child: Card(
                      color: cardBgColor,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                            child: Container(
                              key: ValueKey(_currentIndex),
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
          // Dots indicator
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
    );
  }
} 