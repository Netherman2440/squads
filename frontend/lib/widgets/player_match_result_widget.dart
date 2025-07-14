import 'package:flutter/material.dart';

class PlayerMatchResultWidget extends StatelessWidget {
  final String title;
  final String date;
  final String homeName;
  final String awayName;
  final int homeScore;
  final int awayScore;

  const PlayerMatchResultWidget({
    Key? key,
    required this.title,
    required this.date,
    required this.homeName,
    required this.awayName,
    required this.homeScore,
    required this.awayScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color baseBg = Colors.white;
    final Color borderColor = theme.colorScheme.outlineVariant;
    final Color textColor = Colors.black;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Score row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Home team name and score
            Column(
              children: [
                Text(
                  homeName,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final width = MediaQuery.of(context).size.width;
                    final double boxSize = width < 400 ? 56 : 80;
                    return _buildScoreBox(score: homeScore.toString(), theme: theme, baseBg: baseBg, borderColor: borderColor, textColor: textColor, boxSize: boxSize);
                  },
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Separator
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ':',
                  style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                
               
              ],
            ),
            const SizedBox(width: 24),
            // Away team name and score
            Column(
              children: [
                Text(
                  awayName,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final width = MediaQuery.of(context).size.width;
                    final double boxSize = width < 400 ? 56 : 80;
                    return _buildScoreBox(score: awayScore.toString(), theme: theme, baseBg: baseBg, borderColor: borderColor, textColor: textColor, boxSize: boxSize);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Date under the result
        Text(
          date,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScoreBox({required String score, required ThemeData theme, required Color baseBg, required Color borderColor, required Color textColor, required double boxSize}) {
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: baseBg,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          score,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
    );
  }
} 