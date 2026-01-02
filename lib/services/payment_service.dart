import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String _baseUrl = 'http://localhost:3000/api';

  // Obtenir le statut de paiement pour un parent
  Future<Map<String, dynamic>> getPaymentStatus(String parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/parent/$parentId/current'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load payment status');
      }
    } catch (e) {
      print('Error getting payment status: $e');
      throw Exception('Error: $e');
    }
  }

  // Effectuer un paiement
  Future<Map<String, dynamic>> processPayment({
    required String enrollmentId,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    try {
      // Extraire les 4 derniers chiffres
      final lastDigits = cardNumber.length >= 4
          ? cardNumber.substring(cardNumber.length - 4)
          : cardNumber;

      final response = await http.post(
        Uri.parse('$_baseUrl/payments/process'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'enrollmentId': enrollmentId,
          'cardLastDigits': lastDigits,
          'expiryDate': expiryDate,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Payment failed');
      }
    } catch (e) {
      print('Error processing payment: $e');
      throw Exception('Error: $e');
    }
  }

  // Obtenir tous les paiements pour une garderie (suivi financier)
  Future<Map<String, dynamic>> getNurseryPayments(
    String nurseryId, {
    int? month,
    int? year,
  }) async {
    try {
      final currentDate = DateTime.now();
      final queryMonth = month ?? currentDate.month;
      final queryYear = year ?? currentDate.year;

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/payments/nursery/$nurseryId?month=$queryMonth&year=$queryYear'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load nursery payments');
      }
    } catch (e) {
      print('Error getting nursery payments: $e');
      throw Exception('Error: $e');
    }
  }

  // Obtenir l'historique des paiements d'un parent
  Future<List<dynamic>> getPaymentHistory(String parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/parent/$parentId/history'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['payments'] ?? [];
      } else {
        throw Exception('Failed to load payment history');
      }
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }

  // Obtenir les statistiques financières de la garderie
  Future<Map<String, dynamic>> getNurseryFinancialStats(
    String nurseryId, {
    int? month,
    int? year,
  }) async {
    try {
      final currentDate = DateTime.now();
      final queryMonth = month ?? currentDate.month;
      final queryYear = year ?? currentDate.year;

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/payments/nursery/$nurseryId/stats?month=$queryMonth&year=$queryYear'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load financial stats');
      }
    } catch (e) {
      print('Error getting financial stats: $e');
      throw Exception('Error: $e');
    }
  }

  // Générer les paiements du mois pour tous les enrollments acceptés
  Future<Map<String, dynamic>> generateMonthlyPayments() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/generate-monthly'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate monthly payments');
      }
    } catch (e) {
      print('Error generating monthly payments: $e');
      throw Exception('Error: $e');
    }
  }

  // Formater le montant en TND
  String formatAmount(dynamic amount) {
    if (amount == null) return '0 TND';
    final value =
        amount is String ? double.tryParse(amount) ?? 0 : amount.toDouble();
    return '${value.toStringAsFixed(2)} TND';
  }

  // Obtenir le nom du mois en français
  String getMonthName(int month) {
    const months = [
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
    return month >= 1 && month <= 12 ? months[month - 1] : 'Mois invalide';
  }

  // Valider le numéro de carte (format basique)
  bool validateCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\s+'), '');
    return cleaned.length >= 13 &&
        cleaned.length <= 19 &&
        RegExp(r'^\d+$').hasMatch(cleaned);
  }

  // Valider la date d'expiration
  bool validateExpiryDate(String expiryDate) {
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiryDate)) return false;

    final parts = expiryDate.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    final expiry = DateTime(2000 + year, month);
    return expiry.isAfter(now);
  }

  // Valider le CVV
  bool validateCVV(String cvv) {
    return RegExp(r'^\d{3,4}$').hasMatch(cvv);
  }

  // Masquer le numéro de carte
  String maskCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < 4) return cardNumber;
    return '**** **** **** ${cleaned.substring(cleaned.length - 4)}';
  }
}
