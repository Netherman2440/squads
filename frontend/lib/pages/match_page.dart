import 'package:flutter/material.dart';
import 'package:frontend/models/match.dart';
import 'package:frontend/models/player.dart';
import 'package:frontend/models/position.dart';
import 'package:frontend/widgets/player_widget.dart';
import 'package:frontend/widgets/players_list_widget.dart';
import 'package:frontend/services/match_service.dart';
import 'package:frontend/services/player_service.dart';
import 'package:frontend/pages/match_history_page.dart';

class MatchPage extends StatefulWidget {
  final String squadId;
  final String matchId;

  const MatchPage({
    Key? key,
    required this.squadId,
    required this.matchId,
  }) : super(key: key);

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  MatchDetailResponse? _matchDetail;
  List<Player>? _allPlayers;
  bool _isLoading = true;
  String? _error;
  late List<Player> _teamAPlayers;
  late List<Player> _teamBPlayers;
  late String _teamAName;
  late String _teamBName;
  late TextEditingController _scoreAController;
  late TextEditingController _scoreBController;
  bool _hasResult = false;
  bool _isDirty = false;
  String? _squadName;
  String? _ownerId;
  Player? _draggedPlayer;

  @override
  void initState() {
    super.initState();
    _scoreAController = TextEditingController();
    _scoreBController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _scoreAController.dispose();
    _scoreBController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _squadName ??= args['squadName'] as String?;
      _ownerId ??= args['ownerId'] as String?;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final matchDetail = await MatchService.instance.getMatch(widget.squadId, widget.matchId);
      final allPlayers = await PlayerService.instance.getPlayers(widget.squadId);
      setState(() {
        _matchDetail = matchDetail;
        _allPlayers = allPlayers;
        _teamAPlayers = List<Player>.from(matchDetail.teamA.players);
        _teamBPlayers = List<Player>.from(matchDetail.teamB.players);
        _teamAName = matchDetail.teamA.name ?? 'FC Biali';
        _teamBName = matchDetail.teamB.name ?? 'Czarni United';
        _scoreAController.text = matchDetail.teamA.score?.toString() ?? '';
        _scoreBController.text = matchDetail.teamB.score?.toString() ?? '';
        _hasResult = matchDetail.teamA.score != null && matchDetail.teamB.score != null;
        _isDirty = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onAnyChange() {
    setState(() {
      _isDirty = true;
    });
  }

  void _onScoreChanged() {
    _onAnyChange();
  }

  void _onTeamsChanged(List<Player> teamA, List<Player> teamB) {
    setState(() {
      _teamAPlayers = List<Player>.from(teamA);
      _teamBPlayers = List<Player>.from(teamB);
    });
    _onAnyChange();
  }

  void _addPlayerToTeam(bool toTeamA) async {
    final availablePlayers = _allPlayers!.where((p) =>
      !_teamAPlayers.any((a) => a.playerId == p.playerId) &&
      !_teamBPlayers.any((b) => b.playerId == p.playerId)
    ).toList();
    final Player? selected = await showDialog<Player>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          height: 500,
          child: PlayersListWidget(
            players: availablePlayers,
            onPlayerSelected: (player) => Navigator.of(context).pop(player),
            allowAdd: false,
            allowSelect: true,
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        if (toTeamA) {
          _teamAPlayers.add(selected);
        } else {
          _teamBPlayers.add(selected);
        }
      });
      _onAnyChange();
    }
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
    _onAnyChange();
  }

  void _onPlayerDragStarted(Player player) {
    setState(() {
      _draggedPlayer = player;
    });
  }

  void _onPlayerDragEnded() {
    setState(() {
      _draggedPlayer = null;
    });
  }

  void _removePlayerFromTeams(Player player) {
    setState(() {
      _teamAPlayers.removeWhere((p) => p.playerId == player.playerId);
      _teamBPlayers.removeWhere((p) => p.playerId == player.playerId);
    });
    _onAnyChange();
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MatchHistoryPage(
          squadId: widget.squadId,
          squadName: _squadName ?? '',
          ownerId: _ownerId ?? '',
        ),
      ),
      (route) => false,
    );
    return false;
  }

  void _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete match'),
        content: const Text('Are you sure you want to delete this match? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await MatchService.instance.deleteMatch(widget.squadId, widget.matchId);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MatchHistoryPage(
                squadId: widget.squadId,
                squadName: _squadName ?? '',
                ownerId: _ownerId ?? '',
              ),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void _onSave() async {
    final scoreA = _scoreAController.text.trim().isEmpty ? null : int.tryParse(_scoreAController.text.trim());
    final scoreB = _scoreBController.text.trim().isEmpty ? null : int.tryParse(_scoreBController.text.trim());
    if ((scoreA == null && scoreB != null) || (scoreA != null && scoreB == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Musisz podać wynik obu drużyn lub żadnej!')),
      );
      return;
    }
    try {
      await MatchService.instance.updateMatch(
        widget.squadId,
        widget.matchId,
        teamAId: _matchDetail!.teamA.teamId,
        teamBId: _matchDetail!.teamB.teamId,
        teamAPlayers: !_hasResult ? _teamAPlayers : null,
        teamBPlayers: !_hasResult ? _teamBPlayers : null,
        teamAScore: (scoreA != null && scoreB != null) ? scoreA : null,
        teamBScore: (scoreA != null && scoreB != null) ? scoreB : null,
      );
      await _loadData();
      setState(() {
        _isDirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zmiany zapisane!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zapisu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error:  $_error')),
      );
    }
    const double maxListHeight = 520; // increased for 6 players
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mecz'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete match',
              onPressed: _onDelete,
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Column(
                children: [
                  // Team names and score row
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _teamAName,
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 120,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: SizedBox(
                                    width: 40,
                                    child: TextField(
                                      enabled: true, // score is always editable
                                      controller: _scoreAController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '-',
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (_) => _onScoreChanged(),
                                    ),
                                  ),
                                ),
                                const Text(' : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                                Flexible(
                                  child: SizedBox(
                                    width: 40,
                                    child: TextField(
                                      enabled: true, // score is always editable
                                      controller: _scoreBController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '-',
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (_) => _onScoreChanged(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _teamBName,
                            textAlign: TextAlign.left,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Player lists row
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlayerList(_teamAPlayers, true, maxListHeight, enabled: !_hasResult),
                        const SizedBox(width: 12),
                        _buildPlayerList(_teamBPlayers, false, maxListHeight, enabled: !_hasResult),
                      ],
                    ),
                  ),
                  if (!_hasResult)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Opacity(
                        opacity: 0.7,
                        child: Card(
                          elevation: 0,
                          color: Colors.grey.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart, size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'H2H (Head-to-Head)',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Coming soon...',
                                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!_hasResult) _buildTrashTarget(),
          ],
        ),
        floatingActionButton: _isDirty
            ? FloatingActionButton.extended(
                onPressed: _onSave,
                label: const Text('Save'),
                icon: const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  Widget _buildPlayerList(List<Player> players, bool isTeamA, double maxHeight, {bool enabled = true}) {
    final canAdd = enabled;
    return Expanded(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: DragTarget<Player>(
                    onWillAccept: (player) => canAdd && player != null && !players.any((p) => p.playerId == player.playerId),
                    onAcceptWithDetails: (details) => enabled ? _movePlayer(details.data, isTeamA) : null,
                    builder: (context, candidateData, rejectedData) {
                      final isActive = candidateData.isNotEmpty;
                      return Container(
                        decoration: isActive
                            ? BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                border: Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: ListView.builder(
                          itemCount: players.length,
                          itemBuilder: (context, idx) {
                            final player = players[idx];
                            return enabled
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
                                            showScores: true,
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
                                          showScores: true,
                                        ),
                                      ),
                                    ),
                                    child: PlayerWidget(
                                      player: player,
                                      onTap: null,
                                      showScores: true,
                                    ),
                                    onDragStarted: () => _onPlayerDragStarted(player),
                                    onDragEnd: (_) => _onPlayerDragEnded(),
                                  )
                                : PlayerWidget(
                                    player: player,
                                    onTap: null,
                                    showScores: true,
                                  );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (canAdd)
              Positioned(
                bottom: 8,
                right: 8,
                child: FloatingActionButton(
                  mini: true,
                  heroTag: isTeamA ? 'addA' : 'addB',
                  onPressed: enabled ? () => _addPlayerToTeam(isTeamA) : null,
                  child: const Icon(Icons.add),
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black54,
                  elevation: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrashTarget() {
    if (_draggedPlayer == null) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: DragTarget<Player>(
        onWillAccept: (player) => true,
        onAccept: (player) {
          _removePlayerFromTeams(player);
          _onPlayerDragEnded();
        },
        builder: (context, candidateData, rejectedData) {
          final isActive = candidateData.isNotEmpty;
          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isActive ? 80 : 64,
              height: isActive ? 80 : 64,
              decoration: BoxDecoration(
                color: isActive ? Colors.red.shade300 : Colors.grey.shade300,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Icon(Icons.delete, size: isActive ? 44 : 36, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
