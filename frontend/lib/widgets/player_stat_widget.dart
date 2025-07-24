import 'package:flutter/material.dart';
import 'package:squads/models/stat_type_config.dart' as stat_type_config;

class PlayerStatWidget extends StatelessWidget {
  final String playerName;
  final String statType;
  final dynamic statValue;

  const PlayerStatWidget({
    Key? key,
    required this.playerName,
    required this.statType,
    required this.statValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = stat_type_config.statTypeConfig[statType] ?? {'title': statType, 'description': ''};
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Player image placeholder
        Builder(
          builder: (context) {
            final width = MediaQuery.of(context).size.width;
            final double imageSize = width < 400 ? 56 : 80;
            final double iconSize = width < 400 ? 40 : 60;
            return Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.person, size: iconSize, color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.5)),
            );
          },
        ),
        const SizedBox(height: 12),
        // Player name
        Text(
          playerName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Stat value
        Text(
          statValue.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 4),
        // Stat title
        // Stat description
        Text(
          config['description'] ?? '',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 