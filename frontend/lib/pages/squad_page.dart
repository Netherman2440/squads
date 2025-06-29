import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/user_state.dart';
import '../services/message_service.dart';
import '../utils/permission_utils.dart';
import '../models/models.dart';
import '../services/squad_service.dart';
import '../theme/app_theme.dart';
import 'players_page.dart';

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
    final userState = ref.watch(userSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_squad?.name ?? 'Loading Squad...'),
        backgroundColor: isDark ? AppColors.bgDark : AppColors.lightSurface,
        foregroundColor: isDark ? AppColors.text : AppColors.lightText,
        elevation: 0,
        actions: [
          if (PermissionUtils.isOwner(userState, _squad?.ownerId ?? ''))
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editSquad(context),
            ),
        ],
      ),
      body: _buildBody(context, userState, widget.squadId),
    );
  }

  Widget _buildBody(BuildContext context, UserSessionState userState, String squadId) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_squad == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'Squad not found or access denied',
              style: TextStyle(color: AppColors.textMuted),
            ),
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
          _buildMainSections(context, userState),
          SizedBox(height: 24),
          _buildStatisticsSection(),
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
            Row(
              children: [
                Icon(Icons.group, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Squad Information',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('Name', _squad!.name),
            _buildInfoRow('Created', _squad!.createdAt.toString().split(' ')[0]),
            _buildInfoRow('Players', _squad!.playersCount.toString()),
            _buildInfoRow('Matches', _squad!.matches.length.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSections(BuildContext context, UserSessionState userState) {
    return Row(
      children: [
        Expanded(
          child: _buildMainSection(
            context: context,
            title: 'Players',
            icon: Icons.people,
            color: AppColors.secondary,
            onTap: () => _navigateToPlayers(context),
            canAccess: PermissionUtils.canManagePlayers(userState, _squad!.ownerId),
            count: _squad!.playersCount,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMainSection(
            context: context,
            title: 'Matches',
            icon: Icons.sports_soccer,
            color: AppColors.success,
            onTap: () => _navigateToMatches(context),
            canAccess: PermissionUtils.canManageMatches(userState, _squad!.ownerId),
            count: _squad!.matches.length,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMainSection(
            context: context,
            title: 'Tournaments',
            icon: Icons.emoji_events,
            color: AppColors.warning,
            onTap: () => _navigateToTournaments(context),
            canAccess: true, // Tournaments will be available to all
            count: 0, // Coming soon
            isComingSoon: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMainSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool canAccess,
    required int count,
    bool isComingSoon = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: canAccess ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 120,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isComingSoon 
              ? LinearGradient(
                  colors: isDark 
                    ? [AppColors.borderMuted, AppColors.border]
                    : [Colors.grey.shade300, Colors.grey.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    color.withOpacity(isDark ? 0.2 : 0.1), 
                    color.withOpacity(isDark ? 0.3 : 0.2)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isComingSoon 
                  ? (isDark ? AppColors.textMuted : Colors.grey.shade600)
                  : color,
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isComingSoon 
                    ? (isDark ? AppColors.textMuted : Colors.grey.shade600)
                    : AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                isComingSoon ? 'Coming Soon' : '$count',
                style: TextStyle(
                  fontSize: 14,
                  color: isComingSoon 
                    ? (isDark ? AppColors.textMuted : Colors.grey.shade500)
                    : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppColors.info.withOpacity(isDark ? 0.2 : 0.1),
              AppColors.info.withOpacity(isDark ? 0.3 : 0.2)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, size: 24, color: AppColors.info),
                  SizedBox(width: 8),
                  Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                    ? AppColors.bgLight.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text(
                      'Statistics will be available soon',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppColors.text),
            ),
          ),
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
    if (_squad == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayersPage(
          squadId: _squad!.squadId,
          squadName: _squad!.name,
          ownerId: _squad!.ownerId,
        ),
      ),
    );
  }

  void _navigateToMatches(BuildContext context) {
    MessageService.showInfo(context, 'Matches page coming soon');
  }

  void _navigateToTournaments(BuildContext context) {
    MessageService.showInfo(context, 'Tournaments page coming soon');
  }
} 