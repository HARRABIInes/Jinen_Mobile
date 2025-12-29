# Fonctionnalité de Chat - Documentation

## Vue d'ensemble

Système de messagerie complet permettant aux parents et aux directeurs de garderie d'échanger des messages directement dans l'application.

## Architecture

### Modèles de données

#### Message (`lib/models/message.dart`)

- `id`: Identifiant unique du message
- `expediteurId`: ID de l'expéditeur
- `destinataireId`: ID du destinataire
- `contenu`: Texte du message
- `dateEnvoi`: Date et heure d'envoi
- `estLu`: Statut de lecture (booléen)

#### Conversation (`lib/models/conversation.dart`)

- `id`: Identifiant unique de la conversation
- `parentId`: ID du parent participant
- `directeurId`: ID du directeur participant
- `garderieId`: ID de la garderie concernée
- `messages`: Liste des messages de la conversation
- `derniereMiseAJour`: Date de la dernière activité
- `messagesNonLus`: Nombre de messages non lus

### Service

#### ChatService (`lib/services/chat_service.dart`)

Gère toute la logique métier du chat :

- `getConversations(userId)`: Récupère toutes les conversations d'un utilisateur
- `getConversation(conversationId)`: Récupère une conversation spécifique
- `creerConversation()`: Crée une nouvelle conversation
- `obtenirOuCreerConversation()`: Trouve ou crée une conversation entre deux utilisateurs
- `envoyerMessage()`: Envoie un nouveau message
- `marquerMessagesCommelus()`: Marque les messages comme lus
- `getTotalMessagesNonLus(userId)`: Compte les messages non lus pour un utilisateur
- `supprimerConversation()`: Supprime une conversation
- `chargerDonneesDemo()`: Charge des données de démonstration pour les tests

### Écrans UI

#### ChatListScreen (`lib/screens/chat_list_screen.dart`)

- Affiche la liste de toutes les conversations de l'utilisateur
- Tri par date de dernière mise à jour (plus récentes en premier)
- Badge affichant le nombre de messages non lus par conversation
- Navigation vers l'écran de conversation au clic

**Paramètres:**

- `userId`: ID de l'utilisateur connecté
- `userType`: Type d'utilisateur ('parent' ou 'directeur')

#### ChatScreen (`lib/screens/chat_screen.dart`)

- Interface de chat en temps réel avec bulles de messages
- Distinction visuelle entre messages envoyés/reçus
- Zone de saisie de texte avec bouton d'envoi
- Auto-scroll vers le bas lors de nouveaux messages
- Marquage automatique des messages comme lus

**Paramètres:**

- `conversationId`: ID de la conversation
- `userId`: ID de l'utilisateur connecté
- `autreUtilisateurNom`: Nom de l'autre participant

### Intégration

#### AppState (`lib/providers/app_state.dart`)

Gestion de l'état global :

- `chatService`: Instance du ChatService accessible globalement
- `unreadMessagesCount`: Propriété calculée pour le nombre total de messages non lus

#### Dashboards

Les boutons de chat ont été ajoutés dans :

- `ParentDashboard` : Bouton chat avec badge de notification
- `NurseryDashboard` : Bouton chat avec badge de notification

Les badges affichent le nombre de messages non lus et se mettent à jour automatiquement.

## Utilisation

### Pour les Parents

1. Cliquer sur l'icône de chat dans le tableau de bord
2. Voir la liste des conversations avec les garderies
3. Cliquer sur une conversation pour échanger des messages
4. Taper un message et appuyer sur le bouton d'envoi

### Pour les Directeurs

1. Cliquer sur l'icône de chat dans le tableau de bord
2. Voir la liste des conversations avec les parents
3. Cliquer sur une conversation pour répondre
4. Taper un message et appuyer sur le bouton d'envoi

## Fonctionnalités

✅ **Implémenté :**

- Envoi et réception de messages
- Liste des conversations triée par date
- Compteur de messages non lus
- Marquage automatique comme lu
- Interface utilisateur moderne et intuitive
- Avatars et bulles de messages colorées
- Horodatage des messages

🔄 **À améliorer (futur) :**

- Intégration avec une vraie base de données (Firebase/Supabase)
- Notifications push pour nouveaux messages
- Indicateur "en train d'écrire..."
- Support des pièces jointes (photos, documents)
- Recherche dans les conversations
- Archivage des conversations
- Messages vocaux

## Structure des fichiers

```
lib/
├── models/
│   ├── message.dart          # Modèle de message
│   └── conversation.dart     # Modèle de conversation
├── services/
│   └── chat_service.dart     # Service de gestion du chat
├── screens/
│   ├── chat_list_screen.dart # Liste des conversations
│   └── chat_screen.dart      # Écran de conversation
├── providers/
│   └── app_state.dart        # État global (mis à jour)
└── screens/
    ├── parent_dashboard.dart   # Dashboard parent (mis à jour)
    └── nursery_dashboard.dart  # Dashboard directeur (mis à jour)
```

## Notes techniques

- **Stockage actuel** : En mémoire (liste locale dans ChatService)
- **Persistence** : Aucune pour le moment - les messages sont perdus au redémarrage
- **Temps réel** : Pas de synchronisation en temps réel pour l'instant
- **Scalabilité** : Prêt à être connecté à un backend (Firebase, API REST, etc.)

## Prochaines étapes recommandées

1. **Backend** : Connecter à Firebase Firestore ou une API REST
2. **Persistence** : Sauvegarder localement avec SQLite ou SharedPreferences
3. **Notifications** : Implémenter les notifications push
4. **Tests** : Ajouter des tests unitaires et d'intégration
5. **Performance** : Pagination pour les grandes listes de messages

## Diagramme de séquence (Envoi de message)

```
Parent -> ChatScreen: Tape un message et clique "Envoyer"
ChatScreen -> ChatService: envoyerMessage(conversationId, expediteurId, destinataireId, contenu)
ChatService -> Message: Créer nouveau message
ChatService -> Conversation: Ajouter message à la conversation
ChatService -> Conversation: Mettre à jour derniereMiseAJour
ChatService -> Conversation: Incrémenter messagesNonLus
ChatService --> ChatScreen: Message créé
ChatScreen -> ChatScreen: Rafraîchir l'affichage
ChatScreen -> ChatScreen: Scroll vers le bas
ChatScreen --> Parent: Afficher le message envoyé
```

---

**Développé pour le projet Garderie Mobile**
Date de création : Novembre 2025
