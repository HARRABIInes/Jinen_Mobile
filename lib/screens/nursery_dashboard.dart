import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user.dart';
import '../widgets/app_drawer.dart';
import 'chat_list_screen.dart';

class NurseryDashboard extends StatelessWidget {
  const NurseryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.user;

    // Mock data for demonstration
    final int enrolled = 18;
    final int totalSpots = 20;
    final int revenue = 6300;
    final List<Map<String, String>> requests = [
      {
        'name': 'Youssef Mansour',
        'parent': 'Fatma Mansour',
        'date': '13/11/2024',
        'status': 'En attente',
      },
      {
        'name': 'Lina Gharbi',
        'parent': 'Ahmed Gharbi',
        'date': '13/11/2024',
        'status': 'En attente',
      },
      {
        'name': 'Adam Ben Said',
        'parent': 'Sabrina Ben Said',
        'date': '13/11/2024',
        'status': 'En attente',
      },
    ];
    final List<Map<String, String>> program = [
      {
        'time': '09:00',
        'activity': 'Activités créatives - Groupe A',
        'children': '8 enfants'
      },
      {
        'time': '10:30',
        'activity': 'Récréation extérieure',
        'children': '18 enfants'
      },
      {'time': '12:00', 'activity': 'Déjeuner', 'children': '16 enfants'},
      {'time': '14:00', 'activity': 'Sieste - Petits', 'children': ''},
      {
        'time': '15:30',
        'activity': 'Musique et danse',
        'children': '12 enfants'
      },
    ];
    final List<Map<String, String>> messages = [
      {
        'name': 'Leila Ben Ali',
        'time': 'il y a 2h',
        'msg': 'Bonjour, Sofia est absente demain pour raison...'
      },
      {
        'name': 'Mohamed Trabelsi',
        'time': 'il y a 2h',
        'msg': 'Merci pour le rapport quotidien ! Très utile.'
      },
    ];

    return Scaffold(
      drawer: const AppDrawer(userType: UserType.nursery),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header with stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tableau de bord',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(user?.name ?? 'Garderie',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatListScreen(
                                    userId: user?.id ?? 'directeur1',
                                    userType: 'directeur',
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
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => appState.logout(),
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
                          value: '$enrolled/$totalSpots',
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
                          value: '$revenue',
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

            // Registration requests
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Demandes d\'inscription (5)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton(onPressed: () {}, child: const Text('Tout voir')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: requests.map((req) => _RequestCard(req)).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Daily program
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('Programme d\'aujourd\'hui',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: program.map((item) => _ProgramRow(item)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('Actions rapides',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickAction(icon: Icons.group, label: 'Gérer les inscrits'),
                  _QuickAction(
                      icon: Icons.event, label: 'Activités & horaires'),
                  _QuickAction(icon: Icons.people, label: 'Parents & équipe'),
                  _QuickAction(icon: Icons.bar_chart, label: 'Performance'),
                  _QuickAction(
                      icon: Icons.attach_money, label: 'Suivi financier'),
                  _QuickAction(icon: Icons.settings, label: 'Configuration'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recent messages
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Messages récents',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton(onPressed: () {}, child: const Text('Tout voir')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: messages.map((msg) => _MessageCard(msg)).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
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
  final Map<String, String> req;
  const _RequestCard(this.req);
  @override
  Widget build(BuildContext context) {
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
                  Text(req['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Parent: ${req['parent']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Demandé le ${req['date']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(req['status'] ?? '',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {},
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
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Color(0xFF667EEA)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Voir détails', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramRow extends StatelessWidget {
  final Map<String, String> item;
  const _ProgramRow(this.item);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(item['time'] ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF667EEA))),
          const SizedBox(width: 16),
          Expanded(
            child: Text(item['activity'] ?? '',
                style: const TextStyle(fontSize: 14)),
          ),
          if ((item['children'] ?? '').isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item['children']!,
                  style:
                      const TextStyle(color: Color(0xFF10B981), fontSize: 12)),
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
