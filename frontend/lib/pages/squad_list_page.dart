import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/squad_service.dart';
import '../services/message_service.dart';
import '../models/squad.dart';
import '../state/user_state.dart';
import 'squad_page.dart';

class SquadListPage extends ConsumerStatefulWidget {
  const SquadListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SquadListPage> createState() => _SquadListPageState();
}

class _SquadListPageState extends ConsumerState<SquadListPage> {
  List<Squad> _squads = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSquads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Squads'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSquads,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _createNewSquad(context),
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
            Text('Failed to load squads'),
            SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSquads,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_squads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No squads found'),
            SizedBox(height: 8),
            Text('Create your first squad to get started'),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _createNewSquad(context),
              icon: Icon(Icons.add),
              label: Text('Create Squad'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSquads,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _squads.length,
        itemBuilder: (context, index) {
          final squad = _squads[index];
          return _buildSquadCard(squad);
        },
      ),
    );
  }

  Widget _buildSquadCard(Squad squad) {
    final isOwner = squad.ownerId == ref.read(userSessionProvider).user?.userId;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToSquad(squad),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      squad.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOwner)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Owner',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${squad.playersCount} players',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Created ${_formatDate(squad.createdAt)}',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _loadSquads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final squadService = ref.read(squadServiceProvider);
      final squads = await squadService.getAllSquads();
      
      setState(() {
        _squads = squads;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToSquad(Squad squad) {
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SquadPage(squadId: squad.squadId),
      ),
    );
  }

  void _createNewSquad(BuildContext context) {
    MessageService.showInfo(context, 'Create squad functionality coming soon');
  }
} 