import 'package:flutter/material.dart';
import 'package:squads/models/match.dart';
import 'package:squads/models/player.dart';
import 'package:squads/models/position.dart';
import 'package:squads/widgets/player_widget.dart';
import 'package:squads/widgets/players_list_widget.dart';
import 'package:squads/services/match_service.dart';
import 'package:squads/services/player_service.dart';
import 'package:squads/pages/match_history_page.dart';
import 'package:squads/pages/player_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squads/state/squad_state.dart';
import 'package:squads/state/user_state.dart';

class MatchPage extends ConsumerStatefulWidget {
  final String squadId;
  final String matchId;

  const MatchPage({
    Key? key,
    required this.squadId,
    required this.matchId,
  }) : super(key: key);

  @override
  ConsumerState<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends ConsumerState<MatchPage> {
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
  bool _isEditingTeams = false; // Whether admin is editing teams
  bool get _isOwner {
    final squadState = ref.watch(squadProvider);
    final userId = ref.watch(userSessionProvider).user?.userId ?? '';
    return squadState.isOwner(userId);
  }

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
    if (!_isOwner) return;
    setState(() {
      _isDirty = true;
    });
  }

  void _onScoreChanged() {
    if (!_isOwner) return;
    _onAnyChange();
  }

  void _onTeamsChanged(List<Player> teamA, List<Player> teamB) {
    if (!_isOwner) return;
    setState(() {
      _teamAPlayers = List<Player>.from(teamA);
      _teamBPlayers = List<Player>.from(teamB);
    });
    _onAnyChange();
  }

  void _addPlayerToTeam(bool toTeamA) async {
    if (!_isOwner) return;
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
    if (!_isOwner) return;
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
    if (!_isOwner) return;
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
    if (!_isOwner) return;
    setState(() {
      _teamAPlayers.removeWhere((p) => p.playerId == player.playerId);
      _teamBPlayers.removeWhere((p) => p.playerId == player.playerId);
    });
    _onAnyChange();
  }

  void _onPlayerTap(Player player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerDetailPage(player: player),
      ),
    );
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
    if (!_isOwner) return;
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
    if (!_isOwner) return;
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
        _isEditingTeams = false;
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

  int _getTeamScore(List<Player> players) {
    return (players.fold<double>(0, (sum, p) => sum + (p.score ?? 0))).toInt();
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
    const double maxListHeight = 1200; // increased for more players and scroll
    // Calculate dynamic height for player lists section
    int maxPlayers = _teamAPlayers.length > _teamBPlayers.length ? _teamAPlayers.length : _teamBPlayers.length;
    double playerListHeight = (maxPlayers * 50).clamp(200, 800).toDouble();
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Mecz ${ _matchDetail!.createdAt.day}.${ _matchDetail!.createdAt.month}.${ _matchDetail!.createdAt.year}',
          ),
          actions: [
            if (_isOwner && !_hasResult)
              IconButton(
                icon: Icon(_isEditingTeams ? Icons.check : Icons.edit),
                tooltip: _isEditingTeams ? 'Zakończ edycję składu' : 'Edytuj skład',
                onPressed: () {
                  setState(() {
                    _isEditingTeams = !_isEditingTeams;
                  });
                },
              ),
            if (_isOwner)
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete match',
                onPressed: _onDelete,
              ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _teamAName,
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Total score: ${_getTeamScore(_teamAPlayers)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
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
                                        enabled: _isOwner, // score is editable only for owner
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
                                        enabled: _isOwner, // score is editable only for owner
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _teamBName,
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Total score: ${_getTeamScore(_teamBPlayers)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Player lists row (dynamic height)
                    SizedBox(
                      height: playerListHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlayerList(_teamAPlayers, true, maxListHeight, enabled: !_hasResult),
                          const SizedBox(width: 12),
                          _buildPlayerList(_teamBPlayers, false, maxListHeight, enabled: !_hasResult),
                        ],
                      ),
                    ),
                    // Statistics section (always visible)
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
                    // Test widgets for scroll
                    const SizedBox(height: 40),
                    Container(
                      height: 80,
                      width: double.infinity,
                      color: Colors.amber,
                      alignment: Alignment.center,
                      child: const Text('Test widget 1 (scrollable)', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 80,
                      width: double.infinity,
                      color: Colors.lightBlue,
                      alignment: Alignment.center,
                      child: const Text('Test widget 2 (scrollable)', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 80,
                      width: double.infinity,
                      color: Colors.green,
                      alignment: Alignment.center,
                      child: const Text('Test widget 3 (scrollable)', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            if (!_hasResult) _buildTrashTarget(),
          ],
        ),
        floatingActionButton: _isDirty && _isOwner
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
    final canEdit = _isOwner && !_hasResult && _isEditingTeams;
    final canAdd = canEdit;
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
                    onWillAccept: (player) => canEdit && player != null && !players.any((p) => p.playerId == player.playerId),
                    onAcceptWithDetails: (details) => canEdit ? _movePlayer(details.data, isTeamA) : null,
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
                            if (canEdit) {
                              return Draggable<Player>(
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
                                      showScores: true,
                                      compact: true,
                                    ),
                                  ),
                                ),
                                child: PlayerWidget(
                                  player: player,
                                  onTap: null,
                                  showScores: true,
                                  compact: true,
                                ),
                                onDragStarted: () => _onPlayerDragStarted(player),
                                onDragEnd: (_) => _onPlayerDragEnded(),
                              );
                            } else {
                              return PlayerWidget(
                                player: player,
                                onTap: () => _onPlayerTap(player),
                                showScores: true,
                                compact: true,
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (canAdd)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _addPlayerToTeam(isTeamA),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Center(
                            child: Icon(Icons.add, size: 20, color: Colors.grey[700]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrashTarget() {
    if (_draggedPlayer == null || !_isOwner) return const SizedBox.shrink();
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
