import 'package:flutter/material.dart';

// Config for mapping stat type to title and description
const Map<String, Map<String, String>> statTypeConfig = {
  'matches_won': {
    'title': 'Matches Won',
    'description': 'Number of matches won by the player',
  },
  'goals': {
    'title': 'Goals',
    'description': 'Total goals scored by the player',
  },
  'assists': {
    'title': 'Assists',
    'description': 'Total assists by the player',
  },
  // Add more stat types as needed
};

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
    final config = statTypeConfig[statType] ?? {'title': statType, 'description': ''};
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Player image placeholder
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.5)),
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