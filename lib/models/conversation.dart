import 'message.dart';

class Conversation {
  final String id;
  final String parentId;
  final String directeurId;
  final String garderieId;
  final List<Message> messages;
  final DateTime derniereMiseAJour;
  final int messagesNonLus;

  Conversation({
    required this.id,
    required this.parentId,
    required this.directeurId,
    required this.garderieId,
    this.messages = const [],
    required this.derniereMiseAJour,
    this.messagesNonLus = 0,
  });

  Message? get dernierMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'directeurId': directeurId,
      'garderieId': garderieId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'derniereMiseAJour': derniereMiseAJour.toIso8601String(),
      'messagesNonLus': messagesNonLus,
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      parentId: json['parentId'],
      directeurId: json['directeurId'],
      garderieId: json['garderieId'],
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => Message.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      derniereMiseAJour: DateTime.parse(json['derniereMiseAJour']),
      messagesNonLus: json['messagesNonLus'] ?? 0,
    );
  }

  Conversation copyWith({
    String? id,
    String? parentId,
    String? directeurId,
    String? garderieId,
    List<Message>? messages,
    DateTime? derniereMiseAJour,
    int? messagesNonLus,
  }) {
    return Conversation(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      directeurId: directeurId ?? this.directeurId,
      garderieId: garderieId ?? this.garderieId,
      messages: messages ?? this.messages,
      derniereMiseAJour: derniereMiseAJour ?? this.derniereMiseAJour,
      messagesNonLus: messagesNonLus ?? this.messagesNonLus,
    );
  }
}
