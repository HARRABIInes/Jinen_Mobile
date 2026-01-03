import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/nursery_performance_service.dart';

class NurseryPerformanceScreen extends StatefulWidget {
  const NurseryPerformanceScreen({super.key});

  @override
  State<NurseryPerformanceScreen> createState() =>
      _NurseryPerformanceScreenState();
}

class _NurseryPerformanceScreenState extends State<NurseryPerformanceScreen> {
  late Future<Map<String, dynamic>> _performanceData;
  String _nurseryId = '';

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _nurseryId = appState.nurseries.isNotEmpty ? appState.nurseries.first.id : '';
    
    if (_nurseryId.isNotEmpty) {
      _performanceData =
          Future.value(NurseryPerformanceService.getNurseryReviews(_nurseryId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        backgroundColor: const Color(0xFF667EEA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _nurseryId.isEmpty
          ? const Center(
              child: Text('Aucune garderie sélectionnée'),
            )
          : FutureBuilder<Map<String, dynamic>>(
              future: _performanceData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }

                final data = snapshot.data ?? {};
                final averageRating = data['averageRating'] as double? ?? 0.0;
                final totalReviews = data['totalReviews'] as int? ?? 0;
                final reviews =
                    List<Map<String, dynamic>>.from(data['reviews'] ?? []);
                final ratingDistribution =
                    Map<int, int>.from(data['ratingDistribution'] ?? {});

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Moyenne des Ratings
                      _buildAverageRatingSection(
                        averageRating,
                        totalReviews,
                      ),
                      const SizedBox(height: 24),

                      // Distribution des ratings
                      _buildRatingDistributionSection(
                        ratingDistribution,
                        totalReviews,
                      ),
                      const SizedBox(height: 24),

                      // Commentaires Section
                      _buildCommentsSection(reviews),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAverageRatingSection(double averageRating, int totalReviews) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Moyenne des Évaluations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                averageRating.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.floor()
                            ? Icons.star
                            : (index < averageRating ? Icons.star_half : Icons.star_border),
                        size: 20,
                        color: Colors.amber,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'sur 5.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Basée sur $totalReviews avis',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistributionSection(
    Map<int, int> distribution,
    int totalReviews,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribution des Évaluations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (index) {
          final rating = 5 - index;
          final count = distribution[rating] ?? 0;
          final percentage =
              totalReviews > 0 ? (count / totalReviews * 100) : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Stars
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ),
                const SizedBox(width: 16),
                // Progress bar
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalReviews > 0 ? percentage / 100 : 0,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getRatingColor(rating),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Count
                SizedBox(
                  width: 60,
                  child: Text(
                    '$count (${percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCommentsSection(List<Map<String, dynamic>> reviews) {
    final reviewsWithComments =
        reviews.where((r) => r['comment'] != null && r['comment'].toString().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Commentaires',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${reviewsWithComments.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667EEA),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (reviewsWithComments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun commentaire pour le moment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviewsWithComments.length,
            itemBuilder: (context, index) {
              final review = reviewsWithComments[index];
              return _buildCommentCard(review);
            },
          ),
      ],
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> review) {
    final parentName = review['parentName'] ?? 'Parent Anonyme';
    
    // Parse rating safely (it might be string or number) - keep as double
    final ratingValue = review['rating'];
    print('🔍 DEBUG Rating: $ratingValue (type: ${ratingValue.runtimeType})');
    
    final ratingDouble = ratingValue is double
        ? ratingValue
        : (ratingValue is int 
            ? (ratingValue).toDouble()
            : double.tryParse(ratingValue.toString()) ?? 0.0);
    
    print('🔍 DEBUG Parsed Double: $ratingDouble');
    
    // For display, show the full rating (not just the integer part)
    final ratingInt = ratingDouble.floor();
    
    final comment = review['comment'] ?? '';
    final createdAt = review['createdAt'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec nom et stars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parentName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < ratingInt ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRatingColor(ratingInt).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${ratingDouble.toStringAsFixed(1)}/5',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(ratingInt),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Comment text
            Text(
              comment,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Date
            Text(
              _formatDate(createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) {
      return Colors.green;
    } else if (rating >= 3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return "Aujourd'hui";
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return 'Il y a $months mois';
      } else {
        final years = (difference.inDays / 365).floor();
        return 'Il y a $years an${years > 1 ? 's' : ''}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
