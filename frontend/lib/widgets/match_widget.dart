import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import 'player_widget.dart';

class MatchWidget extends StatefulWidget {
  final List<Player> teamAPlayers;
  final List<Player> teamBPlayers;
  final String? teamAName;
  final String? teamBName;
  final Function(Player)? onPlayerTap;
  final bool showScores;
  final bool canEditTeams;
  final TextEditingController? teamAController;
  final TextEditingController? teamBController;
  final void Function(List<Player> teamA, List<Player> teamB)? onTeamsChanged;

  const MatchWidget({
    Key? key,
    required this.teamAPlayers,
    required this.teamBPlayers,
    this.teamAName,
    this.teamBName,
    this.onPlayerTap,
    this.showScores = true,
    this.canEditTeams = true,
    this.teamAController,
    this.teamBController,
    this.onTeamsChanged,
  }) : super(key: key);

  @override
  State<MatchWidget> createState() => _MatchWidgetState();
}

class _MatchWidgetState extends State<MatchWidget> {
  late List<Player> _teamAPlayers;
  late List<Player> _teamBPlayers;
  late TextEditingController _teamAController;
  late TextEditingController _teamBController;
  bool _isEditingTeamA = false;
  bool _isEditingTeamB = false;

  @override
  void initState() {
    super.initState();
    _teamAPlayers = List<Player>.from(widget.teamAPlayers);
    _teamBPlayers = List<Player>.from(widget.teamBPlayers);
    _teamAController =
        widget.teamAController ??
        TextEditingController(text: widget.teamAName ?? 'FC Biali');
    _teamBController =
        widget.teamBController ??
        TextEditingController(text: widget.teamBName ?? 'Czarni Untd');
  }

