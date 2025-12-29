# Guide d'inscription des garderies - JINEN

## Vue d'ensemble

Ce document décrit le processus d'inscription en plusieurs étapes pour les garderies dans l'application JINEN. Le processus a été conçu avec une interface utilisateur professionnelle et intuitive pour faciliter l'enregistrement complet du profil de la garderie.

## Flux d'inscription

### 1. Authentification initiale
Les propriétaires de garderies commencent par s'inscrire dans l'écran d'authentification (`AuthScreen`) où ils :
- Sélectionnent le type "Garderie"
- Renseignent leurs informations personnelles :
  - Nom complet
  - Email
  - Téléphone
  - Mot de passe

### 2. Configuration du profil de la garderie
Après l'authentification, les utilisateurs de type "Garderie" sont automatiquement redirigés vers l'écran de configuration (`NurserySetupScreen`) qui comprend **3 étapes** :

#### Étape 1 : Informations de base
- **Photo de la garderie** : Upload d'une photo représentative
- **Nom de la garderie** : Nom officiel de l'établissement
- **Description** : Présentation de la garderie, valeurs, approche pédagogique
- **Localisation** :
  - Adresse complète
  - Ville
  - Code postal

#### Étape 2 : Détails pratiques
- **Téléphone de contact**
- **Tarif mensuel** (en TND)
- **Nombre total de places** disponibles
- **Tranche d'âge acceptée** :
  - Âge minimum
  - Âge maximum
- **Horaires d'ouverture** :
  - Heure d'ouverture
  - Heure de fermeture
- **Équipements disponibles** (sélection multiple) :
  - Jardin extérieur
  - Aire de jeux
  - Salle de repos
  - Cuisine équipée
  - Climatisation
  - Caméras de surveillance

#### Étape 3 : Activités proposées
Sélection des activités offertes aux enfants :
- Arts plastiques
- Musique
- Sport
- Lecture
- Jeux éducatifs
- Danse
- Jardinage
- Cuisine

## Caractéristiques de l'interface

### Design professionnel
- **Gradient moderne** : Dégradé violet (#667EEA → #764BA2) pour le header
- **Navigation intuitive** : Indicateurs de progression par étapes
- **Formulaires structurés** : Champs bien organisés avec icônes
- **Validation en temps réel** : Messages d'erreur clairs pour les champs requis
- **Upload de photo** : Interface drag-and-drop avec prévisualisation
- **Sélection interactive** : Boutons chips pour les activités et checkboxes stylisées pour les équipements

### Expérience utilisateur
- Navigation par étapes avec boutons "Suivant" et "Précédent"
- Indicateurs visuels de progression (3 points)
- Validation de formulaire complète
- Message de confirmation à la fin du processus
- Design responsive et mobile-first

## Modèle de données

Le modèle `Nursery` a été enrichi avec les champs suivants :

```dart
class Nursery {
  final String id;
  final String name;
  final String address;
  final String? city;
  final String? postalCode;
  final double distance;
  final double rating;
  final int reviewCount;
  final double price;
  final int availableSpots;
  final int totalSpots;
  final String hours;
  final String photo;
  final String description;
  final List<String> activities;
  final List<String>? facilities;
  final int staff;
  final String ageRange;
  final String? phone;
  final String? email;
  final String? ownerId;
  final List<Review>? reviews;
}
```

## Gestion d'état

### AppState Provider
Nouveaux éléments ajoutés :
- **ScreenType.nurserySetup** : Nouveau type d'écran
- **completeNurserySetup()** : Méthode pour finaliser l'inscription et rediriger vers le tableau de bord

### Flux de navigation
1. Welcome → Auth → **NurserySetup** → NurseryDashboard (pour les garderies)
2. Welcome → Auth → ParentDashboard (pour les parents)

## Technologies utilisées

- **Flutter** : Framework principal
- **Provider** : Gestion d'état
- **image_picker** : Sélection de photos depuis la galerie
- **Material Design 3** : Composants UI modernes

## Fichiers modifiés/créés

### Nouveaux fichiers
- `lib/screens/nursery_setup_screen.dart` : Écran principal d'inscription

### Fichiers modifiés
- `lib/models/nursery.dart` : Modèle enrichi avec nouveaux champs
- `lib/providers/app_state.dart` : Ajout du flux nursery setup
- `lib/app.dart` : Intégration du nouveau screen
- `pubspec.yaml` : Ajout de la dépendance image_picker

## Prochaines étapes recommandées

1. **Intégration backend** :
   - Connecter le formulaire à une API REST
   - Sauvegarder les données dans une base de données
   - Gérer l'upload de photos vers un service cloud (Firebase Storage, AWS S3, etc.)

2. **Améliorations UX** :
   - Ajouter une carte interactive pour la localisation
   - Permettre l'upload de plusieurs photos
   - Ajouter un système de prévisualisation du profil avant soumission

3. **Fonctionnalités supplémentaires** :
   - Gestion des horaires détaillés (jours d'ouverture spécifiques)
   - Upload de documents (licence, certifications, etc.)
   - Ajout d'informations sur le personnel
   - Configuration des tarifs (mensuel, hebdomadaire, journalier)

4. **Validation** :
   - Vérification du format des numéros de téléphone
   - Validation des horaires (ouverture < fermeture)
   - Vérification de l'âge minimum < âge maximum
   - Limites de taille pour les images

## Support et maintenance

Pour toute question ou amélioration, contactez l'équipe de développement JINEN.

---
*Document créé le 20 novembre 2025*
