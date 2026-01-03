import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/nursery.dart';
import '../services/enrollment_service_web.dart';
import '../widgets/rate_nursery_dialog.dart';
import 'chat_list_screen.dart';

class ParentEnrollmentsScreen extends StatefulWidget {
  const ParentEnrollmentsScreen({super.key});

  @override
  State<ParentEnrollmentsScreen> createState() =>
      _ParentEnrollmentsScreenState();
}

class _ParentEnrollmentsScreenState extends State<ParentEnrollmentsScreen> {
  final EnrollmentServiceWeb _enrollmentService = EnrollmentServiceWeb();
  List<Map<String, dynamic>> _enrollments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() => _isLoading = true);

    // Récupérer l'ID du parent connecté
    final appState = Provider.of<AppState>(context, listen: false);
    final parentId = appState.user?.id;
    
    if (parentId != null) {
      final enrollments = await _enrollmentService.getEnrollmentsByParent(parentId);
      setState(() {
        _enrollments = enrollments;
        _isLoading = false;
      });
    } else {
      setState(() {
        _enrollments = [];
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'active':
        return 'Acceptée';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'active':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes inscriptions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollments.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadEnrollments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _enrollments.length,
                    itemBuilder: (context, index) {
                      final enrollment = _enrollments[index];
                      return _buildEnrollmentCard(enrollment);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune inscription',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore inscrit d\'enfant',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentCard(Map<String, dynamic> enrollment) {
    final status = enrollment['status'] ?? 'pending';
    final child = enrollment['child'] ?? {};
    final nursery = enrollment['nursery'] ?? {};
    final startDate = enrollment['startDate'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    child['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 16,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Nursery info
            _buildInfoRow(
              Icons.business,
              'Garderie',
              nursery['name'] ?? 'N/A',
            ),
            const SizedBox(height: 8),

            // Child age
            _buildInfoRow(
              Icons.child_care,
              'Âge',
              '${child['age'] ?? 'N/A'} ans',
            ),
            const SizedBox(height: 8),

            // Start date
            _buildInfoRow(
              Icons.calendar_today,
              'Date de début',
              startDate.isNotEmpty ? startDate.split('T')[0] : 'Non spécifiée',
            ),

            // Additional info for pending status
            if (status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En attente de validation par la garderie',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Rating button for active enrollments
            if (status.toLowerCase() == 'active') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final appState = Provider.of<AppState>(context, listen: false);
                        final parentId = appState.user?.id;
                        
                        if (parentId != null && nursery['id'] != null) {
                          // Create a Nursery object from enrollment data
                          showDialog(
                            context: context,
                            builder: (context) => RateNurseryDialog(
                              nursery: _createNurseryFromData(nursery),
                              parentId: parentId,
                              onReviewSubmitted: () {
                                // Optionally refresh enrollments
                              },
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Noter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final appState = Provider.of<AppState>(context, listen: false);
                        final parentId = appState.user?.id;
                        
                        if (parentId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vous devez être connecté pour contacter une garderie'),
                            ),
                          );
                          return;
                        }
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatListScreen(
                              userId: parentId,
                              userType: 'parent',
                              targetNurseryId: nursery['id'],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Contacter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF00BFA5),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }

  Nursery _createNurseryFromData(Map<String, dynamic> data) {
    return Nursery(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      city: data['city'],
      phone: data['phone'],
      email: data['email'],
      price: double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
      totalSpots: data['totalSpots'] ?? 0,
      availableSpots: data['availableSpots'] ?? 0,
      rating: double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0,
      ageRange: data['ageRange'] ?? '',
      photo: data['photo'] ?? data['photoUrl'] ?? '',
      distance: 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      hours: data['hours'] ?? '',
      activities: data['activities'] is List ? List<String>.from(data['activities']) : [],
      staff: data['staff'] ?? 0,
    );
  }
}
