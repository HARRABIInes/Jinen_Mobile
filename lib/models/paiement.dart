class Paiement {
  final int idPaiement;
  final double montant;
  final DateTime datePaiement;
  final String statut;

  Paiement({
    required this.idPaiement,
    required this.montant,
    required this.datePaiement,
    required this.statut,
  });
}
