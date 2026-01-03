import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/app_state.dart';

class NurseryProgramScreen extends StatefulWidget {
  const NurseryProgramScreen({super.key});

  @override
  State<NurseryProgramScreen> createState() => _NurseryProgramScreenState();
}

class _NurseryProgramScreenState extends State<NurseryProgramScreen> {
  List<Map<String, dynamic>> _scheduleItems = [];
  bool _isEditing = false;
  bool _isLoading = true;
  String? _nurseryId;

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    setState(() => _isLoading = true);
    
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.user;
    
    if (user != null) {
      try {
        // Get nursery ID from owner
        final nurseryResponse = await http.get(
          Uri.parse('http://localhost:3000/api/nurseries/owner/${user.id}'),
        );
        
        if (nurseryResponse.statusCode == 200) {
          final nurseryData = jsonDecode(nurseryResponse.body);
          if (nurseryData['success'] == true && nurseryData['nursery'] != null) {
            _nurseryId = nurseryData['nursery']['id'];
            
            // Load schedule
            final scheduleResponse = await http.get(
              Uri.parse('http://localhost:3000/api/nurseries/$_nurseryId/schedule'),
            );
            
            if (scheduleResponse.statusCode == 200) {
              final scheduleData = jsonDecode(scheduleResponse.body);
              if (scheduleData['success'] == true) {
                setState(() {
                  _scheduleItems = List<Map<String, dynamic>>.from(scheduleData['schedule'] ?? []);
                  _isLoading = false;
                });
                return;
              }
            }
          }
        }
      } catch (e) {
        print('Error loading program: $e');
      }
    }
    
    setState(() {
      _scheduleItems = [];
      _isLoading = false;
    });
  }

  Future<void> _addActivity(BuildContext context) async {
    final timeController = TextEditingController();
    final activityController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter une activité'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Horaire (ex: 09:00)',
                  hintText: '09:00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: activityController,
                decoration: InputDecoration(
                  labelText: 'Nom de l\'activité',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.event),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && _nurseryId != null) {
      if (timeController.text.isEmpty || activityController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir l\'horaire et le nom de l\'activité')),
        );
        return;
      }

      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/api/nurseries/$_nurseryId/schedule'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'timeSlot': timeController.text,
            'activityName': activityController.text,
            'description': descriptionController.text,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activité ajoutée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProgram();
        } else {
          throw Exception('Erreur serveur');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editActivity(Map<String, dynamic> item) async {
    final timeController = TextEditingController(text: item['timeSlot'] ?? item['time_slot'] ?? '');
    final activityController = TextEditingController(text: item['activityName'] ?? item['activity_name'] ?? '');
    final descriptionController = TextEditingController(text: item['description'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifier l\'activité'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Horaire',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: activityController,
                decoration: InputDecoration(
                  labelText: 'Nom de l\'activité',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.event),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final scheduleId = item['id'];
        final response = await http.put(
          Uri.parse('http://localhost:3000/api/nurseries/schedule/$scheduleId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'timeSlot': timeController.text,
            'activityName': activityController.text,
            'description': descriptionController.text,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activité modifiée'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProgram();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteActivity(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'activité ?'),
        content: Text('Voulez-vous vraiment supprimer "${item['activityName'] ?? item['activity_name']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final scheduleId = item['id'];
        final response = await http.delete(
          Uri.parse('http://localhost:3000/api/nurseries/schedule/$scheduleId'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activité supprimée'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProgram();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Programme Journalier',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit_rounded),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
            tooltip: _isEditing ? 'Terminer' : 'Modifier',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isEditing ? 'Mode édition activé' : '${_scheduleItems.length} activité(s)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste des activités
                Expanded(
                  child: _scheduleItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune activité programmée',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Appuyez sur + pour ajouter',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProgram,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _scheduleItems.length,
                            itemBuilder: (context, index) {
                              final item = _scheduleItems[index];
                              return _buildScheduleCard(item);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addActivity(context),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> item) {
    final timeSlot = item['timeSlot'] ?? item['time_slot'] ?? '';
    final activityName = item['activityName'] ?? item['activity_name'] ?? '';
    final description = item['description'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _isEditing ? () => _editActivity(item) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeSlot,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activityName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteActivity(item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
