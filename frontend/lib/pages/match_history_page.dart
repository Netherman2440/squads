import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/match_service.dart';
import '../services/message_service.dart';
import '../models/match.dart';
import '../state/user_state.dart';

class MatchHistoryPage extends ConsumerStatefulWidget {
  final String squadId;
  final String squadName;

  const MatchHistoryPage({
    Key? key,
    required this.squadId,
    required this.squadName,
  }) : super(key: key);

  @override
  ConsumerState<MatchHistoryPage> createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends ConsumerState<MatchHistoryPage> {
  List<Match> _matches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match History - ${widget.squadName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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

    if (_matches.isEmpty) {
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
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final formattedDate = _formatDateTime(match.createdAt);
    
    // Check if score is set (not null and not [0, 0] or empty)
    final hasScore = match.score != null && 
                    match.score!.isNotEmpty && 
                    (match.score!.length >= 2) && 
                    (match.score![0] != 0 || match.score![1] != 0);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Date/Time - main element
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
            // Score boxes
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
      final matches = await MatchService.instance.getSquadMatches(widget.squadId);
      
      // Sort matches by creation date (newest first)
      matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _matches = matches;
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
} 