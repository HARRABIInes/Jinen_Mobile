import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user.dart';

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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667EEA), Color(0xFFFFFFFF)],
            stops: [0.0, 0.3],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header avec profil utilisateur
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667EEA),
                  ),
                ),
              ),
              accountName: Text(
                user?.name ?? 'Utilisateur',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),

            // Menu items
            _buildMenuItem(
              context,
              icon: Icons.person,
              title: 'Mon Profil',
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(context, 'Profil à implémenter');
              },
            ),

            if (userType == UserType.parent) ...[
              _buildMenuItem(
                context,
                icon: Icons.child_care,
                title: 'Mes Enfants',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Liste des enfants à implémenter');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.payment,
                title: 'Paiements',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(
                      context, 'Historique des paiements à implémenter');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.star,
                title: 'Mes Avis',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Mes avis à implémenter');
                },
              ),
            ],

            if (userType == UserType.nursery) ...[
              _buildMenuItem(
                context,
                icon: Icons.dashboard,
                title: 'Tableau de bord',
                onTap: () {
                  Navigator.pop(context);
                  appState.setScreen(ScreenType.nurseryDashboard);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.people,
                title: 'Enfants inscrits',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Liste des enfants à implémenter');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.calendar_today,
                title: 'Programme',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Gestion du programme à implémenter');
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.analytics,
                title: 'Statistiques',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Statistiques à implémenter');
                },
              ),
            ],

            const Divider(),

            _buildMenuItem(
              context,
              icon: Icons.settings,
              title: 'Paramètres',
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(context, 'Paramètres à implémenter');
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.help,
              title: 'Aide',
              onTap: () {
                Navigator.pop(context);
                _showDialog(
                  context,
                  'Aide',
                  'Pour toute question, contactez-nous à support@garderie.com',
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.info,
              title: 'À propos',
              onTap: () {
                Navigator.pop(context);
                _showDialog(
                  context,
                  'À propos',
                  'Garderie App v1.0.0\nApplication de gestion de garderie\n© 2025',
                );
              },
            ),

            const Divider(),

            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Déconnexion',
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showConfirmDialog(
                  context,
                  'Déconnexion',
                  'Êtes-vous sûr de vouloir vous déconnecter ?',
                  () {
                    appState.logout();
                    _showSnackBar(context, 'Déconnexion réussie');
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
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? const Color(0xFF667EEA),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? const Color(0xFF1F2937),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
