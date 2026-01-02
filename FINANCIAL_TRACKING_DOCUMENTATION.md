# Documentation du Système de Suivi Financier

## Vue d'ensemble

Le système de suivi financier permet aux garderies de gérer les paiements mensuels des parents de manière automatisée et professionnelle.

## Fonctionnalités principales

### Pour les Parents

#### Interface de Paiement (`ParentPaymentScreen`)
- **Accès** : Dashboard Parent → "Mes Paiements"
- **Fonctionnalités** :
  - Liste des paiements en attente pour le mois en cours
  - Formulaire de paiement sécurisé :
    - Numéro de carte (16 chiffres avec formatage automatique)
    - Date d'expiration (MM/AA)
    - Code CVV (3-4 chiffres)
  - Validation en temps réel des données de carte
  - Confirmation de paiement instantanée
  - Affichage du statut (Payé/Non payé)

#### Processus de Paiement
1. Le parent accède à "Mes Paiements" depuis son dashboard
2. Les paiements en attente sont affichés (un par enfant inscrit)
3. Clic sur "Payer maintenant" ouvre le formulaire de paiement
4. Saisie des informations de carte avec validation
5. Confirmation du paiement
6. Notification envoyée à la garderie
7. Statut mis à jour instantanément

### Pour les Garderies

#### Interface de Suivi Financier (`NurseryFinancialTrackingScreen`)
- **Accès** : Dashboard Garderie → "Suivi financier"
- **Fonctionnalités** :
  - **Sélection de période** : Mois et année personnalisables
  - **Statistiques en temps réel** :
    - Montant attendu total
    - Montant reçu
    - Montant en attente
    - Taux de paiement (pourcentage)
  - **Filtres** :
    - Tous les enfants
    - Seulement les payés
    - Seulement les non payés
  - **Liste détaillée** :
    - Nom de l'enfant
    - Nom du parent
    - Email et téléphone du parent
    - Montant
    - Statut du paiement
    - Date de paiement (si payé)

#### Barre de Progression
- Affichage visuel du taux de paiement
- Couleur verte pour indiquer la progression
- Pourcentage exact affiché

## Architecture Technique

### Base de Données

#### Table `payments`
```sql
- id (UUID) : Identifiant unique
- enrollment_id (UUID) : Référence à l'inscription
- parent_id (UUID) : Référence au parent
- nursery_id (UUID) : Référence à la garderie
- child_id (UUID) : Référence à l'enfant
- amount (DECIMAL) : Montant du paiement
- payment_month (INTEGER) : Mois (1-12)
- payment_year (INTEGER) : Année
- payment_status (VARCHAR) : 'paid' ou 'unpaid'
- payment_date (TIMESTAMP) : Date du paiement
- card_last_digits (VARCHAR) : 4 derniers chiffres de la carte
- transaction_id (VARCHAR) : ID de transaction unique
```

#### Vue `payment_details`
Jointure automatique entre payments, users, children et nurseries pour faciliter les requêtes.

#### Fonction `create_monthly_payments()`
Génère automatiquement les paiements mensuels pour toutes les inscriptions actives.

### Services Backend (Node.js/Express)

#### Endpoints API

1. **GET /api/payments/parent/:parentId/status**
   - Récupère les paiements en attente pour un parent (mois en cours)
   - Retourne : Liste des paiements avec détails enfant/garderie

2. **POST /api/payments/process**
   - Traite un paiement
   - Paramètres : enrollmentId, cardNumber, expiryDate, cvv
   - Actions :
     - Validation des données
     - Mise à jour du statut à 'paid'
     - Sauvegarde des 4 derniers chiffres de la carte
     - Génération d'un transaction_id
     - Création d'une notification pour la garderie

3. **GET /api/payments/nursery/:nurseryId**
   - Récupère tous les paiements d'une garderie
   - Paramètres query : month, year
   - Retourne : Liste complète avec détails parent/enfant

4. **GET /api/payments/nursery/:nurseryId/stats**
   - Calcule les statistiques financières
   - Paramètres query : month, year
   - Retourne :
     - total_expected : Montant total attendu
     - total_received : Montant total reçu
     - total_pending : Montant en attente
     - paid_count : Nombre de paiements reçus
     - unpaid_count : Nombre de paiements en attente
     - payment_percentage : Pourcentage de paiements reçus

5. **GET /api/payments/parent/:parentId/history**
   - Historique des paiements d'un parent
   - Paramètre query : limit (défaut: 12)

6. **POST /api/payments/generate-monthly**
   - Génère les paiements mensuels (à appeler par cron job)
   - Crée automatiquement les entrées 'unpaid' pour le mois en cours

### Services Frontend (Flutter/Dart)

#### `PaymentService` (lib/services/payment_service.dart)

**Méthodes principales :**

```dart
// Récupère le statut de paiement pour un parent
Future<Map<String, dynamic>> getPaymentStatus(String parentId)

// Traite un paiement
Future<Map<String, dynamic>> processPayment({
  required String enrollmentId,
  required String cardNumber,
  required String expiryDate,
  required String cvv,
})

// Récupère les paiements d'une garderie
Future<Map<String, dynamic>> getNurseryPayments({
  required String nurseryId,
  int? month,
  int? year,
})

// Récupère les statistiques financières
Future<Map<String, dynamic>> getNurseryFinancialStats({
  required String nurseryId,
  int? month,
  int? year,
})

// Récupère l'historique des paiements d'un parent
Future<Map<String, dynamic>> getPaymentHistory(String parentId, {int limit = 12})

// Génère les paiements mensuels
Future<Map<String, dynamic>> generateMonthlyPayments()
```

