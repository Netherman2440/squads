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
  late final TextEditingController _searchController;

  // Add createdAt sort type
  SortType _sortType = SortType.name;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Always start sorted by name ascending
    _sortType = SortType.name;
    _isAscending = true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Apply search filter
    List<Player> filteredPlayers = widget.players
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    // Apply sorting
    filteredPlayers.sort((a, b) {
      switch (_sortType) {
        case SortType.name:
          return _isAscending
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case SortType.score:
          return _isAscending
              ? (a.score ?? 0).compareTo(b.score ?? 0)
              : (b.score ?? 0).compareTo(a.score ?? 0);
        case SortType.createdAt:
          return _isAscending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt);
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
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
              const SizedBox(width: 8),
              PopupMenuButton<_SortMenuAction>(
                icon: const Icon(Icons.unfold_more),
                tooltip: 'Sortuj',
                onSelected: (action) {
                  setState(() {
                    switch (action) {
                      case _SortMenuAction.toggleName:
                        if (_sortType == SortType.name) {
                          _isAscending = !_isAscending;
                        } else {
                          _sortType = SortType.name;
                          _isAscending = false; // When switching, show Z-A as alternative
                        }
                        break;
                      case _SortMenuAction.toggleScore:
                        if (_sortType == SortType.score) {
                          _isAscending = !_isAscending;
                        } else {
                          _sortType = SortType.score;
                          _isAscending = false; // Default: best to worst
                        }
                        break;
                      case _SortMenuAction.toggleCreatedAt:
                        if (_sortType == SortType.createdAt) {
                          _isAscending = !_isAscending;
                        } else {
                          _sortType = SortType.createdAt;
                          _isAscending = false; // Default: newest first
                        }
                        break;
                    }
                  });
                },
                itemBuilder: (context) {
                  List<PopupMenuEntry<_SortMenuAction>> items = [];
                  // Always show the alternative for the current sort type first
                  if (_sortType == SortType.name) {
                    items.add(
                      PopupMenuItem(
                        value: _SortMenuAction.toggleName,
                        child: Row(
                          children: const [
                            Icon(Icons.sort_by_alpha),
                            SizedBox(width: 8),
                            Text('Z → A'),
                          ],
                        ),
                      ),
                    );
                  } else {
                    items.add(
                      PopupMenuItem(
                        value: _SortMenuAction.toggleName,
                        child: Row(
                          children: const [
                            Icon(Icons.sort_by_alpha),
                            SizedBox(width: 8),
                            Text('A → Z'),
                          ],
                        ),
                      ),
                    );
                  }
                  if (_sortType == SortType.score) {
                    items.add(
                      PopupMenuItem(
                        value: _SortMenuAction.toggleScore,
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_upward),
                            SizedBox(width: 8),
                            Text('Score ↑'),
                          ],
                        ),
                      ),
                    );
                  } else {
                    items.add(
                      PopupMenuItem(
                        value: _SortMenuAction.toggleScore,
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_downward),
                            SizedBox(width: 8),
                            Text('Score ↓'),
                          ],
                        ),
                      ),
                    );
                  }
                  if (_sortType == SortType.createdAt) {
                    items.add(
                      PopupMenuItem(
                        value: _SortMenuAction.toggleCreatedAt,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Text(_isAscending ? 'Oldest' : 'Newest'),
                          ],
                        ),
                      ),
                    );
                  } else {
                    items.add(
                      PopupMenuItem(
                        value: _SortMenuAction.toggleCreatedAt,
                        child: Row(
                          children: const [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 8),
                            Text('Newest'),
                          ],
                        ),
                      ),
                    );
                  }
                  return items;
                },
              ),
            ],
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
                          ? () {
                             setState(() {
                               _searchQuery = '';
                               _searchController.clear();
                             });
                             widget.onPlayerSelected!(player);
                          } 
                          : null,
                      showScores: true,
                      compact: true,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

enum SortType {
  name,
  score,
  createdAt,
}

enum _SortMenuAction {
  toggleName,
  toggleScore,
  toggleCreatedAt,
}
