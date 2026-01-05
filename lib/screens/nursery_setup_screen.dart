import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class NurserySetupScreen extends StatefulWidget {
  const NurserySetupScreen({super.key});

  @override
  State<NurserySetupScreen> createState() => _NurserySetupScreenState();
}

class _NurserySetupScreenState extends State<NurserySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form controllers
  final _nurseryNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalSpotsController = TextEditingController();
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();
  final _openingTimeController = TextEditingController();
  final _closingTimeController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Selected values
  final List<String> _selectedActivities = [];
  final Map<String, bool> _selectedFacilities = {
    'Jardin extérieur': false,
    'Aire de jeux': false,
    'Salle de repos': false,
    'Cuisine équipée': false,
    'Climatisation': false,
    'Caméras de surveillance': false,
  };

  final List<String> _availableActivities = [
    'Arts plastiques',
    'Musique',
    'Sport',
    'Lecture',
    'Jeux éducatifs',
    'Danse',
    'Jardinage',
    'Cuisine',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nurseryNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _priceController.dispose();
    _totalSpotsController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validate current page before moving to next
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = appState.user;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Prepare facilities list
      final facilities = _selectedFacilities.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // Calculate age range
      final ageRange =
          '${_minAgeController.text} - ${_maxAgeController.text} ans';

      // Calculate hours
      final hours =
          '${_openingTimeController.text} - ${_closingTimeController.text}';

      // Create nursery
      final nursery = await appState.nurseryService.createNursery(
        ownerId: user.id,
        name: _nurseryNameController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        address: _addressController.text,
        city: _cityController.text,
        postalCode: _postalCodeController.text.isNotEmpty
            ? _postalCodeController.text
            : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        hours: hours,
        pricePerMonth: double.parse(_priceController.text),
        totalSpots: int.parse(_totalSpotsController.text),
        ageRange: ageRange,
        imageUrl: _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text
            : null,
        facilities: facilities,
        activities: _selectedActivities,
      );

      if (nursery != null) {
        // Update app state
        appState.completeNurserySetup();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil de garderie créé avec succès !'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else {
        throw Exception('Failed to create nursery');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: _currentPage > 0
                          ? IconButton(
                              onPressed: _previousPage,
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              padding: EdgeInsets.zero,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Créer votre profil',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              3,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentPage == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        _buildBasicInfoPage(),
                        _buildDetailsPage(),
                        _buildActivitiesPage(),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Button
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_currentPage == 2 ? _handleSubmit : _nextPage),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey,
                      ).copyWith(
                        backgroundColor:
                            WidgetStateProperty.all(Colors.transparent),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  _currentPage == 2 ? 'Terminer' : 'Suivant',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
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

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de base',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Présentez votre garderie',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Image URL
          _buildTextField(
            label: 'URL de l\'image de la garderie',
            controller: _imageUrlController,
            hint: 'https://exemple.com/image.jpg',
            icon: Icons.image,
          ),
          const SizedBox(height: 12),
          if (_imageUrlController.text.isNotEmpty)
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  _imageUrlController.text,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Image non disponible',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Nursery Name
          _buildTextField(
            label: 'Nom de la garderie *',
            controller: _nurseryNameController,
            hint: 'Les Petits Anges',
            icon: Icons.business,
            validator: (value) => value?.isEmpty ?? true ? 'Nom requis' : null,
          ),
          const SizedBox(height: 20),

          // Description
          _buildTextField(
            label: 'Description',
            controller: _descriptionController,
            hint:
                'Décrivez votre garderie, vos valeurs, votre approche pédagogique...',
            icon: Icons.description,
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          // Location Section
          const Text(
            'Localisation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),

          // Address
          _buildTextField(
            label: 'Adresse *',
            controller: _addressController,
            hint: '123 Rue de la République',
            icon: Icons.location_on,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Adresse requise' : null,
          ),
          const SizedBox(height: 16),

          // City and Postal Code
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  label: 'Ville *',
                  controller: _cityController,
                  hint: 'Tunis',
                  icon: Icons.location_city,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ville requise' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Code postal',
                  controller: _postalCodeController,
                  hint: '1000',
                  icon: Icons.pin_drop,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails pratiques',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Informations importantes pour les parents',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Phone
          _buildTextField(
            label: 'Téléphone *',
            controller: _phoneController,
            hint: '+216 XX XXX XXX',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Téléphone requis' : null,
          ),
          const SizedBox(height: 20),

          // Email
          _buildTextField(
            label: 'Email de contact',
            controller: _emailController,
            hint: 'contact@garderie.tn',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),

          // Price
          _buildTextField(
            label: 'Tarif mensuel (TND) *',
            controller: _priceController,
            hint: '250',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Tarif requis' : null,
          ),
          const SizedBox(height: 20),

          // Total Spots
          _buildTextField(
            label: 'Nombre total de places *',
            controller: _totalSpotsController,
            hint: '30',
            icon: Icons.people,
            keyboardType: TextInputType.number,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Nombre de places requis' : null,
          ),
          const SizedBox(height: 24),

          // Age Range
          const Text(
            'Tranche d\'âge acceptée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Âge minimum *',
                  controller: _minAgeController,
                  hint: '1',
                  icon: Icons.child_care,
                  keyboardType: TextInputType.number,
                  suffix: 'ans',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Âge maximum *',
                  controller: _maxAgeController,
                  hint: '5',
                  icon: Icons.child_friendly,
                  keyboardType: TextInputType.number,
                  suffix: 'ans',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Hours
          const Text(
            'Horaires d\'ouverture',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Ouverture *',
                  controller: _openingTimeController,
                  hint: '07:00',
                  icon: Icons.access_time,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Fermeture *',
                  controller: _closingTimeController,
                  hint: '18:00',
                  icon: Icons.access_time_filled,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Facilities
          const Text(
            'Équipements disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ..._selectedFacilities.keys.map((facility) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedFacilities[facility]!
                      ? const Color(0xFF667EEA).withOpacity(0.1)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFacilities[facility]!
                        ? const Color(0xFF667EEA)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: CheckboxListTile(
                  title: Text(
                    facility,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _selectedFacilities[facility]!
                          ? const Color(0xFF667EEA)
                          : const Color(0xFF374151),
                    ),
                  ),
                  value: _selectedFacilities[facility],
                  onChanged: (value) {
                    setState(() {
                      _selectedFacilities[facility] = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF667EEA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivitiesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activités proposées',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez les activités que vous proposez',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableActivities.map((activity) {
              final isSelected = _selectedActivities.contains(activity);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedActivities.remove(activity);
                    } else {
                      _selectedActivities.add(activity);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF667EEA)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF667EEA)
                          : const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      Text(
                        activity,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF667EEA).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vous êtes presque prêt !',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Une fois votre profil créé, vous pourrez le modifier à tout moment depuis votre tableau de bord.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
