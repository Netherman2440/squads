import 'package:flutter/material.dart';
import 'package:squads/models/player.dart';
import 'package:squads/models/position.dart';
import 'package:squads/widgets/player_widget.dart';

class PlayersListWidget extends StatefulWidget {
  final List<Player> players;
  final void Function(Player)? onPlayerSelected;
  final bool allowAdd;
  final bool allowSelect;

  const PlayersListWidget({
    Key? key,
    required this.players,
    this.onPlayerSelected,
    this.allowAdd = true,
    this.allowSelect = true,
  }) : super(key: key);

  @override
  State<PlayersListWidget> createState() => _PlayersListWidgetState();
}

class _PlayersListWidgetState extends State<PlayersListWidget> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredPlayers = widget.players
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Szukaj gracza',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: filteredPlayers.isEmpty
              ? const Center(child: Text('Brak graczy'))
              : ListView.builder(
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final player = filteredPlayers[index];
                    return PlayerWidget(
                      player: player,
                      onTap: widget.allowSelect && widget.onPlayerSelected != null
                          ? () => widget.onPlayerSelected!(player)
                          : null,
                      showScores: true,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
