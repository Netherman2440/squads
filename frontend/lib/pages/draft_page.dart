import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squads/models/player.dart';
import 'package:squads/models/draft.dart';
import 'package:squads/services/player_service.dart';
import 'package:squads/services/match_service.dart';
import 'package:squads/state/draft_state.dart';
import 'package:squads/state/user_state.dart';
import 'package:squads/state/players_state.dart';
import 'package:squads/state/squad_state.dart';

import 'package:squads/widgets/create_player_widget.dart';
import 'package:squads/services/message_service.dart';
import 'package:squads/pages/create_match_page.dart';
import 'package:squads/widgets/player_widget.dart';
import 'package:squads/widgets/players_list_widget.dart';


class DraftPage extends ConsumerStatefulWidget {
  final String squadId;
  final String ownerId;

  const DraftPage({
    super.key,
    required this.squadId,
    required this.ownerId,
  });

  @override
  ConsumerState<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends ConsumerState<DraftPage> {
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final squadId = ref.read(squadProvider).squad?.squadId ?? widget.squadId;
      final players = await PlayerService.instance.getPlayers(squadId);
      ref.read(playersProvider.notifier).setPlayers(players);
      final draftNotifier = ref.read(draftProvider.notifier);
      draftNotifier.setAllPlayers(players);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPlayerCreated() {
    _loadPlayers();
  }

  List<Player> _getFilteredPlayers(List<Player> players) {
    if (_searchQuery.isEmpty) return players;
    return players.where((player) =>
        player.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _showAddPlayerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: CreatePlayerWidget(
              squadId: widget.squadId,
              onPlayerCreated: () {
                Navigator.of(context).pop();
                _onPlayerCreated();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _createDraft() async {
    final draftState = ref.read(draftProvider);
    if (draftState.selectedPlayers.isEmpty) {
      MessageService.showError(context, 'Wybierz graczy do draftu');
      return;
    }

    try {
      final drafts = await MatchService.instance.drawTeams(widget.squadId, draftState.selectedPlayers);
      
      if (mounted) {
        MessageService.showSuccess(context, 'Draft został utworzony!');

        // Reset draft state
        ref.read(draftProvider.notifier).clearSelectedPlayers();

        // Navigate to create match page with drafts
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateMatchPage(
              squadId: widget.squadId,
              ownerId: widget.ownerId,
              drafts: drafts,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        MessageService.showError(context, 'Błąd podczas tworzenia draftu: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftState = ref.watch(draftProvider);
    final squadState = ref.watch(squadProvider);
    final userId = ref.watch(userSessionProvider).user?.userId ?? '';
    final canManagePlayers = squadState.isOwner(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tworzenie składu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Nie udało się załadować graczy',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPlayers,
                        child: const Text('Spróbuj ponownie'),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Available players column (left)
                    Expanded(
                      flex: 1,
                      child: Stack(
                        children: [
                          Card(
                            margin: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [

                                Expanded(
                                  child: PlayersListWidget(
                                    players: _getFilteredPlayers(draftState.availablePlayers),
                                    onPlayerSelected: canManagePlayers
                                        ? (player) => ref.read(draftProvider.notifier).addPlayer(player)
                                        : null,
                                    allowAdd: false,
                                    allowSelect: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canManagePlayers)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton(
                                onPressed: () => _showAddPlayerDialog(context),
                                child: const Icon(Icons.add),
                                tooltip: 'Dodaj gracza',
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Selected players column (right)
                    Expanded(
                      flex: 1,
                      child: Stack(
                        children: [
                          Card(
                            margin: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Wybrani gracze (${draftState.selectedPlayers.length})',
                                          style: Theme.of(context).textTheme.titleMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: draftState.selectedPlayers.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Brak wybranych graczy',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: draftState.selectedPlayers.length,
                                          itemBuilder: (context, index) {
                                            final player = draftState.selectedPlayers[index];
                                            return PlayerWidget(
                                              player: player,
                                              onTap: canManagePlayers
                                                  ? () => ref.read(draftProvider.notifier).removePlayer(player)
                                                  : null,
                                              showScores: true,
                                              compact: true,
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                          if (canManagePlayers && draftState.selectedPlayers.isNotEmpty)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton.extended(
                                onPressed: _createDraft,
                                label: const Text('Draft'),
                                icon: const Icon(Icons.shuffle),
                                tooltip: 'Utwórz draft',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
} 