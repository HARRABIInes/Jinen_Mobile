class Message {
  final String id;
  final String expediteurId;
  final String destinataireId;
  final String contenu;
  final DateTime dateEnvoi;
  final bool estLu;

  Message({
    required this.id,
    required this.expediteurId,
    required this.destinataireId,
    required this.contenu,
    required this.dateEnvoi,
    this.estLu = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expediteurId': expediteurId,
      'destinataireId': destinataireId,
      'contenu': contenu,
      'dateEnvoi': dateEnvoi.toIso8601String(),
      'estLu': estLu,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      expediteurId: json['expediteurId'],
      destinataireId: json['destinataireId'],
      contenu: json['contenu'],
      dateEnvoi: DateTime.parse(json['dateEnvoi']),
      estLu: json['estLu'] ?? false,
    );
  }

  Message copyWith({
    String? id,
    String? expediteurId,
    String? destinataireId,
    String? contenu,
    DateTime? dateEnvoi,
    bool? estLu,
  }) {
    return Message(
      id: id ?? this.id,
      expediteurId: expediteurId ?? this.expediteurId,
      destinataireId: destinataireId ?? this.destinataireId,
      contenu: contenu ?? this.contenu,
      dateEnvoi: dateEnvoi ?? this.dateEnvoi,
      estLu: estLu ?? this.estLu,
    );
  }
}
