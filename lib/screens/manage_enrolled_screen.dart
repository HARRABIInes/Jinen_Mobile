import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/enrolled_children_service_web.dart';
import 'chat_list_screen.dart';

class ManageEnrolledScreen extends StatefulWidget {
  const ManageEnrolledScreen({super.key});

  @override
  State<ManageEnrolledScreen> createState() => _ManageEnrolledScreenState();
}

class _ManageEnrolledScreenState extends State<ManageEnrolledScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEnrolledChildren();
  }

  Future<void> _loadEnrolledChildren() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final nurseries = appState.nurseries;

    if (nurseries.isEmpty) {
      setState(() {
        _error = 'No nursery found';
        _isLoading = false;
      });
      return;
    }

    final nurseryId = nurseries.first.id;

    print('📋 Loading enrolled children for nursery: $nurseryId');

    final result = await EnrolledChildrenService.getEnrolledChildren(nurseryId);
    
    setState(() {
      _data = result;
      _isLoading = false;
      if (result['success'] != true) {
        _error = result['error'] ?? 'Unknown error';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Enrolled Children'),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadEnrolledChildren();
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : _data == null || (_data!['parents'] as List).isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.group_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No enrolled children yet'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _isLoading = true);
                              _loadEnrolledChildren();
                            },
                            child: const Text('Refresh'),
                          )
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() => _isLoading = true);
                        await _loadEnrolledChildren();
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Summary Card
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          const Text(
                                            'Total Parents',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${_data!['totalParents'] ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text(
                                            'Total Children',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${_data!['totalChildren'] ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Parents and Children List
                          const Text(
                            'Enrolled Parents & Children',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // List of parents with their children
                          ...(_data!['parents'] as List<dynamic>).map<Widget>((parent) {
                            return _buildParentCard(
                              parent as Map<String, dynamic>,
                            );
                          }),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildParentCard(Map<String, dynamic> parent) {
    final children = (parent['children'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parent['parentName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            parent['parentEmail'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (parent['parentPhone'] != null && (parent['parentPhone'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          parent['parentPhone'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Contact button
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final appState = Provider.of<AppState>(context, listen: false);
                        final nurseries = appState.nurseries;
                        
                        if (nurseries.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nursery not found')),
                          );
                          return;
                        }

                        final nurseryId = nurseries.first.id;
                        final ownerId = appState.user?.id;

                        if (ownerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You must be logged in')),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatListScreen(
                              userId: ownerId,
                              userType: 'directeur',
                              targetNurseryId: nurseryId,
                              targetParentId: parent['parentId'],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.message, size: 16),
                      label: const Text('Contacter ce parent'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Children List
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Children:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...children.map((child) {
                    return _buildChildItem(child);
                  }),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No children enrolled',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChildItem(Map<String, dynamic> child) {
    final statusColor = _getStatusColor(child['enrollmentStatus']);
    final status = child['enrollmentStatus']?.toLowerCase() ?? 'unknown';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child['childName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Age: ${child['age'] ?? '?'} years',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (child['enrollmentStatus'] ?? 'unknown').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Birth Date: ${_formatDate(child['birthDate'])}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Enrolled: ${_formatDate(child['enrollmentDate'])}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            // Action buttons
            const SizedBox(height: 12),
            if (status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptEnrollment(child['enrollmentId']),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectEnrollment(child['enrollmentId']),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else if (status == 'active')
              ElevatedButton.icon(
                onPressed: () => _cancelEnrollment(child['enrollmentId']),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Cancel Enrollment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptEnrollment(String enrollmentId) async {
    final result = await EnrolledChildrenService.acceptEnrollment(enrollmentId);
    
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enrollment accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload data
        setState(() => _isLoading = true);
        _loadEnrolledChildren();
        
        // Notify AppState to refresh dashboard
        if (mounted) {
          Provider.of<AppState>(context, listen: false).notifyListeners();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectEnrollment(String enrollmentId) async {
    final result = await EnrolledChildrenService.rejectEnrollment(enrollmentId);
    
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enrollment rejected!'),
            backgroundColor: Colors.orange,
          ),
        );
        // Reload data
        setState(() => _isLoading = true);
        _loadEnrolledChildren();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelEnrollment(String enrollmentId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Enrollment'),
        content: const Text('Are you sure you want to cancel this enrollment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await EnrolledChildrenService.rejectEnrollment(enrollmentId);
      
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enrollment cancelled!'),
              backgroundColor: Colors.red,
            ),
          );
          // Reload data
          setState(() => _isLoading = true);
          _loadEnrolledChildren();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return '${parsed.day}/${parsed.month}/${parsed.year}';
      }
    } catch (e) {
      return 'N/A';
    }
    return 'N/A';
  }
}
