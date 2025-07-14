import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/user_state.dart';
import '../services/message_service.dart';
import '../utils/permission_utils.dart';
import '../models/models.dart';
import '../services/squad_service.dart';
import '../theme/app_theme.dart';
import 'players_page.dart';
import 'match_history_page.dart';
import 'squad_list_page.dart';
import '../state/squad_state.dart';
import '../state/players_state.dart';
import '../state/matches_state.dart';
import '../widgets/player_stats_carousel.dart';
import '../models/stat_type.dart';
import '../models/stat_type_config.dart';

class SquadPage extends ConsumerStatefulWidget {
  final String squadId;

  const SquadPage({Key? key, required this.squadId}) : super(key: key);

  @override
  ConsumerState<SquadPage> createState() => _SquadPageState();
}

class _SquadPageState extends ConsumerState<SquadPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSquad();
  }

  Future<void> _loadSquad() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final squadDetail = await SquadService.instance.getSquad(widget.squadId);
      ref.read(squadProvider.notifier).setSquad(squadDetail);
      ref.read(playersProvider.notifier).setPlayers(squadDetail.players);
      ref.read(matchesProvider.notifier).setMatches(squadDetail.matches);
    } catch (e) {
      // Możesz dodać obsługę błędów jeśli chcesz
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final squadState = ref.watch(squadProvider);
    final playersState = ref.watch(playersProvider);
    final matchesState = ref.watch(matchesProvider);
    final userId = ref.watch(userSessionProvider).user?.userId ?? '';
    final isOwner = squadState.isOwner(userId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(squadState.squad?.name ?? 'Loading Squad...'),
        backgroundColor: isDark ? AppColors.bgDark : AppColors.lightSurface,
        foregroundColor: isDark ? AppColors.text : AppColors.lightText,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => SquadListPage(),
              ),
              (route) => false,
            );
          },
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editSquad(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: _buildBody(context, squadState, playersState, matchesState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SquadState squadState, PlayersState playersState, MatchesState matchesState) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (squadState.squad == null) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSquadInfo(squadState, playersState, matchesState),
        SizedBox(height: 24),
        _buildMainSections(context, squadState, playersState, matchesState),
        SizedBox(height: 24),
        _buildStatisticsSection(),
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
    );
  }

  Widget _buildSquadInfo(SquadState squadState, PlayersState playersState, MatchesState matchesState) {
    final squad = squadState.squad!;
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
            _buildInfoRow('Name', squad.name),
            _buildInfoRow('Created', squad.createdAt.toString().split(' ')[0]),
            _buildInfoRow('Players', playersState.players.length.toString()),
            _buildInfoRow('Matches', matchesState.matches.length.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSections(BuildContext context, SquadState squadState, PlayersState playersState, MatchesState matchesState) {
    return Row(
      children: [
        Expanded(
          child: _buildMainSection(
            context: context,
            title: 'Players',
            icon: Icons.people,
            color: AppColors.secondary,
            onTap: () => _navigateToPlayers(context),
            canAccess: true,
            count: 0,
            showCount: false,
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
            canAccess: true,
            count: 0,
            showCount: false,
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
            count: 0, // No count for tournaments
            showCount: false,
            isComingSoon: false,
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
    bool showCount = true,
    bool isComingSoon = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: canAccess ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
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
                size: 28,
                color: color,
              ),
              SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                  overflow: TextOverflow.ellipsis,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              if (showCount) ...[
                SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Test data for squad stats
    final List<Map<String, dynamic>> squadStats = [
      {
        'statType': 'recent_match',
        'title': 'Recent Match',
        'date': '2024-06-10',
        'homeName': 'Squad A',
        'awayName': 'Squad B',
        'homeScore': 3,
        'awayScore': 2,
      },
      {
        'statType': 'next_match',
        'title': 'Next Match',
        'date': '2024-06-20',
        'homeName': 'Squad A',
        'awayName': 'Squad C',
        'homeScore': null,
        'awayScore': null,
      },
      {
        'statType': 'best_player',
        'playerName': 'John Doe',
        'value': 8,
      },
      {
        'statType': 'best_delta',
        'value': 5,
      },
      {
        'statType': 'domination',
        'playerName': 'Rival Squad',
        'value': 7,
      },
      {
        'statType': 'teamwork',
        'playerName': 'Best Teammate',
        'value': 10,
      },
      {
        'statType': 'win_streak',
        'value': 4,
      },
      {
        'statType': 'win_ratio',
        'win': 10,
        'draw': 2,
        'loss': 3,
      },
      {
        'statType': 'avg_goals',
        'value': 2.5,
      },
      {
        'statType': 'biggest_win',
        'title': 'Biggest Win',
        'date': '2024-05-01',
        'homeName': 'Squad A',
        'awayName': 'Squad D',
        'homeScore': 6,
        'awayScore': 1,
      },
      {
        'statType': 'biggest_loss',
        'title': 'Biggest Loss',
        'date': '2024-04-15',
        'homeName': 'Squad E',
        'awayName': 'Squad A',
        'homeScore': 5,
        'awayScore': 0,
      },
    ];
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
              StatsCarousel(
                stats: squadStats,
                title: 'Squad Stats',
                getPlayerName: (stat) => stat['playerName'] ?? '',
                getStatType: (stat) => stat['statType'] ?? '',
                getStatValue: (stat) => stat['value'] ?? '',
              ),
              SizedBox(height: 24),
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

  void _editSquad(BuildContext context) {
    MessageService.showInfo(context, 'Edit squad functionality coming soon');
  }

  void _navigateToPlayers(BuildContext context) {
    final squadState = ref.read(squadProvider);
    if (squadState.squad == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayersPage(
          squadId: squadState.squad!.squadId,
          ownerId: squadState.squad!.ownerId,
        ),
      ),
    );
  }

  void _navigateToMatches(BuildContext context) {
    final squadState = ref.read(squadProvider);
    if (squadState.squad == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchHistoryPage(
          squadId: squadState.squad!.squadId,
          squadName: squadState.squad!.name,
          ownerId: squadState.squad!.ownerId,
        ),
      ),
    );
  }

  void _navigateToTournaments(BuildContext context) {
    //MessageService.showInfo(context, 'Tournaments page coming soon');
  }
} 