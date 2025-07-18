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
import 'package:squads/models/carousel_type.dart';

// Example stat data structure
class PlayerStatData {
  final String statType;
  final dynamic statValue;
  final String? playerName; // Added for PlayerStatWidget
  PlayerStatData({required this.statType, required this.statValue, this.playerName});
}

class StatsCarousel extends StatefulWidget {
  final List<dynamic> stats;
  final String title;
  final String? Function(dynamic stat)? getPlayerName;
  final String? Function(dynamic stat)? getStatType;
  final dynamic Function(dynamic stat)? getStatValue;
  const StatsCarousel({Key? key, required this.stats, required this.title, this.getPlayerName, this.getStatType, this.getStatValue}) : super(key: key);

  @override
  State<StatsCarousel> createState() => _StatsCarouselState();
}

class _StatsCarouselState extends State<StatsCarousel> {
  int _currentIndex = 0;
  Timer? _autoTimer;
  static const Duration autoDuration = Duration(seconds: 5);
  static const Duration resumeDelay = Duration(seconds: 5);

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
      int nextIndex = (_currentIndex + 1) % widget.stats.length;
      _goToPage(nextIndex);
    });
  }

  void _pauseAndResumeAutoScroll() {
    _autoTimer?.cancel();
    _autoTimer = Timer(resumeDelay, _startAutoScroll);
  }

  void _goToPage(int index) {
    if (index >= 0 && index < widget.stats.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stat = widget.stats[_currentIndex];
    final statType = widget.getStatType?.call(stat) ?? '';
    final config = statTypeConfig[statType] ?? {'title': statType, 'description': ''};
    final String sectionTitle = config['title'] ?? widget.title;
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final double bgHeight = width < 500 ? 240 : 320;
    Widget cardWidget;
    // Use the same widget selection logic as before, but with generic stat access
    if (statType == Carousel_Type.NEMEZIS || statType == Carousel_Type.WORST_RIVAL || statType == Carousel_Type.DOMINATION || statType == Carousel_Type.GAMES_PLAYED_TOGETHER) {
      double duelScale = 1.0;
      if (width < 350) {
        duelScale = 0.6;
      } else if (width < 400) {
        duelScale = 0.75;
      }
      cardWidget = PlayerStatDuelWidget(
        playerNameLeft: stat['leftName'],
        playerNameRight: stat['rightName'],
        statType: statType,
        statValue: stat['statValue'] ?? '',
        scale: duelScale,
        description: stat['description'] ?? '',
        date: stat['date'] ?? '',
      );
    } else if (statType == Carousel_Type.H2H) {
      double h2hScale = 1.0;
      if (width < 350) {
        h2hScale = 0.6;
      } else if (width < 400) {
        h2hScale = 0.75;
      }
      cardWidget = PlayerH2HWidget(
        playerName: stat['player1'] ?? '',
        results: List<String>.from(stat['results'] ?? []),
        scale: h2hScale,
      );
    } else if (statType == Carousel_Type.WIN_RATIO) {
      cardWidget = PlayerResultRatioPieWidget(
        win: stat['win'] ?? 0,
        draw: stat['draw'] ?? 0,
        loss: stat['loss'] ?? 0,
      );
    } else if (statType == Carousel_Type.BIGGEST_WIN || statType == Carousel_Type.BIGGEST_LOSS || statType == Carousel_Type.RECENT_MATCH || statType == Carousel_Type.NEXT_MATCH) {
      cardWidget = PlayerMatchResultWidget(
        title: stat['title'] ?? '',
        date: stat['date'] ?? '',
        homeName: stat['homeName'] ?? '',
        awayName: stat['awayName'] ?? '',
        homeScore: stat['homeScore'] ?? 0,
        awayScore: stat['awayScore'] ?? 0,
      );
    } else {
      cardWidget = PlayerStatWidget(
        playerName: widget.getPlayerName?.call(stat) ?? '',
        statType: statType,
        statValue: widget.getStatValue?.call(stat) ?? '',
      );
    }
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
              if (sectionTitle.isNotEmpty)
                Text(
                  sectionTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              if (sectionTitle.isNotEmpty) const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth = constraints.maxWidth < 450 ? constraints.maxWidth - 64 : 400;
                  cardWidth = cardWidth.clamp(220, 400);
                  final bool showArrows = constraints.maxWidth >= 550;
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
                      SizedBox(
                        width: cardWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: GestureDetector(
                            onPanEnd: (details) {
                              final velocity = details.velocity.pixelsPerSecond.dx;
                              if (velocity < -100 && _currentIndex < widget.stats.length - 1) {
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
                            onPressed: _currentIndex < widget.stats.length - 1
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
              if (width >= 400)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.stats.length, (index) {
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
        if (width < 400)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.stats.length, (index) {
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