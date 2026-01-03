import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/app_state.dart';
import '../services/enrollment_service_web.dart';
import '../services/nursery_dashboard_service.dart';
import '../services/notification_service_web.dart';
import '../widgets/app_drawer.dart';
import 'chat_list_screen.dart';
import 'notifications_screen.dart';
import 'manage_enrolled_screen.dart';
import 'nursery_performance_screen.dart';
import 'nursery_financial_tracking_screen.dart';

class NurseryDashboard extends StatefulWidget {
  const NurseryDashboard({super.key});

  @override
  State<NurseryDashboard> createState() => _NurseryDashboardState();
}

class _NurseryDashboardState extends State<NurseryDashboard> {
  final NurseryDashboardService _dashboardService = NurseryDashboardService();
  final EnrollmentServiceWeb _enrollmentService = EnrollmentServiceWeb();

  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _schedule = [];
  List<Map<String, dynamic>> _pendingEnrollments = [];
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboardData());
    _loadUnreadCount();

    // Listen for updates from other screens (e.g., ManageEnrolledScreen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false)
          .addListener(_onAppStateChange);
    });
  }

  Future<void> _loadUnreadCount() async {
    if (!mounted) return;
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userId = appState.user?.id ?? '';
      if (userId.isNotEmpty) {
        final count = await NotificationServiceWeb.getUnreadCount(userId);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading unread count: $e');
    }
  }

  void _onAppStateChange() {
    // Reload dashboard data when AppState changes (e.g., enrollment accepted)
    if (mounted) {
      _loadDashboardData();
    }
  }

  @override
  void dispose() {
    Provider.of<AppState>(context, listen: false)
        .removeListener(_onAppStateChange);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.nurseries.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final nurseryId = appState.nurseries.first.id;

    try {
      final results = await Future.wait([
        _dashboardService.getNurseryStats(nurseryId),
        _dashboardService.getDailySchedule(nurseryId),
        _enrollmentService.getEnrollmentsByNursery(nurseryId),
      ]);

      setState(() {
        _stats = results[0] as Map<String, dynamic>?;
        _schedule = List<Map<String, dynamic>>.from(results[1] as List);

        final allEnrollments =
            List<Map<String, dynamic>>.from(results[2] as List);
        _pendingEnrollments = allEnrollments
            .where((e) =>
                (e['status'] ?? '').toString().toLowerCase() == 'pending')
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // ignore: avoid_print
      print('Error loading dashboard data: $e');
    }
  }

  Future<void> _handleAcceptEnrollment(String enrollmentId) async {
    final success = await _dashboardService.acceptEnrollment(enrollmentId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription acceptée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDashboardData();
    }
  }

  Future<void> _handleRejectEnrollment(String enrollmentId) async {
    final success = await _dashboardService.rejectEnrollment(enrollmentId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription refusée'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadDashboardData();
    }
  }

  Future<void> _handleDeleteSchedule(String scheduleId) async {
    final success = await _dashboardService.deleteScheduleItem(scheduleId);
    if (success && mounted) {
      _loadDashboardData();
    }
  }

  void _showAddScheduleDialog() {
    final timeController = TextEditingController();
    final activityController = TextEditingController();
    final descriptionController = TextEditingController();
    final participantController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une activité'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration:
                    const InputDecoration(labelText: 'Heure (ex: 09:00)'),
              ),
              TextField(
                controller: activityController,
                decoration: const InputDecoration(labelText: 'Activité'),
              ),
              TextField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (optionnel)'),
              ),
              TextField(
                controller: participantController,
                decoration:
                    const InputDecoration(labelText: "Nombre d'enfants"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              if (appState.nurseries.isEmpty) {
                Navigator.pop(context);
                return;
              }

              final nurseryId = appState.nurseries.first.id;
              await _dashboardService.createScheduleItem(
                nurseryId: nurseryId,
                timeSlot: timeController.text,
                activityName: activityController.text,
                description: descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text,
                participantCount: int.tryParse(participantController.text),
              );

              if (!context.mounted) return;
              Navigator.pop(context);
              _loadDashboardData();
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.user;

    return Scaffold(
      drawer: const AppDrawer(userType: UserType.nursery),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            color: const Color(0xFF6366F1),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header Section with improved design
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      children: [
                        // Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Builder(
                                  builder: (context) => Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.menu_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      onPressed: () =>
                                          Scaffold.of(context).openDrawer(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bonjour,',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user?.name ?? 'Garderie',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Chat Button with Badge
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatListScreen(
                                                userId: user?.id ?? 'nursery1',
                                                userType: 'nursery',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    if (appState.unreadMessagesCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF6366F1),
                                              width: 2,
                                            ),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 20,
                                            minHeight: 20,
                                          ),
                                          child: Text(
                                            '${appState.unreadMessagesCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                // Notifications Button
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => NotificationsScreen(
                                                userId: user?.id ?? 'nursery1',
                                              ),
                                            ),
                                          ).then((_) {
                                            // Refresh unread count when returning
                                            _loadUnreadCount();
                                          });
                                        },
                                      ),
                                    ),
                                    if (_unreadNotificationCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            _unreadNotificationCount > 99
                                                ? '99+'
                                                : _unreadNotificationCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                // Logout Button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: appState.logout,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Statistics Cards with modern design
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Enfants inscrits',
                                value: _stats != null
                                    ? '${_stats!['enrolledChildren']}/${_stats!['totalSpots']}'
                                    : '--/--',
                                icon: Icons.child_care_rounded,
                                color: Colors.white,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669)
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                label: 'Revenus (TND/mois)',
                                value: _stats != null
                                    ? '${_stats!['monthlyRevenue']}'
                                    : '--',
                                icon: Icons.payments_rounded,
                                color: Colors.white,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706)
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Main Content Container with rounded top corners
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_isLoading)
                          Container(
                            padding: const EdgeInsets.all(60),
                            child: const CircularProgressIndicator(
                              color: Color(0xFF6366F1),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 28),
                          // Enrollment Requests Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: Color(0xFF6366F1),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Demandes d'inscription",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        Text(
                                          '${_pendingEnrollments.length} en attente',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF6366F1),
                                  ),
                                  child: const Text(
                                    'Tout voir',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _pendingEnrollments.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.inbox_rounded,
                                          size: 48,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Aucune demande en attente',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: _pendingEnrollments
                                        .map(
                                          (enrollment) => _RequestCard(
                                            enrollment: enrollment,
                                            onAccept: () =>
                                                _handleAcceptEnrollment(
                                              (enrollment['id'] ?? '')
                                                  .toString(),
                                            ),
                                            onReject: () =>
                                                _handleRejectEnrollment(
                                              (enrollment['id'] ?? '')
                                                  .toString(),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                          const SizedBox(height: 28),
                          // Daily Schedule Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today_rounded,
                                        color: Color(0xFF10B981),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Programme d'aujourd'hui",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: _showAddScheduleDialog,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: _schedule.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.event_busy_rounded,
                                            size: 48,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Aucune activité programmée',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      children: _schedule
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => Column(
                                              children: [
                                                _ProgramRow(
                                                  item: entry.value,
                                                  onDelete: () =>
                                                      _handleDeleteSchedule(
                                                    (entry.value['id'] ?? '')
                                                        .toString(),
                                                  ),
                                                ),
                                                if (entry.key <
                                                    _schedule.length - 1)
                                                  Divider(
                                                    height: 1,
                                                    indent: 20,
                                                    endIndent: 20,
                                                    color: Colors.grey[200],
                                                  ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        // Quick Actions Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFF59E0B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Actions rapides',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.4,
                            children: [
                              _QuickAction(
                                icon: Icons.group_rounded,
                                label: 'Gérer les inscrits',
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6)
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageEnrolledScreen(),
                                    ),
                                  );
                                },
                              ),
                              _QuickAction(
                                icon: Icons.analytics_rounded,
                                label: 'Performance',
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669)
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NurseryPerformanceScreen(),
                                    ),
                                  );
                                },
                              ),
                              _QuickAction(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Suivi financier',
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706)
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NurseryFinancialTrackingScreen(),
                                    ),
                                  );
                                },
                              ),
                              const _QuickAction(
                                icon: Icons.settings_rounded,
                                label: 'Configuration',
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF6366F1)
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Gradient? gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? color.withOpacity(0.15) : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient != null ? gradient!.colors.first : color)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> enrollment;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.enrollment,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final child = enrollment['child'] as Map<String, dynamic>?;
    final parent = enrollment['parent'] as Map<String, dynamic>?;
    final createdAt = enrollment['createdAt'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (child?['childName'] ?? 'N/A').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parent: ${(parent?['name'] ?? 'N/A').toString()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        'Demandé le ${_formatDate(createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'En attente',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAccept,
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side:
                        const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _ProgramRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _ProgramRow({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final timeSlot = (item['timeSlot'] ?? '').toString();
    final activityName = (item['activityName'] ?? '').toString();
    final description = item['description']?.toString();
    final participantCount = item['participantCount'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  timeSlot.split(':')[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Text(
                  timeSlot.split(':').length > 1
                      ? timeSlot.split(':')[1]
                      : '00',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (participantCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_rounded,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$participantCount',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 22),
              onPressed: onDelete,
              tooltip: 'Supprimer',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? Colors.white : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    (gradient != null ? gradient!.colors.first : Colors.black)
                        .withOpacity(gradient != null ? 0.25 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: gradient != null
                      ? Colors.white.withOpacity(0.3)
                      : const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color:
                      gradient != null ? Colors.white : const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      gradient != null ? Colors.white : const Color(0xFF1E293B),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