  @override
  void didUpdateWidget(covariant MatchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.teamAPlayers != oldWidget.teamAPlayers ||
        widget.teamBPlayers != oldWidget.teamBPlayers) {
      _teamAPlayers = List<Player>.from(widget.teamAPlayers);
      _teamBPlayers = List<Player>.from(widget.teamBPlayers);
    }
  }

  @override
  void dispose() {
    if (widget.teamAController == null) {
      _teamAController.dispose();
    }
    if (widget.teamBController == null) {
      _teamBController.dispose();
    }
    super.dispose();
  }

  void _swapTeams() {
    setState(() {
      final tempPlayers = _teamAPlayers;
      _teamAPlayers = _teamBPlayers;
      _teamBPlayers = tempPlayers;
    });
    widget.onTeamsChanged?.call(_teamAPlayers, _teamBPlayers);
  }

  void _movePlayer(Player player, bool toTeamA) {
    setState(() {
      if (toTeamA) {
        _teamBPlayers.removeWhere((p) => p.playerId == player.playerId);
        _teamAPlayers.add(player);
      } else {
        _teamAPlayers.removeWhere((p) => p.playerId == player.playerId);
        _teamBPlayers.add(player);
      }
    });
    widget.onTeamsChanged?.call(_teamAPlayers, _teamBPlayers);
  }

  double _calculateTeamScore(List<Player> teamPlayers, List<Player> opposingTeamPlayers, {bool allowSubstitutions = true}) {
    if (!allowSubstitutions || teamPlayers.length == opposingTeamPlayers.length) {
      // No substitutions or equal team sizes - count all players
      return teamPlayers.fold(0.0, (sum, player) => sum + player.score);
    }
    
    if (teamPlayers.length > opposingTeamPlayers.length) {
      // This team is larger - exclude the weakest player
      final sortedPlayers = List<Player>.from(teamPlayers)
        ..sort((a, b) => b.score.compareTo(a.score)); // Sort descending by score
      // Take all but the last (weakest) player
      return sortedPlayers.take(sortedPlayers.length - 1)
        .fold(0.0, (sum, player) => sum + player.score);
    } else {
      // This team is smaller - count all players
      return teamPlayers.fold(0.0, (sum, player) => sum + player.score);
    }
  }

  Widget _buildTeamColumn({
    required String title,
    required List<Player> players,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditTap,
    required VoidCallback onSaveTap,
    required VoidCallback onCancelTap,
    required bool isTeamA,
  }) {
    final teamScore = _calculateTeamScore(players, isTeamA ? _teamBPlayers : _teamAPlayers);

    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Team name header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: onSaveTap,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: onCancelTap,
                        ),
                      ],
                    )
                  else
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Builder(
                            builder: (context) {
                              final isNarrowScreen = MediaQuery.of(context).size.width < 600;
                              final displayTitle = isNarrowScreen && title.length > 8
                                  ? '${title.substring(0, 8)}...'
                                  : title;
                              
                              return Text(
                                displayTitle,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            },
                          ),
                        ),
                        if (widget.canEditTeams && MediaQuery.of(context).size.width >= 600)
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: onEditTap,
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${teamScore.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Players list with drag & drop
            Expanded(
              child: DragTarget<Player>(
                onWillAccept:
                    (player) =>
                        widget.canEditTeams &&
                        player != null &&
                        !players.any((p) => p.playerId == player.playerId),
                onAcceptWithDetails:
                    (details) => _movePlayer(details.data, isTeamA),
                builder: (context, candidateData, rejectedData) {
                  final isActive = candidateData.isNotEmpty;
                  return Container(
                    decoration:
                        isActive
                            ? BoxDecoration(
                              color: Colors.blue.withOpacity(0.08),
                              border: Border.all(color: Colors.blue, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            )
                            : null,
                    child:
                        players.isEmpty
                            ? const Center(
                              child: Text(
                                'Brak graczy w drużynie',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: players.length,
                              itemBuilder: (context, index) {
                                final player = players[index];
                                return widget.canEditTeams
                                    ? Draggable<Player>(
                                      data: player,
                                      feedbackOffset: const Offset(150, 0),
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: SizedBox(
                                          width: 300,
                                          child: Opacity(
                                            opacity: 0.7,
                                            child: PlayerWidget(
                                              player: player,
                                              showScores: widget.showScores,
                                              compact: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.3,
                                        child: SizedBox(
                                          width: 300,
                                          child: PlayerWidget(
                                            player: player,
                                            showScores: widget.showScores,
                                            compact: true,
                                          ),
                                        ),
                                      ),
                                      child: PlayerWidget(
                                        player: player,
                                        onTap:
                                            widget.onPlayerTap != null
                                                ? () =>
                                                    widget.onPlayerTap!(player)
                                                : null,
                                        showScores: widget.showScores,
                                        compact: true,
                                      ),
                                    )
                                    : PlayerWidget(
                                      player: player,
                                      onTap:
                                          widget.onPlayerTap != null
                                              ? () =>
                                                  widget.onPlayerTap!(player)
                                              : null,
                                      showScores: widget.showScores,
                                      compact: true,
                                    );
                              },
                            ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildTeamColumn(
                title: _teamAController.text,
                players: _teamAPlayers,
                controller: _teamAController,
                isEditing: _isEditingTeamA,
                onEditTap: () => setState(() => _isEditingTeamA = true),
                onSaveTap: () => setState(() => _isEditingTeamA = false),
                onCancelTap: () {
                  _teamAController.text = widget.teamAName ?? 'FC Biali';
                  setState(() => _isEditingTeamA = false);
                },
                isTeamA: true,
              ),
              _buildTeamColumn(
                title: _teamBController.text,
                players: _teamBPlayers,
                controller: _teamBController,
                isEditing: _isEditingTeamB,
                onEditTap: () => setState(() => _isEditingTeamB = true),
                onSaveTap: () => setState(() => _isEditingTeamB = false),
                onCancelTap: () {
                  _teamBController.text = widget.teamBName ?? 'Czarni Untd';
                  setState(() => _isEditingTeamB = false);
                },
                isTeamA: false,
              ),
            ],
          ),
        ),
        if (widget.canEditTeams && MediaQuery.of(context).size.width >= 600)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _swapTeams,
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: 'Rotuj drużyny',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
