import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class PlayerWidget extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;
  final bool showScores;
  final bool compact; // If true, use compact layout for narrow columns

  const PlayerWidget({
    Key? key,
    required this.player,
    this.onTap,
    this.showScores = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // Compact layout: no icon, name and score in one row, ellipsis for long names
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final isNarrowScreen = MediaQuery.of(context).size.width < 600;
                      final displayName = isNarrowScreen && player.name.length > 8
                          ? '${player.name.substring(0, 8)}...'
                          : player.name;
                      
                      return Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    },
                  ),
                ),
                if (showScores)
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      final Color baseBg = theme.brightness == Brightness.dark
                          ? AppColors.lightSurface
                          : AppColors.lightSurface;
                      final Color borderColor = player.score != 0.0
                          ? theme.colorScheme.primary.withOpacity(0.5)
                          : theme.colorScheme.outlineVariant;
                      return Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: baseBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          player.score.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(
            Icons.sports_soccer,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          player.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.sports,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${player.matchesPlayed} meczów',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: showScores
            ? Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  final Color baseBg = theme.brightness == Brightness.dark
                      ? AppColors.lightSurface
                      : AppColors.lightSurface;
                  final Color borderColor = player.score != 0.0
                      ? theme.colorScheme.primary.withOpacity(0.5)
                      : theme.colorScheme.outlineVariant;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: baseBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      player.score.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  Color _getScoreColor(double score) {
    // This function is no longer used for background color, but may be used elsewhere.
    // Keeping for compatibility, but not used for score display background anymore.
    return Colors.grey;
  }
} 