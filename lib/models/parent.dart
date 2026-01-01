import 'enfant.dart';
import 'garderie.dart';
import 'paiement.dart';
import 'avis.dart';
import 'utilisateur.dart';

class Parent extends Utilisateur {
  Parent({
    required super.id,
    required super.nom,
    required super.email,
    required super.motDePasse,
  });

  void ajouterEnfant(Enfant enfant) {}
  void consulterProfilGarderie(Garderie g) {}
  void inscrireEnfant(Enfant enfant, Garderie g) {}
  void payerEnLigne(Paiement p) {}
  void consulterEspaceEnfant(Enfant enfant) {}
  void laisserAvis(Avis a) {}
  @override
  void sAuthentifier() {
    // Implémentation basique : TODO remplacer par logique réelle d'authentification
  }

  @override
  void creerCompte() {
    // Implémentation basique : TODO remplacer par logique réelle de création de compte
  }
}