**Méthodes de validation :**

```dart
// Valide un numéro de carte (16 chiffres + algorithme de Luhn)
bool validateCardNumber(String cardNumber)

// Valide une date d'expiration (MM/AA, pas expirée)
bool validateExpiryDate(String expiryDate)

// Valide un code CVV (3-4 chiffres)
bool validateCVV(String cvv)
```

**Méthodes utilitaires :**

```dart
// Formate un montant avec le symbole TND
String formatAmount(dynamic amount)

// Retourne le nom du mois en français
String getMonthName(int month)

// Masque un numéro de carte (**** **** **** 1234)
String maskCardNumber(String cardNumber)
```

## Sécurité

### Validation des Données
- **Numéro de carte** : Algorithme de Luhn pour validation
- **Date d'expiration** : Vérification format et validité
- **CVV** : Longueur 3-4 chiffres

### Stockage
- Seuls les 4 derniers chiffres de la carte sont stockés
- Aucune information de carte complète n'est conservée
- Transaction ID généré aléatoirement pour chaque paiement

### Notes de Sécurité
⚠️ **Important** : L'implémentation actuelle simule le traitement des paiements. En production :
- Intégrer un gateway de paiement (Stripe, PayPal, etc.)
- Utiliser HTTPS obligatoirement
- Implémenter 3D Secure
- Respecter les normes PCI DSS

## Automatisation Mensuelle

### Génération des Paiements
La fonction `create_monthly_payments()` doit être appelée :
- Au début de chaque mois
- Automatiquement via un cron job
- Ou manuellement via l'endpoint `/api/payments/generate-monthly`

### Workflow Automatique
1. Au 1er de chaque mois, appeler `create_monthly_payments()`
2. Pour chaque inscription active (status = 'accepted') :
   - Créer un paiement avec status = 'unpaid'
   - Montant = price_per_month de la garderie
   - payment_month = mois actuel
   - payment_year = année actuelle
3. Les parents peuvent ensuite effectuer le paiement
4. Au paiement, le status passe de 'unpaid' à 'paid'

## Interface Utilisateur

### Design
- **Palette de couleurs** :
  - Gradient principal : #6366F1 → #8B5CF6 (Indigo/Violet)
  - Succès/Payé : #10B981 (Vert)
  - Attention/Non payé : #F59E0B (Orange)
  - Information : #3B82F6 (Bleu)
- **Composants** :
  - Cards avec ombres et bordures arrondies
  - Icônes Material Design
  - Animations de chargement
  - États visuels clairs (payé/non payé)

### Expérience Utilisateur
- **Parent** :
  - Vue claire des paiements en attente
  - Processus de paiement simple en 3 étapes
  - Validation en temps réel
  - Confirmation immédiate
- **Garderie** :
  - Dashboard complet avec statistiques
  - Filtres pour gestion rapide
  - Indicateurs visuels de performance
  - Rafraîchissement pull-to-refresh

## Notifications

Quand un paiement est effectué :
1. Une notification est créée dans la table `notifications`
2. Type : 'payment'
3. Destinataire : nursery_id
4. Message : "Nouveau paiement reçu pour l'inscription #[ID]"
5. related_id : payment_id

## Tests et Débogage

### Tester le Système

1. **Créer des inscriptions de test** :
   ```sql
   -- S'assurer qu'il y a des enrollments avec status='accepted'
   ```

2. **Générer les paiements** :
   ```bash
   curl -X POST http://localhost:3000/api/payments/generate-monthly
   ```

3. **Vérifier les paiements créés** :
   ```sql
   SELECT * FROM payment_details WHERE payment_month = EXTRACT(MONTH FROM CURRENT_DATE);
   ```

4. **Interface Parent** :
   - Se connecter en tant que parent
   - Naviguer vers "Mes Paiements"
   - Vérifier que les paiements apparaissent
   - Effectuer un paiement test

5. **Interface Garderie** :
   - Se connecter en tant que garderie
   - Naviguer vers "Suivi financier"
   - Vérifier les statistiques
   - Tester les filtres

### Logs Backend
```javascript
console.log('Payment processed:', paymentId);
console.log('Notification created for nursery:', nurseryId);
```

## Migration et Déploiement

### Migration Initiale Effectuée
Le script `database/migrate_payments_table.sql` a été exécuté avec succès :
- ✅ Ajout des colonnes nécessaires
- ✅ Création des index
- ✅ Création de la vue payment_details
- ✅ Création de la fonction create_monthly_payments()

### Configuration Requise
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=nursery_db
DB_USER=nursery_admin
DB_PASSWORD=nursery_password_2025
```

## Maintenance

### Tâches Mensuelles
1. Exécuter `create_monthly_payments()` le 1er du mois
2. Vérifier les statistiques de paiement
3. Relancer les parents avec paiements en attente

### Monitoring
- Surveiller le taux de paiement mensuel
- Analyser les paiements en retard
- Vérifier la santé de la base de données

## Support et Contact

Pour toute question ou problème :
- Consulter les logs backend : `docker logs nursery_backend`
- Vérifier les erreurs frontend dans la console Flutter
- Consulter cette documentation

---

**Version** : 1.0.0
**Date** : Janvier 2025
**Statut** : ✅ Opérationnel
