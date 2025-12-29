import 'dart:math';
import '../models/message.dart';
import '../models/conversation.dart';

class ChatService {
  // Simulation de stockage local (remplacer par base de données / API)
  final List<Conversation> _conversations = [];
  final Random _random = Random();

  // Récupérer toutes les conversations d'un utilisateur
  List<Conversation> getConversations(String userId) {
    return _conversations.where((conv) {
      return conv.parentId == userId || conv.directeurId == userId;
    }).toList()
      ..sort((a, b) => b.derniereMiseAJour.compareTo(a.derniereMiseAJour));
  }

  // Récupérer une conversation spécifique
  Conversation? getConversation(String conversationId) {
    try {
      return _conversations.firstWhere((conv) => conv.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  // Créer une nouvelle conversation
  Conversation creerConversation({
    required String parentId,
    required String directeurId,
    required String garderieId,
  }) {
    final conversation = Conversation(
      id: _generateId(),
      parentId: parentId,
      directeurId: directeurId,
      garderieId: garderieId,
      messages: [],
      derniereMiseAJour: DateTime.now(),
      messagesNonLus: 0,
    );
    _conversations.add(conversation);
    return conversation;
  }

  // Trouver ou créer une conversation entre un parent et un directeur
  Conversation obtenirOuCreerConversation({
    required String parentId,
    required String directeurId,
    required String garderieId,
  }) {
    try {
      return _conversations.firstWhere((conv) =>
          conv.parentId == parentId &&
          conv.directeurId == directeurId &&
          conv.garderieId == garderieId);
    } catch (e) {
      return creerConversation(
        parentId: parentId,
        directeurId: directeurId,
        garderieId: garderieId,
      );
    }
  }

  // Envoyer un message
  Message envoyerMessage({
    required String conversationId,
    required String expediteurId,
    required String destinataireId,
    required String contenu,
  }) {
    final message = Message(
      id: _generateId(),
      expediteurId: expediteurId,
      destinataireId: destinataireId,
      contenu: contenu,
      dateEnvoi: DateTime.now(),
      estLu: false,
    );

    final index =
        _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index != -1) {
      final conversation = _conversations[index];
      final updatedMessages = [...conversation.messages, message];
      final messagesNonLus = updatedMessages
          .where((m) => m.destinataireId == destinataireId && !m.estLu)
          .length;

      _conversations[index] = conversation.copyWith(
        messages: updatedMessages,
        derniereMiseAJour: DateTime.now(),
        messagesNonLus: messagesNonLus,
      );
    }

    return message;
  }

  // Marquer les messages comme lus
  void marquerMessagesCommelus({
    required String conversationId,
    required String utilisateurId,
  }) {
    final index =
        _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index != -1) {
      final conversation = _conversations[index];
      final updatedMessages = conversation.messages.map((message) {
        if (message.destinataireId == utilisateurId && !message.estLu) {
          return message.copyWith(estLu: true);
        }
        return message;
      }).toList();

      _conversations[index] = conversation.copyWith(
        messages: updatedMessages,
        messagesNonLus: 0,
      );
    }
  }

  // Obtenir le nombre total de messages non lus
  int getTotalMessagesNonLus(String userId) {
    return getConversations(userId)
        .where((conv) => conv.messagesNonLus > 0)
        .fold(0, (sum, conv) => sum + conv.messagesNonLus);
  }

  // Supprimer une conversation
  void supprimerConversation(String conversationId) {
    _conversations.removeWhere((conv) => conv.id == conversationId);
  }

  // Générer un ID aléatoire
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        _random.nextInt(9999).toString();
  }

  // Charger des données de démonstration (pour tests)
  void chargerDonneesDemo() {
    final conv1 = creerConversation(
      parentId: 'parent1',
      directeurId: 'directeur1',
      garderieId: 'garderie1',
    );

    envoyerMessage(
      conversationId: conv1.id,
      expediteurId: 'parent1',
      destinataireId: 'directeur1',
      contenu: 'Bonjour, j\'aimerais inscrire mon enfant à votre garderie.',
    );

    Future.delayed(const Duration(seconds: 1), () {
      envoyerMessage(
        conversationId: conv1.id,
        expediteurId: 'directeur1',
        destinataireId: 'parent1',
        contenu:
            'Bonjour ! Avec plaisir. Nous avons des places disponibles. Quel âge a votre enfant ?',
      );
    });
  }
}
