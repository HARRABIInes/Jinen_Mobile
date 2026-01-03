import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user.dart';
import '../models/nursery.dart';
import '../widgets/app_drawer.dart';
import '../services/parent_nurseries_service_web.dart';
import '../services/review_service_web.dart';
import '../services/parent_program_service.dart';
import 'chat_list_screen.dart';
import 'parent_enrollments_screen.dart';
import 'parent_payment_screen.dart';
import 'package:intl/intl.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  late List<dynamic> _nurseries = [];
  late List<dynamic> _todayProgram = [];
  late List<dynamic> _recentReviews = [];
  String? _nurseryName;
  bool _isLoading = true;
  bool _isProgramLoading = true;
  bool _isReviewsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNurseries();
    _loadTodayProgram();
    _loadRecentReviews();
  }

  // Helper function to format rating properly (average from backend)
  String _formatRating(dynamic rating) {
    if (rating == null) return '0.0';
    if (rating is double) return rating.toStringAsFixed(1);
    if (rating is int) return rating.toDouble().toStringAsFixed(1);
    final parsed = double.tryParse(rating.toString());
    return parsed?.toStringAsFixed(1) ?? '0.0';
  }

  Future<void> _loadNurseries() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final parentId = appState.user?.id ?? '';
      print('🔄 Loading nurseries for parentId: $parentId');
      
      final res = await ParentNurseriesServiceWeb.getParentNurseries(parentId);
      
      print('🔄 Response: $res');
      print('🔄 Success: ${res['success']}');
      print('🔄 Nurseries count: ${(res['nurseries'] ?? []).length}');
      if ((res['nurseries'] ?? []).isNotEmpty) {
        print('🔄 First nursery: ${res['nurseries'][0]}');
        print('🔄   - Name: ${res['nurseries'][0]['name']}');
        print('🔄   - Rating: ${res['nurseries'][0]['rating']}');
        print('🔄   - ReviewCount: ${res['nurseries'][0]['reviewCount']}');
      }
      
      if (mounted) {
        setState(() {
          _nurseries = res['nurseries'] ?? [];
          _isLoading = false;
          print('✅ Nurseries loaded: ${_nurseries.length} nurseries');
          for (var i = 0; i < _nurseries.length; i++) {
            print('   - ${_nurseries[i]['name']}: rating=${_nurseries[i]['rating']}, reviewCount=${_nurseries[i]['reviewCount']}');
          }
        });
      }
    } catch (e) {
      print('❌ Error in _loadNurseries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTodayProgram() async {
    if (!mounted) return;
    setState(() => _isProgramLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final parentId = appState.user?.id ?? '';
      final res = await ParentProgramService.getTodayProgram(parentId);
      if (mounted) {
        setState(() {
          _todayProgram = res['program'] ?? [];
          _nurseryName = res['nurseryName'];
          _isProgramLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProgramLoading = false);
      }
    }
  }

  Future<void> _loadRecentReviews() async {
    if (!mounted) return;
    setState(() => _isReviewsLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final parentId = appState.user?.id ?? '';
      final res = await ParentProgramService.getNurseryRecentReviews(parentId);
      if (mounted) {
        setState(() {
          _recentReviews = res['reviews'] ?? [];
          _isReviewsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReviewsLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.user;

    return Scaffold(
      drawer: const AppDrawer(userType: UserType.parent),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
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
                              user?.name ?? 'Parent',
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
                                      userId: user?.id ?? 'parent1',
                                      userType: 'parent',
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
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 28),
                              onPressed: () {},
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  '2',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Chercher une garderie...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    onTap: () => appState.setScreen(ScreenType.search),
                    readOnly: true,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick action button - Mes inscriptions
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ParentEnrollmentsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF00BFA5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_outlined),
                              SizedBox(width: 8),
                              Text(
                                'Mes inscriptions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Mes Garderies
                        const Text(
                          'Mes Garderies',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nurseries List or Loading State
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else if (_nurseries.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aucune garderie inscrite',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ParentEnrollmentsScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00BFA5),
                                  ),
                                  child: const Text('Inscrire un enfant'),
                                )
                              ],
                            ),
                          )
                        else
                          ...(_nurseries.map((nursery) {
                            return _buildNurseryCard(nursery);
                          }).toList()),
                        const SizedBox(height: 24),

                        // Actions rapides
                        const Text(
                          'Actions rapides',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.search,
                                iconColor: const Color(0xFF00BFA5),
                                title: 'Nouvelle garderie',
                                onTap: () =>
                                    appState.setScreen(ScreenType.search),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.location_on,
                                iconColor: const Color(0xFF00ACC1),
                                title: 'Garderies proches',
                                onTap: () =>
                                    appState.setScreen(ScreenType.search),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.calendar_today,
                                iconColor: const Color(0xFF9C27B0),
                                title: 'Programme',
                                onTap: () => _showTodayProgramDialog(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.payment,
                                iconColor: const Color(0xFFF59E0B),
                                title: 'Mes Paiements',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ParentPaymentScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Notifications récentes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notifications récentes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Tout voir'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Display recent reviews or empty state
                        if (_isReviewsLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else if (_recentReviews.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Aucun avis disponible',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ...(_recentReviews.map((review) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _NotificationCard(
                                icon: Icons.star,
                                title: review['comment'] ?? 'Avis sans commentaire',
                                time: _formatReviewTime(review['created_at']),
                                subtitle: '${review['parent_name']} - ${review['rating']}/5 ⭐',
                                isUnread: false,
                              ),
                            );
                          }).toList()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNurseryCard(Map<String, dynamic> nursery) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom de la garderie
            Text(
              nursery['name'] ?? 'Garderie',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),

            // Adresse
            if (nursery['address'] != null || nursery['city'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${nursery['address'] ?? ''} ${nursery['city'] ?? ''}'
                            .trim(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Rating
            if (nursery['rating'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatRating(nursery['rating'])} / 5.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '(${nursery['reviewCount'] ?? 0} avis)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

            // Places disponibles
            if (nursery['availableSpots'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.chair,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${nursery['availableSpots']} / ${nursery['totalSpots'] ?? ''} places',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Bouton vers détails
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Naviguer vers les détails de la garderie
                  final nurseryObject = Nursery(
                    id: nursery['id'] ?? '',
                    name: nursery['name'] ?? 'Garderie',
                    description: nursery['description'] ?? '',
                    address: nursery['address'] ?? '',
                    city: nursery['city'] ?? '',
                    postalCode: nursery['postalCode'] ?? '',
                    phone: nursery['phone'] ?? '',
                    email: nursery['email'] ?? '',
                    hours: nursery['hours'] ?? '',
                    price: double.tryParse(nursery['price']?.toString() ?? '0') ?? 0.0,
                    totalSpots: nursery['totalSpots'] ?? 0,
                    availableSpots: nursery['availableSpots'] ?? 0,
                    rating: double.tryParse(nursery['rating']?.toString() ?? '0') ?? 0.0,
                    ageRange: nursery['ageRange'] ?? '',
                    photo: '',
                    distance: 0.0,
                    reviewCount: nursery['reviewCount'] ?? 0,
                    activities: [],
                    facilities: [],
                    staff: 0,
                  );
                  final appState = Provider.of<AppState>(context, listen: false);
                  appState.selectNursery(nurseryObject);
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Voir détails'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showLeaveReviewDialog(nursery),
                    child: const Text('Laisser un avis'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _showReviewsDialog(nursery['id']);
                    },
                    child: const Text('Voir avis'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _contactNursery(nursery),
                icon: const Icon(Icons.message, size: 16),
                label: const Text('Contacter'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReviewTime(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays}j';
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  void _showTodayProgramDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFF9C27B0)),
              SizedBox(width: 8),
              Text('Programme d\'aujourd\'hui'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _isProgramLoading
                ? const Center(child: CircularProgressIndicator())
                : _todayProgram.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _nurseryName == null
                                ? 'Aucune garderie inscrite'
                                : 'Aucun programme pour aujourd\'hui',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_nurseryName != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _nurseryName!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00BFA5),
                                ),
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _todayProgram.length,
                              itemBuilder: (context, index) {
                                final item = _todayProgram[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF9C27B0),
                                      child: Text(
                                        item['time_slot']?.toString().split(':')[0] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      item['activity_name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('🕐 ${item['time_slot'] ?? ''}'),
                                        if (item['description'] != null)
                                          Text(item['description']),
                                        if (item['participant_count'] != null)
                                          Text(
                                            '👥 ${item['participant_count']} participants',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLeaveReviewDialog(Map<String, dynamic> nursery) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final parentId = appState.user?.id;

    if (parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous devez être connecté pour laisser un avis')),
      );
      return;
    }

    double rating = 5.0;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Laisser un avis - ${nursery['name'] ?? ''}'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (dialogContext, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Notez la garderie (0.5 - 5.0)'),
                Slider(
                  value: rating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: rating.toStringAsFixed(1),
                  onChanged: (v) {
                    setState(() => rating = v);
                  },
                ),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'Votre commentaire (optionnel)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await ReviewServiceWeb.postReview(
                nurseryId: nursery['id'],
                parentId: parentId,
                rating: double.parse(rating.toStringAsFixed(1)),
                comment: commentController.text.isNotEmpty
                    ? commentController.text
                    : null,
              );

              if (res['success'] == true) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Merci pour votre avis'),
                        backgroundColor: Colors.green),
                  );
                  await _loadNurseries();
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Erreur: ${res['error'] ?? 'Impossible d\'envoyer l\'avis'}')),
                  );
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewsDialog(String nurseryId) async {
    final res = await ReviewServiceWeb.getNurseryReviews(nurseryId);
    List reviews = [];
    if (res['success'] == true) reviews = res['reviews'] ?? [];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avis des parents'),
        content: SizedBox(
          width: double.maxFinite,
          child: reviews.isEmpty
              ? const Text('Aucun avis pour le moment')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: reviews.length,
                  itemBuilder: (context, idx) {
                    final r = reviews[idx];
                    final isMine = r['parent_id'] ==
                        Provider.of<AppState>(context, listen: false).user?.id;
                    return ListTile(
                      title: Text(r['parent_name'] ?? 'Parent'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r['rating']}/5'),
                          if (r['comment'] != null) Text(r['comment']),
                          Text(r['created_at'] ?? '',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      trailing: isMine
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _showEditReviewDialog(r);
                                  await _showReviewsDialog(nurseryId);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Colors.red),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                          'Confirmer la suppression'),
                                      content:
                                          const Text('Supprimer cet avis ?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Annuler')),
                                        ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Supprimer')),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    final parentId = Provider.of<AppState>(
                                            context,
                                            listen: false)
                                        .user
                                        ?.id;
                                    final res =
                                        await ReviewServiceWeb.deleteReview(
                                            reviewId: r['id'],
                                            parentId: parentId ?? '');
                                    if (res['success'] == true) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text('Avis supprimé'),
                                                backgroundColor: Colors.green));
                                      }
                                      await _loadNurseries();
                                      Navigator.pop(context);
                                      await _showReviewsDialog(nurseryId);
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Erreur: ${res['error'] ?? 'Impossible de supprimer'}')));
                                      }
                                    }
                                  }
                                },
                              ),
                            ])
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'))
        ],
      ),
    );
  }

  Future<void> _showEditReviewDialog(Map<String, dynamic> review) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final parentId = appState.user?.id;
    double rating =
        (review['rating'] is num) ? (review['rating'] as num).toDouble() : 5.0;
    final commentController =
        TextEditingController(text: review['comment'] ?? '');
    if (parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous devez être connecté pour modifier un avis')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier mon avis'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (dialogContext, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Notez la garderie (0.5 - 5.0)'),
                Slider(
                  value: rating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: rating.toStringAsFixed(1),
                  onChanged: (v) {
                    setState(() => rating = v);
                  },
                ),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'Votre commentaire (optionnel)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await ReviewServiceWeb.editReview(
                reviewId: review['id'],
                parentId: parentId,
                rating: double.parse(rating.toStringAsFixed(1)),
                comment: commentController.text.isNotEmpty
                    ? commentController.text
                    : null,
              );

              if (res['success'] == true) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Avis modifié'),
                        backgroundColor: Colors.green),
                  );
                  await _loadNurseries();
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Erreur: ${res['error'] ?? 'Impossible de modifier'}')),
                  );
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _contactNursery(Map<String, dynamic> nursery) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final parentId = appState.user?.id;

    if (parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous devez être connecté pour contacter une garderie')),
      );
      return;
    }

    try {
      print('💬 Initiating conversation with nursery: ${nursery['id']}');
      
      // Navigate to chat list screen with context that we're starting a conversation
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatListScreen(
              userId: parentId,
              userType: 'parent',
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error contacting nursery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final String? subtitle;
  final bool isUnread;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.time,
    this.subtitle,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? const Color(0xFF00BFA5) : Colors.grey[200]!,
          width: isUnread ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF00BFA5),
                shape: BoxShape.circle,
              ),
            ),
          if (isUnread) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
