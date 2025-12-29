import 'programme.dart';
import 'activite.dart';

class Garderie {
  final int idGarderie;
  final String nom;
  final String adresse;
  final double tarif;
  final double disponibilite;
  final String description;

  Garderie({
    required this.idGarderie,
    required this.nom,
    required this.adresse,
    required this.tarif,
    required this.disponibilite,
    required this.description,
  });

  void mettreAJourInfos() {}
  void publierProgramme(Programme p) {}
  void ajouterActivite(Activite a) {}
}
