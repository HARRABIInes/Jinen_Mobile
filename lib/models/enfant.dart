import 'devoir.dart';

class Enfant {
  final int idEnfant;
  final String nom;
  final int age;

  Enfant({
    required this.idEnfant,
    required this.nom,
    required this.age,
  });

  void mettreAJourEtat() {}
  void ajouterDevoir(Devoir d) {}
}
