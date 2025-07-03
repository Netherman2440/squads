import 'package:flutter/material.dart';
import 'package:frontend/models/match.dart';
import 'package:frontend/models/player.dart';
import 'package:frontend/widgets/match_widget.dart';
import 'package:frontend/widgets/players_list_widget.dart';

class MatchPage extends StatefulWidget {
  final MatchDetailResponse matchDetail;
  final List<Player> allPlayers;

  const MatchPage({
    Key? key,
    required this.matchDetail,
    required this.allPlayers,
  }) : super(key: key);

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  late List<Player> _teamAPlayers;
  late List<Player> _teamBPlayers;
  late String _teamAName;
  late String _teamBName;
  late List<int> _score;
  bool _hasResult = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _teamAPlayers = List<Player>.from(widget.matchDetail.teamA.players);
    _teamBPlayers = List<Player>.from(widget.matchDetail.teamB.players);
    _teamAName = 'FC Biali';
    _teamBName = 'Czarni United';
    _score = [widget.matchDetail.teamA.score ?? 0, widget.matchDetail.teamB.score ?? 0];
    _hasResult = false;
  }

  void _onScoreChanged(int team, String value) {
    final parsed = int.tryParse(value) ?? 0;
    setState(() {
      _score[team] = parsed;
      _isDirty = true;
    });
  }

  void _onTeamsChanged(List<Player> teamA, List<Player> teamB) {
    setState(() {
      _teamAPlayers = List<Player>.from(teamA);
      _teamBPlayers = List<Player>.from(teamB);
      _isDirty = true;
    });
  }

  void _addPlayerToTeam(bool toTeamA) async {
    final availablePlayers = widget.allPlayers.where((p) =>
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
        _isDirty = true;
      });
    }
  }

  void _onSave() async {
    if (!_hasResult && (_score[0] > 0 || _score[1] > 0)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Potwierdź wynik'),
          content: const Text('Po zapisaniu wyniku nie będzie można już zmieniać składów. Kontynuować?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Zapisz'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    // TODO: Wyślij zmiany do backendu
    setState(() {
      _hasResult = true;
      _isDirty = false;
    });
    // Możesz dodać snackbar lub nawigację
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mecz')), 
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: TextField(
                    enabled: !_hasResult,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Wynik Team A'),
                    controller: TextEditingController(text: _score[0].toString()),
                    onChanged: (v) => _onScoreChanged(0, v),
                  ),
                ),
                const SizedBox(width: 24),
                const Text(':', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 24),
                Flexible(
                  child: TextField(
                    enabled: !_hasResult,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Wynik Team B'),
                    controller: TextEditingController(text: _score[1].toString()),
                    onChanged: (v) => _onScoreChanged(1, v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MatchWidget(
                  teamAPlayers: _teamAPlayers,
                  teamBPlayers: _teamBPlayers,
                  teamAName: _teamAName,
                  teamBName: _teamBName,
                  canEditTeams: !_hasResult,
                  showScores: true,
                  onPlayerTap: null,
                ),
                if (!_hasResult)
                  Positioned(
                    left: 16,
                    top: 16,
                    child: FloatingActionButton(
                      heroTag: 'addA',
                      onPressed: () => _addPlayerToTeam(true),
                      child: const Icon(Icons.add),
                      tooltip: 'Dodaj gracza do Team A',
                    ),
                  ),
                if (!_hasResult)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: FloatingActionButton(
                      heroTag: 'addB',
                      onPressed: () => _addPlayerToTeam(false),
                      child: const Icon(Icons.add),
                      tooltip: 'Dodaj gracza do Team B',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isDirty
          ? FloatingActionButton.extended(
              onPressed: _onSave,
              label: const Text('Save'),
              icon: const Icon(Icons.save),
            )
          : null,
    );
  }
}
