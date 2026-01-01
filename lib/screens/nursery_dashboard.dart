import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user.dart';
import '../widgets/app_drawer.dart';
import '../services/nursery_dashboard_service.dart';
import '../services/enrollment_service_web.dart';
import 'chat_list_screen.dart';

class NurseryDashboard extends StatefulWidget {
  const NurseryDashboard({super.key});

  @override
  State<NurseryDashboard> createState() => _NurseryDashboardState();
}

class _NurseryDashboardState extends State<NurseryDashboard> {
  final NurseryDashboardService _dashboardService = NurseryDashboardService();
  final EnrollmentServiceWeb _enrollmentService = EnrollmentServiceWeb();

  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _schedule = [];
  List<Map<String, dynamic>> _pendingEnrollments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    print('🔄 Loading dashboard data...');
    setState(() => _isLoading = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final nurseries = appState.nurseries;

    if (nurseries.isNotEmpty) {
      final nurseryId = nurseries.first.id;
      print('🏢 Nursery ID: $nurseryId');

      // Load stats, schedule, and pending enrollments in parallel
      final results = await Future.wait([
        _dashboardService.getNurseryStats(nurseryId),
        _dashboardService.getDailySchedule(nurseryId),
        _enrollmentService.getEnrollmentsByNursery(nurseryId),
      ]);

      print('📊 Stats received: ${results[0]}');
      print('📅 Schedule received: ${results[1]}');
      print('📝 Enrollments received: ${(results[2] as List).length} items');

      setState(() {
        _stats = results[0] as Map<String, dynamic>?;
        _schedule = results[1] as List<Map<String, dynamic>>;
        final allEnrollments = results[2] as List<Map<String, dynamic>>;
        _pendingEnrollments =
            allEnrollments.where((e) => e['status'] == 'pending').toList();
        print('✅ Pending enrollments: ${_pendingEnrollments.length}');
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAcceptEnrollment(String enrollmentId) async {
    final success = await _dashboardService.acceptEnrollment(enrollmentId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription acceptée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDashboardData(); // Reload data
    }
  }

  Future<void> _handleRejectEnrollment(String enrollmentId) async {
    final success = await _dashboardService.rejectEnrollment(enrollmentId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription refusée'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadDashboardData(); // Reload data
    }
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
                // Header
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
                                  onPressed: () {
                                    Scaffold.of(context).openDrawer();
                                  },
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
                                    icon: const Icon(Icons.chat_bubble_outline,
                                        color: Colors.white, size: 28),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatListScreen(
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
                                icon: const Icon(Icons.notifications,
                                    color: Colors.white),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout,
                                    color: Colors.white),
                                onPressed: () => appState.logout(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Enfants inscrits',
                              value: _stats != null
                                  ? '${_stats!['enrolledChildren']}/${_stats!['totalSpots']}'
                                  : '--/--',
                              icon: Icons.child_care,
                              color: Colors.white,
                              fontSize: 16,
                              iconSize: 28,
                              padding: 12,
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
                              fontSize: 16,
                              iconSize: 28,
                              padding: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Loading indicator
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  // Registration requests
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Demandes d\'inscription (${_pendingEnrollments.length})',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
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
                              padding: EdgeInsets.all(16.0),
                              child: Text('Aucune demande en attente'),
                            ),
                          )
                        : Column(
                            children: _pendingEnrollments
                                .map((enrollment) => _RequestCard(
                                      enrollment: enrollment,
                                      onAccept: () => _handleAcceptEnrollment(
                                          enrollment['id']),
                                      onReject: () => _handleRejectEnrollment(
                                          enrollment['id']),
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Daily program
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Programme d\'aujourd\'hui',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFF667EEA)),
                          onPressed: () => _showAddScheduleDialog(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: _schedule.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Aucune activité programmée'),
                            )
                          : Column(
                              children: _schedule
                                  .map((item) => _ProgramRow(
                                        item: item,
                                        onDelete: () =>
                                            _handleDeleteSchedule(item['id']),
                                      ))
                                  .toList(),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Quick actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text('Actions rapides',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickAction(
                          icon: Icons.group, label: 'Gérer les inscrits'),
                      _QuickAction(
                          icon: Icons.event, label: 'Activités & horaires'),
                      _QuickAction(
                          icon: Icons.people, label: 'Parents & équipe'),
                      _QuickAction(icon: Icons.bar_chart, label: 'Performance'),
                      _QuickAction(
                          icon: Icons.attach_money, label: 'Suivi financier'),
                      _QuickAction(
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

  void _showAddScheduleDialog(BuildContext context) {
    final timeController = TextEditingController();
    final activityController = TextEditingController();
    final descriptionController = TextEditingController();
    final participantController = TextEditingController();

    showDialog(
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
                    const InputDecoration(labelText: 'Nombre d\'enfants'),
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

              Navigator.pop(context);
              _loadDashboardData();
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteSchedule(String scheduleId) async {
    final success = await _dashboardService.deleteScheduleItem(scheduleId);
    if (success && mounted) {
      _loadDashboardData();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double fontSize;
  final double iconSize;
  final double padding;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fontSize = 20,
    this.iconSize = 32,
    this.padding = 16,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: color)),
              Text(label,
                  style:
                      TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
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
                  Text(child?['childName'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Parent: ${parent?['name'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (createdAt != null)
                    Text('Demandé le ${_formatDate(createdAt)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('En attente',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
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
                    borderRadius: BorderRadius.circular(8)),
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
                    borderRadius: BorderRadius.circular(8)),
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
    } catch (e) {
      return isoDate;
    }
  }
}

class _ProgramRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _ProgramRow({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(item['timeSlot'] ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF667EEA))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['activityName'] ?? '',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                if (item['description'] != null && item['description'] != '')
                  Text(item['description'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (item['participantCount'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${item['participantCount']} enfants',
                  style:
                      const TextStyle(color: Color(0xFF10B981), fontSize: 12)),
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
  const _QuickAction({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
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
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF667EEA)),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final Map<String, String> msg;
  const _MessageCard(this.msg);
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF667EEA).withOpacity(0.15),
              child: Text(msg['name']![0],
                  style: const TextStyle(
                      color: Color(0xFF667EEA), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(msg['msg'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            Text(msg['time'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
