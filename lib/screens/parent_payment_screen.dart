import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/payment_service.dart';

class ParentPaymentScreen extends StatefulWidget {
  const ParentPaymentScreen({super.key});

  @override
  State<ParentPaymentScreen> createState() => _ParentPaymentScreenState();
}

class _ParentPaymentScreenState extends State<ParentPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  bool _isLoading = false;
  List<dynamic> _pendingPayments = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentStatus();
  }

  Future<void> _loadPaymentStatus() async {
    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final parentId = appState.user?.id ?? '';

      final result = await _paymentService.getPaymentStatus(parentId);
      setState(() {
        _pendingPayments = result['pendingPayments'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processPayment(Map<String, dynamic> payment) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await _paymentService.processPayment(
        enrollmentId: payment['enrollment_id'].toString(),
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expiryDate: _expiryDateController.text,
        cvv: _cvvController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paiement effectué avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPaymentStatus();
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de paiement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentDialog(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payment, color: Color(0xFF6366F1)),
            ),
            const SizedBox(width: 12),
            const Text('Effectuer le paiement'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Résumé du paiement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paiement pour: ${payment['child_name']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Garderie: ${payment['nursery_name']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Mois: ${_paymentService.getMonthName(payment['payment_month'])} ${payment['payment_year']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Montant:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _paymentService.formatAmount(payment['amount']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Numéro de carte
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de carte',
                    hintText: '1234 5678 9012 3456',
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Numéro de carte requis';
                    }
                    if (!_paymentService.validateCardNumber(value)) {
                      return 'Numéro de carte invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date d'expiration et CVV
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        decoration: InputDecoration(
                          labelText: 'Date d\'expiration',
                          hintText: 'MM/AA',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryDateInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Date requise';
                          }
                          if (!_paymentService.validateExpiryDate(value)) {
                            return 'Date invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'CVV requis';
                          }
                          if (!_paymentService.validateCVV(value)) {
                            return 'CVV invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Note de sécurité
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Paiement sécurisé SSL',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _processPayment(payment),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Confirmer le paiement'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _cardNumberController.clear();
    _expiryDateController.clear();
    _cvvController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Paiements'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPaymentStatus,
              child: _pendingPayments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun paiement en attente',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tous vos paiements sont à jour',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingPayments.length,
                      itemBuilder: (context, index) {
                        final payment = _pendingPayments[index];
                        return _buildPaymentCard(payment);
                      },
                    ),
            ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment['child_name'] ?? 'Enfant',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      payment['nursery_name'] ?? 'Garderie',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Non payé',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${_paymentService.getMonthName(payment['payment_month'])} ${payment['payment_year']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Montant à payer:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                _paymentService.formatAmount(payment['amount']),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showPaymentDialog(payment),
              icon: const Icon(Icons.payment),
              label: const Text('Payer maintenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}

// Input formatter pour le numéro de carte (ajoute des espaces tous les 4 chiffres)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Input formatter pour la date d'expiration (ajoute un slash après 2 chiffres)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
