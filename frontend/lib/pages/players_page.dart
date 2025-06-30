import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/player_service.dart';
import '../services/squad_service.dart';
import '../services/message_service.dart';
import '../models/player.dart';
import '../models/position.dart';
import '../widgets/player_widget.dart';
import '../widgets/create_player_widget.dart';
import '../state/user_state.dart';
import '../utils/permission_utils.dart';

class PlayersPage extends ConsumerStatefulWidget {
  final String squadId;
  final String squadName;
  final String ownerId;

  const PlayersPage({
    Key? key,
    required this.squadId,
    required this.squadName,
    required this.ownerId,
  }) : super(key: key);

  @override
  ConsumerState<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends ConsumerState<PlayersPage> {
  List<Player> _players = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userSessionProvider);
    final canManagePlayers = PermissionUtils.canManagePlayers(userState, widget.ownerId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gracze - ${widget.squadName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlayers,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: canManagePlayers
          ? FloatingActionButton(
              onPressed: () => _showAddPlayerDialog(context),
              child: const Icon(Icons.add),
              tooltip: 'Dodaj gracza',
            )
          : null,
    );
  }

  Widget _buildBody() {
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

    if (_players.isEmpty) {
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
        child: ListView.builder(
          itemCount: _players.length,
          itemBuilder: (context, index) {
            final player = _players[index];
            return PlayerWidget(
              player: player,
              onTap: () => _onPlayerTap(player),
              showScores: true,
            );
          },
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
      final players = await PlayerService.instance.getPlayers(widget.squadId);
      
      setState(() {
        _players = players;
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
    // For now, just allow tapping without showing message
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
                _loadPlayers();
              },
            ),
          ),
        );
      },
    );
  }
} 