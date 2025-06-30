import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/player_service.dart';
import '../services/squad_service.dart';
import '../services/message_service.dart';
import '../models/player.dart';
import '../models/position.dart';
import '../widgets/player_list_widget.dart';
import '../state/user_state.dart';

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
  
  // Controllers for the add player dialog
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _playerScoreController = TextEditingController();
  Position? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _playerScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userSessionProvider).user;
    final isOwner = currentUser?.userId == widget.ownerId;

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
      floatingActionButton: isOwner
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
        child: PlayerListWidget(
          players: _players,
          onPlayerTap: _onPlayerTap,
          showScores: true,
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
    _playerNameController.clear();
    _playerScoreController.clear();
    _selectedPosition = null;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dodaj nowego gracza'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _playerNameController,
                decoration: const InputDecoration(
                  labelText: 'Imię gracza',
                  hintText: 'Wprowadź imię gracza',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (value) => _addPlayer(context),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _playerScoreController,
                decoration: const InputDecoration(
                  labelText: 'Score',
                  hintText: 'Wprowadź score gracza',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) => _addPlayer(context),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Position>(
                value: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'Pozycja',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Wybierz pozycję (opcjonalnie)'),
                items: Position.values.map((Position position) {
                  return DropdownMenuItem<Position>(
                    value: position,
                    child: Text(_getPositionDisplayName(position)),
                  );
                }).toList(),
                onChanged: (Position? newValue) {
                  setState(() {
                    _selectedPosition = newValue;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () => _addPlayer(context),
              child: const Text('Dodaj'),
            ),
          ],
        );
      },
    );
  }

  String _getPositionDisplayName(Position position) {
    switch (position) {
      case Position.none:
        return 'Brak pozycji';
      case Position.goalie:
        return 'Bramkarz';
      case Position.field:
        return 'Pole';
      case Position.defender:
        return 'Obrońca';
      case Position.midfielder:
        return 'Pomocnik';
      case Position.forward:
        return 'Napastnik';
    }
  }

  void _addPlayer(BuildContext context) async {
    final playerName = _playerNameController.text.trim();
    final scoreText = _playerScoreController.text.trim();
    
    if (playerName.isEmpty) {
      MessageService.showError(context, 'Proszę wprowadzić imię gracza');
      return;
    }
    
    if (scoreText.isEmpty) {
      MessageService.showError(context, 'Proszę wprowadzić score gracza');
      return;
    }
    
    int? score;
    try {
      score = int.parse(scoreText);
      if (score < 0) {
        MessageService.showError(context, 'Score nie może być ujemny');
        return;
      }
    } catch (e) {
      MessageService.showError(context, 'Score musi być liczbą całkowitą');
      return;
    }
    
    try {
      Navigator.of(context).pop(); // Close dialog
      
      // Show loading indicator
      MessageService.showInfo(context, 'Dodawanie gracza...');
      
      final position = _selectedPosition ?? Position.none;
      final playerResponse = await SquadService.instance.addPlayer(
        widget.squadId,
        playerName,
        score,
        position,
      );
      
      MessageService.showSuccess(context, 'Gracz "$playerName" został dodany pomyślnie!');
      
      // Reload players list
      await _loadPlayers();
      
    } catch (e) {
      MessageService.showError(context, 'Nie udało się dodać gracza: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _addNewPlayer(BuildContext context) {
    _showAddPlayerDialog(context);
  }
} 