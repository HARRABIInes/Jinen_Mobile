import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/review_service_web.dart';
import '../models/review.dart';
import '../models/nursery.dart';
import 'enrollment_screen.dart';

class NurseryDetails extends StatefulWidget {
  const NurseryDetails({super.key});

  @override
  State<NurseryDetails> createState() => _NurseryDetailsState();
}

class _NurseryDetailsState extends State<NurseryDetails> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final nursery = appState.selectedNursery;

    if (nursery != null) {
      setState(() => _isLoadingReviews = true);
      final res = await ReviewServiceWeb.getNurseryReviews(nursery.id);
      setState(() {
        _reviews = res['success'] == true 
            ? List<Map<String, dynamic>>.from(res['reviews'] ?? [])
            : [];
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final nursery = appState.selectedNursery;

    if (nursery == null) {
      return const Scaffold(
        body: Center(child: Text('Aucune garderie sélectionnée')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
              ),
              onPressed: () => appState.setScreen(ScreenType.search),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite_border,
                      color: Color(0xFF2C3E50)),
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.share, color: Color(0xFF2C3E50)),
                ),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: nursery.photo.isNotEmpty
                  ? Image.network(
                      nursery.photo,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image,
                              size: 64, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.image, size: 64, color: Colors.grey),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info Card
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating and reviews
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 18, color: Color(0xFFFFB300)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${nursery.rating}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${nursery.reviewCount} avis)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          nursery.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Address
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 20, color: Color(0xFF00BFA5)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nursery.address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.directions_walk,
                                size: 20, color: Color(0xFF00BFA5)),
                            const SizedBox(width: 8),
                            Text(
                              'À ${nursery.distance} km de vous',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Available spots
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00BFA5).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF00BFA5)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '✓ ${nursery.availableSpots} places disponibles sur ${nursery.totalSpots}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00BFA5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick Info Cards
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.schedule,
                            iconColor: const Color(0xFF00BFA5),
                            label: 'Horaires',
                            value: nursery.hours,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.people,
                            iconColor: const Color(0xFF00ACC1),
                            label: 'Personnel',
                            value: '${nursery.staff} personnes',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 1),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.child_care,
                            iconColor: const Color(0xFF9C27B0),
                            label: 'Âge',
                            value: nursery.ageRange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.euro_symbol,
                            iconColor: const Color(0xFFFF9800),
                            label: 'Prix/mois',
                            value: '${nursery.price} TND',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tabs
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: const TabBar(
                            labelColor: Color(0xFF00BFA5),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Color(0xFF00BFA5),
                            tabs: [
                              Tab(text: 'À propos'),
                              Tab(text: 'Activités'),
                              Tab(text: 'Avis'),
                            ],
                          ),
                        ),
                        Container(
                          height: 300,
                          color: Colors.white,
                          child: TabBarView(
                            children: [
                              // À propos
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      nursery.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Activités
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: nursery.activities
                                      .map((activity) => Chip(
                                            label: Text(activity),
                                            backgroundColor:
                                                const Color(0xFF00BFA5)
                                                    .withOpacity(0.1),
                                            labelStyle: const TextStyle(
                                              color: Color(0xFF00BFA5),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),

                              // Avis
                              _isLoadingReviews
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : _reviews.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.reviews,
                                                    size: 64,
                                                    color: Colors.grey[300]),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Aucun avis pour le moment',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.all(20),
                                          itemCount: _reviews.length,
                                          itemBuilder: (context, index) {
                                            final review = _reviews[index];
                                            final parentName = review['parentName'] as String? ?? '';
                                            final ratingValue = review['rating'];
                                            final rating = ratingValue is String 
                                              ? double.tryParse(ratingValue) ?? 0.0
                                              : ratingValue is int 
                                                ? (ratingValue as int).toDouble()
                                                : (ratingValue as double? ?? 0.0);
                                            final comment = review['comment'] as String? ?? '';
                                            return Card(
                                              margin: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundColor:
                                                              const Color(
                                                                  0xFF00BFA5),
                                                          child: Text(
                                                            parentName.isNotEmpty ? parentName[0]
                                                                .toUpperCase() : '?',
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                parentName,
                                                                style:
                                                                    const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              Row(
                                                                children: List
                                                                    .generate(
                                                                  5,
                                                                  (i) => Icon(
                                                                    i < rating.floor()
                                                                        ? Icons
                                                                            .star
                                                                        : Icons
                                                                            .star_border,
                                                                    size: 16,
                                                                    color: Colors
                                                                        .amber,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      comment,
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Buttons
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bouton "Laisser un avis"
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF00BFA5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showLeaveReviewDialog(nursery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Laisser un avis',
                      style: TextStyle(
                        color: Color(0xFF00BFA5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bouton "Inscire mon enfant"
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EnrollmentScreen(
                            nurseryId: nursery.id,
                            nurseryName: nursery.name,
                            price: nursery.price,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Inscrire mon enfant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
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

  Future<void> _showLeaveReviewDialog(Nursery nursery) async {
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
        title: Text('Laisser un avis - ${nursery.name}'),
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
                nurseryId: nursery.id,
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
                  _loadReviews();
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
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
