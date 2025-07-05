import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/match_service.dart';
import '../services/message_service.dart';
import '../services/squad_service.dart';
import '../models/match.dart';
import '../state/user_state.dart';
import '../state/players_state.dart';
import '../state/matches_state.dart';
import '../state/squad_state.dart';
import '../utils/permission_utils.dart';
import 'match_page.dart';
import 'squad_page.dart';
import 'draft_page.dart';

class MatchHistoryPage extends ConsumerStatefulWidget {
  final String squadId;
  final String squadName;
  final String ownerId;

  const MatchHistoryPage({
    Key? key,
    required this.squadId,
    required this.squadName,
    required this.ownerId,
  }) : super(key: key);

  @override
  ConsumerState<MatchHistoryPage> createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends ConsumerState<MatchHistoryPage> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ensureSquadLoaded();
    _loadMatches();
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
    final matchesState = ref.watch(matchesProvider);
    final userId = ref.watch(userSessionProvider).user?.userId ?? '';
    final canManageMatches = squadState.isOwner(userId);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Match History - ${squadState.squad?.name ?? ''}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => SquadPage(squadId: widget.squadId),
              ),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: _buildBody(matchesState),
      floatingActionButton: canManageMatches
          ? FloatingActionButton(
              onPressed: () => _navigateToDraft(context),
              child: const Icon(Icons.add),
              tooltip: 'Utwórz nowy mecz',
            )
          : null,
    );
  }

  Widget _buildBody(MatchesState matchesState) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Failed to load matches'),
            SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMatches,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (matchesState.matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No matches found'),
            SizedBox(height: 8),
            Text('Create your first match to get started'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: matchesState.matches.length,
        itemBuilder: (context, index) {
          final match = matchesState.matches[index];
          return _buildMatchCard(match, context);
        },
      ),
    );
  }

  Widget _buildMatchCard(Match match, BuildContext context) {
    final formattedDate = _formatDateTime(match.createdAt);
    
    // Check if score is set (not null and not [0, 0] or empty)
    final hasScore = match.score != null && 
                    match.score!.isNotEmpty && 
                    (match.score!.length >= 2) && 
                    (match.score![0] != 0 || match.score![1] != 0);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchPage(
                squadId: widget.squadId,
                matchId: match.matchId,
              ),
            ),
          );
        },
        title: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Match #${match.matchId.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Row(
              children: [
                _buildScoreBox(
                  score: hasScore ? match.score![0].toString() : '',
                  isLeft: true,
                ),
                SizedBox(width: 8),
                Text(
                  '-',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(width: 8),
                _buildScoreBox(
                  score: hasScore ? match.score![1].toString() : '',
                  isLeft: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBox({required String score, required bool isLeft}) {
    final hasScore = score.isNotEmpty;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: hasScore 
          ? (isLeft ? Colors.blue.shade100 : Colors.red.shade100)
          : Colors.grey.shade200,
        border: Border.all(
          color: hasScore 
            ? (isLeft ? Colors.blue.shade300 : Colors.red.shade300)
            : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          hasScore ? score : '',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: hasScore 
              ? (isLeft ? Colors.blue.shade700 : Colors.red.shade700)
              : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final squadId = ref.read(squadProvider).squad?.squadId ?? widget.squadId;
      final matches = await MatchService.instance.getSquadMatches(squadId);
      ref.read(matchesProvider.notifier).setMatches(matches);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      MessageService.showError(context, 'Failed to load matches: $e');
    }
  }

  void _navigateToDraft(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DraftPage(
          squadId: widget.squadId,
          ownerId: widget.ownerId,
        ),
      ),
    );
  }
} 