import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/draft.dart';
import 'package:frontend/models/player.dart';
import 'package:frontend/pages/match_page.dart';
import 'package:frontend/services/match_service.dart';
import 'package:frontend/services/message_service.dart';
import 'package:frontend/widgets/match_widget.dart';

class CreateMatchPage extends ConsumerStatefulWidget {
  final String squadId;
  final String ownerId;
  final List<Draft> drafts;

  const CreateMatchPage({
    super.key,
    required this.squadId,
    required this.ownerId,
    required this.drafts,
  });

  @override
  ConsumerState<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends ConsumerState<CreateMatchPage> {
  int _selectedDraftIndex = 0;
  late List<Draft> _originalDrafts;
  late List<Draft> _currentDrafts;
  late TextEditingController _teamAController;
  late TextEditingController _teamBController;

  @override
  void initState() {
    super.initState();
    _originalDrafts = widget.drafts.map((d) => Draft(
      teamA: List.from(d.teamA),
      teamB: List.from(d.teamB),
    )).toList();
    _currentDrafts = _originalDrafts.map((d) => Draft(
      teamA: List.from(d.teamA),
      teamB: List.from(d.teamB),
    )).toList();
    _teamAController = TextEditingController(text: 'FC Biali');
    _teamBController = TextEditingController(text: 'Czarni United');
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  void _switchDraft(int newIndex) {
    setState(() {
      // Reset current draft to original when switching
      _currentDrafts[_selectedDraftIndex] = Draft(
        teamA: List.from(_originalDrafts[_selectedDraftIndex].teamA),
        teamB: List.from(_originalDrafts[_selectedDraftIndex].teamB),
      );
      _selectedDraftIndex = newIndex;
    });
  }

  void _onTeamChanged(List<Player> teamA, List<Player> teamB) {
    setState(() {
      _currentDrafts[_selectedDraftIndex] = Draft(
        teamA: List.from(teamA),
        teamB: List.from(teamB),
      );
    });
  }

  void _createMatch() async {
    final selectedDraft = _currentDrafts[_selectedDraftIndex];
    final teamAName = _teamAController.text;
    final teamBName = _teamBController.text;
    try {
      final match = await MatchService.instance.createMatch(
        widget.squadId,
        selectedDraft,
        teamAName: teamAName,
        teamBName: teamBName,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchPage(
            squadId: widget.squadId,
            matchId: match.matchId,
          ),
        ),
      );
    } catch (e) {
      MessageService.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.drafts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wyniki draftu'),
        ),
        body: const Center(
          child: Text('Brak dostępnych draftów'),
        ),
      );
    }

    final selectedDraft = _currentDrafts[_selectedDraftIndex];
    final draftCount = _currentDrafts.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wyniki draftu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () {
                    final newIndex = (_selectedDraftIndex - 1 + draftCount) % draftCount;
                    _switchDraft(newIndex);
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Draft ${_selectedDraftIndex + 1} z $draftCount',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () {
                    final newIndex = (_selectedDraftIndex + 1) % draftCount;
                    _switchDraft(newIndex);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MatchWidget(
                teamAPlayers: selectedDraft.teamA,
                teamBPlayers: selectedDraft.teamB,
                teamAName: _teamAController.text,
                teamBName: _teamBController.text,
                showScores: true,
                canEditTeams: true,
                onPlayerTap: (_) {},
                teamAController: _teamAController,
                teamBController: _teamBController,
                onTeamsChanged: _onTeamChanged, // <-- ensure this is passed
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createMatch,
        label: const Text('Create Match'),
        icon: const Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
} 
