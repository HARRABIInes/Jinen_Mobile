import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user.dart';
import '../screens/manage_enrolled_screen.dart';
import '../screens/nursery_children_list_screen.dart';
import '../screens/nursery_program_screen.dart';
import '../screens/nursery_performance_screen.dart';
import '../screens/nursery_settings_screen.dart';
import '../screens/parent_children_screen.dart';
import '../screens/parent_payment_screen.dart';
import '../screens/parent_reviews_screen.dart';

class AppDrawer extends StatelessWidget {
  final UserType userType;

  const AppDrawer({
    super.key,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.user;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Colors.white,
            ],
            stops: [0.0, 0.15, 0.4],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header avec profil utilisateur - Design moderne
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Utilisateur',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Menu items - Nursery
            if (userType == UserType.nursery) ...[
              _buildMenuItem(
                context,
                icon: Icons.person_rounded,
                title: 'Mon Profil',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NurserySettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              const SizedBox(height: 4),
              _buildMenuItem(
                context,
                icon: Icons.dashboard_rounded,
                title: 'Tableau de bord',
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.1),
                    Colors.transparent
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigation vers manage enrolled (même que tableau de bord)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageEnrolledScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              _buildMenuItem(
                context,
                icon: Icons.people_rounded,
                title: 'Enfants inscrits',
                subtitle: 'Sans parent',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NurseryChildrenListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              _buildMenuItem(
                context,
                icon: Icons.calendar_today_rounded,
                title: 'Programme',
                subtitle: 'Modifier le planning',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NurseryProgramScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              _buildMenuItem(
                context,
                icon: Icons.analytics_rounded,
                title: 'Performance',
                subtitle: 'Statistiques et avis',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NurseryPerformanceScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.grey[300], thickness: 1),
              ),
              const SizedBox(height: 4),
              _buildMenuItem(
                context,
                icon: Icons.settings_rounded,
                title: 'Paramètres',
                subtitle: 'Gérer votre profil',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NurserySettingsScreen(),
                    ),
                  );
                },
              ),
            ],

            // Menu items - Parent
            if (userType == UserType.parent) ...[
              _buildMenuItem(
                context,
                icon: Icons.person_rounded,
                title: 'Mon Profil',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Profil à implémenter');
                },
              ),
              const SizedBox(height: 4),
              _buildMenuItem(
                context,
                icon: Icons.child_care_rounded,
                title: 'Mes Enfants',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParentChildrenScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              _buildMenuItem(
                context,
                icon: Icons.payment_rounded,
                title: 'Paiements',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParentPaymentScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              _buildMenuItem(
                context,
                icon: Icons.star_rounded,
                title: 'Mes Avis',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParentReviewsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.grey[300], thickness: 1),
              ),
              const SizedBox(height: 4),
              _buildMenuItem(
                context,
                icon: Icons.settings_rounded,
                title: 'Paramètres',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Paramètres à implémenter');
                },
              ),
            ],

            const SizedBox(height: 4),

            _buildMenuItem(
              context,
              icon: Icons.help_rounded,
              title: 'Aide',
              onTap: () {
                Navigator.pop(context);
                _showDialog(
                  context,
                  'Aide',
                  'Pour toute question, contactez-nous à support@garderie.com',
                  Icons.help_outline_rounded,
                  const Color(0xFF6366F1),
                );
              },
            ),

            const SizedBox(height: 4),

            _buildMenuItem(
              context,
              icon: Icons.info_rounded,
              title: 'À propos',
              onTap: () {
                Navigator.pop(context);
                _showDialog(
                  context,
                  'À propos',
                  'Garderie App v1.0.0\nApplication de gestion de garderie\n© 2026',
                  Icons.info_outline_rounded,
                  const Color(0xFF6366F1),
                );
              },
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.grey[300], thickness: 1),
            ),

            const SizedBox(height: 4),

            _buildMenuItem(
              context,
              icon: Icons.logout_rounded,
              title: 'Déconnexion',
              textColor: Colors.red.shade700,
              iconColor: Colors.red.shade700,
              onTap: () {
                Navigator.pop(context);
                _showConfirmDialog(
                  context,
                  'Déconnexion',
                  'Êtes-vous sûr de vouloir vous déconnecter ?',
                  () {
                    appState.logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.white),
                            SizedBox(width: 12),
                            Text('Déconnexion réussie'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    Gradient? gradient,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (iconColor ?? const Color(0xFF6366F1)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? const Color(0xFF6366F1),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor ?? const Color(0xFF1F2937),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDialog(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
