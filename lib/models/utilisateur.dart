abstract class Utilisateur {
  final int id;
  final String nom;
  final String email;
  final String motDePasse;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.email,
    required this.motDePasse,
  });

  void sAuthentifier();
  void creerCompte();
}
