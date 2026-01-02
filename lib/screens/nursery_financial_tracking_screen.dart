import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/payment_service.dart';

class NurseryFinancialTrackingScreen extends StatefulWidget {
  const NurseryFinancialTrackingScreen({super.key});

  @override
  State<NurseryFinancialTrackingScreen> createState() =>
      _NurseryFinancialTrackingScreenState();
}

class _NurseryFinancialTrackingScreenState
    extends State<NurseryFinancialTrackingScreen> {
  final PaymentService _paymentService = PaymentService();

  bool _isLoading = false;
  List<dynamic> _payments = [];
  Map<String, dynamic> _stats = {};

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedFilter = 'tous'; // 'tous', 'paid', 'unpaid'

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final nurseryId = appState.user?.id ?? '';

      // Charger les paiements
      final paymentsResult = await _paymentService.getNurseryPayments(
        nurseryId,
        month: _selectedMonth,
        year: _selectedYear,
      );

      // Charger les statistiques
      final statsResult = await _paymentService.getNurseryFinancialStats(
        nurseryId,
        month: _selectedMonth,
        year: _selectedYear,
      );

      setState(() {
        _payments = paymentsResult['payments'] ?? [];
        _stats = statsResult['stats'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredPayments {
    if (_selectedFilter == 'tous') {
      return _payments;
    } else if (_selectedFilter == 'paid') {
      return _payments.where((p) => p['payment_status'] == 'paid').toList();
    } else {
      return _payments.where((p) => p['payment_status'] == 'unpaid').toList();
    }
  }

  Future<void> _showMonthYearPicker() async {
    final picked = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        selectedMonth: _selectedMonth,
        selectedYear: _selectedYear,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked['month']!;
        _selectedYear = picked['year']!;
      });
      _loadFinancialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi Financier'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header avec sélection de mois et statistiques
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Sélection du mois
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: _showMonthYearPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '${_paymentService.getMonthName(_selectedMonth)} $_selectedYear',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),

                // Statistiques
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Attendu',
                          _paymentService
                              .formatAmount(_stats['total_expected'] ?? 0),
                          Icons.trending_up,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Reçu',
                          _paymentService
                              .formatAmount(_stats['total_received'] ?? 0),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'En attente',
                          _paymentService
                              .formatAmount(_stats['total_pending'] ?? 0),
                          Icons.schedule,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // Barre de progression
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Taux de paiement',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(_stats['payment_percentage'] ?? 0).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_stats['payment_percentage'] ?? 0) / 100,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B981),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('Tous', 'tous'),
                const SizedBox(width: 8),
                _buildFilterChip('Payés', 'paid'),
                const SizedBox(width: 8),
                _buildFilterChip('Non payés', 'unpaid'),
                const Spacer(),
                Text(
                  '${_filteredPayments.length} enfant${_filteredPayments.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Liste des paiements
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun paiement',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFilter == 'tous'
                                  ? 'Aucune inscription pour ce mois'
                                  : _selectedFilter == 'paid'
                                      ? 'Aucun paiement reçu'
                                      : 'Tous les paiements sont à jour',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFinancialData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = _filteredPayments[index];
                            return _buildPaymentCard(payment);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF6366F1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final isPaid = payment['payment_status'] == 'paid';
    final statusColor = isPaid ? const Color(0xFF10B981) : Colors.orange;
    final statusIcon = isPaid ? Icons.check_circle : Icons.schedule;
    final statusText = isPaid ? 'Payé' : 'Non payé';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.child_care,
            color: statusColor,
            size: 28,
          ),
        ),
        title: Text(
          payment['child_name'] ?? 'Enfant',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Parent: ${payment['parent_name'] ?? 'N/A'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              payment['parent_email'] ?? '',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            if (isPaid && payment['payment_date'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Payé le ${_formatDate(payment['payment_date'])}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _paymentService.formatAmount(payment['amount']),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// Dialog pour sélectionner mois et année
class _MonthYearPickerDialog extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;

  const _MonthYearPickerDialog({
    required this.selectedMonth,
    required this.selectedYear,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    _month = widget.selectedMonth;
    _year = widget.selectedYear;
  }

  static const List<String> _monthNames = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre'
  ];

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - 2 + index);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Sélectionner la période'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _month,
            decoration: InputDecoration(
              labelText: 'Mois',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: List.generate(12, (index) {
              return DropdownMenuItem(
                value: index + 1,
                child: Text(_monthNames[index]),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() => _month = value);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _year,
            decoration: InputDecoration(
              labelText: 'Année',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: years.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(year.toString()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _year = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {'month': _month, 'year': _year});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
