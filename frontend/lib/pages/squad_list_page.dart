import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/squad_service.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../models/squad.dart';
import '../state/user_state.dart';
import '../state/squad_state.dart';
import 'squad_page.dart';
import 'auth_page.dart';

class SquadListPage extends ConsumerStatefulWidget {
  const SquadListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SquadListPage> createState() => _SquadListPageState();
}

class _SquadListPageState extends ConsumerState<SquadListPage> {
  List<Squad> _squads = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _squadNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSquads();
  }

  @override
  void dispose() {
    _squadNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userSession = ref.watch(userSessionProvider);
    final canCreateSquad = userSession.user != null;
    print(userSession.user);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('My Squads'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSquads,
          ),
          if (canCreateSquad)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _showCreateSquadDialog(context),
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: canCreateSquad ? FloatingActionButton(
        onPressed: () => _showCreateSquadDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Create new squad',
      ) : null,
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
    final userId = ref.read(userSessionProvider).user?.userId;
    final isOwner = squad.ownerId == userId;
    
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
      final squads = await SquadService.instance.getAllSquads();
      
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

  void _handleLogout() async {
    try {
      // Perform complete logout (clears both state and tokens)
      print('Logout');
      ref.read(userSessionProvider.notifier).logout();
      
      // Navigate back to auth page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
        (route) => false,
      );
      
      MessageService.showSuccess(context, 'Logged out successfully');
    } catch (e) {
      MessageService.showError(context, 'Logout failed: $e');
    }
  }

  void _showCreateSquadDialog(BuildContext context) {
    _squadNameController.clear();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New Squad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _squadNameController,
                decoration: InputDecoration(
                  labelText: 'Squad Name',
                  hintText: 'Enter squad name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (value) => _createSquad(context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _createSquad(context),
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _createSquad(BuildContext context) async {
    final squadName = _squadNameController.text.trim();
    
    if (squadName.isEmpty) {
      MessageService.showError(context, 'Please enter a squad name');
      return;
    }
    
    try {
      Navigator.of(context).pop(); // Close dialog
      
      // Show loading indicator
      MessageService.showInfo(context, 'Creating squad...');
      
      final squadResponse = await SquadService.instance.createSquad(squadName);
      
      MessageService.showSuccess(context, 'Squad "${squadName}" created successfully!');
      
      // Reload squads list
      await _loadSquads();
      
    } catch (e) {
      MessageService.showError(context, 'Failed to create squad: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _createNewSquad(BuildContext context) {
    _showCreateSquadDialog(context);
  }
} 