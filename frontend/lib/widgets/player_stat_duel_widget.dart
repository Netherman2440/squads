import 'package:flutter/material.dart';
import 'player_stat_widget.dart';

class PlayerStatDuelWidget extends StatelessWidget {
  final String playerNameLeft;
  final String playerNameRight;
  final String statType;
  final dynamic statValue;
  final double scale;
  final String description;
  final String? date;

  const PlayerStatDuelWidget({
    Key? key,
    required this.playerNameLeft,
    required this.playerNameRight,
    required this.statType,
    required this.statValue,
    this.scale = 1.0,
    this.description = '',
    this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = statTypeConfig[statType] ?? {'title': statType, 'description': ''};
    final double imageSize = (MediaQuery.of(context).size.width < 400 ? 56 : 80) * scale;
    final double iconSize = (MediaQuery.of(context).size.width < 400 ? 40 : 60) * scale;
    final double nameFontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16 * scale;
    final double valueFontSize = Theme.of(context).textTheme.headlineMedium?.fontSize ?? 28 * scale;
    final double titleFontSize = Theme.of(context).textTheme.titleLarge?.fontSize ?? 20 * scale;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left player
            Column(
              children: [
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16 * scale),
                  ),
                  child: Icon(Icons.person, size: iconSize, color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.5)),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  playerNameLeft,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: nameFontSize),
                ),
              ],
            ),
            SizedBox(width: 32 * scale),
            // Stat value in the center
            Column(
              children: [
                Text(
                  statValue.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: valueFontSize),
                ),
                if (date != null && date!.isNotEmpty) ...[
                  SizedBox(height: 4 * scale),
                  Text(
                    date!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
            SizedBox(width: 32 * scale),
            // Right player
            Column(
              children: [
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16 * scale),
                  ),
                  child: Icon(Icons.person, size: iconSize, color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.5)),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  playerNameRight,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: nameFontSize),
                ),
              ],
            ),
          ],
        ),
        if (description.isNotEmpty) ...[
          SizedBox(height: 8 * scale),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
} 