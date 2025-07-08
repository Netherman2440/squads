import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squads/pages/player_detail_page.dart';
import '../services/player_service.dart';
import '../services/squad_service.dart';
import '../services/message_service.dart';
import '../models/player.dart';
import '../models/position.dart';
import '../widgets/player_widget.dart';
import '../widgets/create_player_widget.dart';
import '../state/user_state.dart';
import '../utils/permission_utils.dart';
import '../widgets/players_list_widget.dart';
import '../state/players_state.dart';
import '../state/squad_state.dart';
import '../state/matches_state.dart';

class PlayersPage extends ConsumerStatefulWidget {
  final String squadId;

  final String ownerId;

  const PlayersPage({
    Key? key,
    required this.squadId,

    required this.ownerId,
  }) : super(key: key);

  @override
  ConsumerState<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends ConsumerState<PlayersPage> {
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _ensureSquadLoaded();
    _loadPlayers();
  }

  Future<void> _ensureSquadLoaded() async {
    final squadState = ref.read(squadProvider);
    if (squadState.squad == null) {
      setState(() { _isLoading = true; });
      try {
        final squadDetail = await SquadService.instance.getSquad(widget.squadId);
        ref.read(squadProvider.notifier).setSquad(squadDetail);
        ref.read(playersProvider.notifier).setPlayers(squadDetail.players);
        ref.read(matchesProvider.notifier).setMatches(squadDetail.matches);
      } catch (e) {
        // Możesz dodać obsługę błędów jeśli chcesz
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final squadState = ref.watch(squadProvider);
    final playersState = ref.watch(playersProvider);
    final userId = ref.watch(userSessionProvider).user?.userId ?? '';
    final canManagePlayers = squadState.isOwner(userId);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gracze - ${squadState.squad?.name ?? ''}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlayers,
          ),
        ],
      ),
      body: _buildBody(playersState),
      floatingActionButton: canManagePlayers
          ? FloatingActionButton(
              onPressed: () => _showAddPlayerDialog(context),
              child: const Icon(Icons.add),
              tooltip: 'Dodaj gracza',
            )
          : null,
    );
  }

  Widget _buildBody(PlayersState playersState) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    if (playersState.players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Brak graczy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Użyj przycisku floating button aby dodać pierwszego gracza',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlayers,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: PlayersListWidget(
          players: playersState.players,
          onPlayerSelected: _onPlayerTap,
          allowAdd: false,
          allowSelect: true,
        ),
      ),
    );
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
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onPlayerTap(Player player) {
    // TODO: Navigate to player details page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerDetailPage(player: player),
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: CreatePlayerWidget(
              squadId: ref.read(squadProvider).squad?.squadId ?? widget.squadId,
              onPlayerCreated: () {
                Navigator.of(context).pop();
                _loadPlayers();
              },
            ),
          ),
        );
      },
    );
  }
} 