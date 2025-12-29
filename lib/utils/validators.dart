class Validators {
  // Validation de l'email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email requis';
    }

    // Regex pour validation email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide (exemple: nom@domaine.com)';
    }

    return null;
  }

  // Validation du téléphone tunisien
  static String? validateTunisianPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Numéro de téléphone requis';
    }

    // Enlever les espaces
    final cleanedValue = value.replaceAll(' ', '');

    // Regex pour numéro tunisien: +216 suivi de 8 chiffres
    final phoneRegex = RegExp(r'^\+216[0-9]{8}$');

    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Format invalide (exemple: +216 12345678)';
    }

    return null;
  }

  // Validation du nom (non vide, lettres seulement)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nom requis';
    }

    if (value.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }

    return null;
  }

  // Validation du mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe requis';
    }

    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }

    return null;
  }

  // Validation de la date de naissance
  static String? validateBirthDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date de naissance requise';
    }

    try {
      final parts = value.split('/');
      if (parts.length != 3) {
        return 'Format invalide (mm/dd/yyyy)';
      }

      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final date = DateTime(year, month, day);
      final now = DateTime.now();

      if (date.isAfter(now)) {
        return 'La date ne peut pas être dans le futur';
      }

      return null;
    } catch (e) {
      return 'Date invalide';
    }
  }

  // Validation du prix
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Prix requis';
    }

    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Prix invalide';
    }

    return null;
  }
}
