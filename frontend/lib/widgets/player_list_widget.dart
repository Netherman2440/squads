import 'package:flutter/material.dart';
import '../models/player.dart';

class PlayerListWidget extends StatelessWidget {
  final List<Player> players;
  final Function(Player)? onPlayerTap;
  final bool showScores;

  const PlayerListWidget({
    Key? key,
    required this.players,
    this.onPlayerTap,
    this.showScores = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return _PlayerListItem(
          player: player,
          onTap: onPlayerTap != null ? () => onPlayerTap!(player) : null,
          showScore: showScores,
        );
      },
    );
  }
}

class _PlayerListItem extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;
  final bool showScore;

  const _PlayerListItem({
    Key? key,
    required this.player,
    this.onTap,
    required this.showScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        trailing: showScore
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(player.score),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  player.score.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    if (score >= 4.0) return Colors.red;
    return Colors.grey;
  }
} 