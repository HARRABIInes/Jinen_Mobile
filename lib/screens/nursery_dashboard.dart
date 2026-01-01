import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/app_state.dart';
import '../services/enrollment_service_web.dart';
import '../services/nursery_dashboard_service.dart';
import '../widgets/app_drawer.dart';
import 'chat_list_screen.dart';
import 'manage_enrolled_screen.dart';
import 'nursery_performance_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboardData());
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
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(
                                    Icons.menu,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bonjour,',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    user?.name ?? 'Garderie',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Colors.white,
                                      size: 28,
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
                                  if (appState.unreadMessagesCount > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
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
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                ),
                                onPressed: appState.logout,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Enfants inscrits',
                              value: _stats != null
                                  ? '${_stats!['enrolledChildren']}/${_stats!['totalSpots']}'
                                  : '--/--',
                              icon: Icons.child_care,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Revenus (TND/mois)',
                              value: _stats != null
                                  ? '${_stats!['monthlyRevenue']}'
                                  : '--',
                              icon: Icons.attach_money,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Demandes d'inscription (${_pendingEnrollments.length})",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                            onPressed: () {}, child: const Text('Tout voir')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _pendingEnrollments.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Aucune demande en attente'),
                            ),
                          )
                        : Column(
                            children: _pendingEnrollments
                                .map(
                                  (enrollment) => _RequestCard(
                                    enrollment: enrollment,
                                    onAccept: () => _handleAcceptEnrollment(
                                      (enrollment['id'] ?? '').toString(),
                                    ),
                                    onReject: () => _handleRejectEnrollment(
                                      (enrollment['id'] ?? '').toString(),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Programme d'aujourd'hui",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF667EEA),
                          ),
                          onPressed: _showAddScheduleDialog,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _schedule.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Aucune activité programmée'),
                            )
                          : Column(
                              children: _schedule
                                  .map(
                                    (item) => _ProgramRow(
                                      item: item,
                                      onDelete: () => _handleDeleteSchedule(
                                        (item['id'] ?? '').toString(),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Actions rapides',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickAction(
                        icon: Icons.group,
                        label: 'Gérer les inscrits',
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
                      const _QuickAction(
                          icon: Icons.event, label: 'Activités & horaires'),
                      const _QuickAction(
                          icon: Icons.people, label: 'Parents & équipe'),
                      _QuickAction(
                        icon: Icons.bar_chart,
                        label: 'Performance',
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
                      const _QuickAction(
                          icon: Icons.attach_money, label: 'Suivi financier'),
                      const _QuickAction(
                          icon: Icons.settings, label: 'Configuration'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
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

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (child?['childName'] ?? 'N/A').toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Parent: ${(parent?['name'] ?? 'N/A').toString()}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (createdAt != null)
                    Text(
                      'Demandé le ${_formatDate(createdAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'En attente',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Accepter', style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Refuser', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            timeSlot,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF667EEA),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description != null && description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (participantCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$participantCount enfants',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: onDelete,
            tooltip: 'Supprimer',
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

  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF667EEA)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
