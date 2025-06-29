import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/squad_state.dart';
import '../state/user_state.dart';
import '../services/message_service.dart';
import '../utils/permission_utils.dart';
import '../models/models.dart';
import '../services/squad_service.dart';

class SquadPage extends ConsumerStatefulWidget {
  final String squadId;

  const SquadPage({Key? key, required this.squadId}) : super(key: key);

  @override
  ConsumerState<SquadPage> createState() => _SquadPageState();
}

class _SquadPageState extends ConsumerState<SquadPage> {
  SquadDetailResponse? _squad;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSquad();
  }

  @override
  Widget build(BuildContext context) {
    final squadState = ref.watch(squadProvider);
    final userState = ref.watch(userSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_squad?.name ?? 'Loading Squad...'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (PermissionUtils.isOwner(userState, squadState))
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editSquad(context),
            ),
        ],
      ),
      body: _buildBody(context, userState, squadState),
    );
  }

  Widget _buildBody(BuildContext context, UserSessionState userState, SquadState squadState) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_squad == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Squad not found or access denied'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSquad,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSquadInfo(),
          SizedBox(height: 24),
          _buildPermissionInfo(userState, squadState),
          SizedBox(height: 24),
          _buildActionButtons(context, userState, squadState),
        ],
      ),
    );
  }

  Widget _buildSquadInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Squad Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow('Name', _squad!.name),
            _buildInfoRow('Created', _squad!.createdAt.toString().split(' ')[0]),
            _buildInfoRow('Players', _squad!.playersCount.toString()),
            _buildInfoRow('Owner ID', _squad!.ownerId),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionInfo(UserSessionState userState, SquadState squadState) {
    final isOwner = PermissionUtils.isOwner(userState, squadState);
    final canEdit = PermissionUtils.canEdit(userState, squadState);
    final canManagePlayers = PermissionUtils.canManagePlayers(userState, squadState);
    final canManageMatches = PermissionUtils.canManageMatches(userState, squadState);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildPermissionRow('Owner', isOwner),
            _buildPermissionRow('Can Edit', canEdit),
            _buildPermissionRow('Can Manage Players', canManagePlayers),
            _buildPermissionRow('Can Manage Matches', canManageMatches),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserSessionState userState, SquadState squadState) {
    final canManagePlayers = PermissionUtils.canManagePlayers(userState, squadState);
    final canManageMatches = PermissionUtils.canManageMatches(userState, squadState);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (canManagePlayers)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToPlayers(context),
                  icon: Icon(Icons.people),
                  label: Text('Manage Players'),
                ),
              ),
            SizedBox(height: 8),
            if (canManageMatches)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToMatches(context),
                  icon: Icon(Icons.sports_soccer),
                  label: Text('Manage Matches'),
                ),
              ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _navigateToSquadDetails(context),
                icon: Icon(Icons.info),
                label: Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String permission, bool hasPermission) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(permission),
        ],
      ),
    );
  }

  void _loadSquad() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final squadDetail = await SquadService.instance.getSquad(widget.squadId);
      
      setState(() {
        _squad = squadDetail;
        _isLoading = false;
      });
      
      // Set squad in state after loading
      ref.read(squadProvider.notifier).setSquad(squadDetail);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      MessageService.showError(context, e.toString());
    }
  }

  void _editSquad(BuildContext context) {
    MessageService.showInfo(context, 'Edit squad functionality coming soon');
  }

  void _navigateToPlayers(BuildContext context) {
    MessageService.showInfo(context, 'Players page coming soon');
  }

  void _navigateToMatches(BuildContext context) {
    MessageService.showInfo(context, 'Matches page coming soon');
  }

  void _navigateToSquadDetails(BuildContext context) {
    MessageService.showInfo(context, 'Squad details page coming soon');
  }
} 