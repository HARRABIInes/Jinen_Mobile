import 'notification.dart';
import 'enfant.dart';
import 'utilisateur.dart';

class Directeur extends Utilisateur {
  Directeur({
    required super.id,
    required super.nom,
    required super.email,
    required super.motDePasse,
  });

  void creerProfilGarderie() {}
  void mettreAJourProfil() {}
  void gererComptesInscrits() {}
  void ajouterDevoir(Enfant enfant) {}
  void envoyerEtatEnfant(Enfant enfant) {}
  void mettreAJourDisponibilite() {}
  void envoyerNotification(NotificationModel n) {}
  @override
  void sAuthentifier() {
    // Implémentation simple : TODO remplacer par logique d'authentification
  }

  @override
  void creerCompte() {
    // Implémentation simple : TODO remplacer par logique de création de compte
  }
}
