# Guide d'utilisation - Inscription Garderie JINEN

## 🎯 Pour tester l'inscription

### 1. Lancer l'application
```bash
cd c:\Git\Projet_Mobile
flutter run
```

### 2. Parcours d'inscription

#### A. Page d'accueil (Welcome Screen)
- Cliquez sur "Commencer" ou "S'inscrire"

#### B. Authentification (Auth Screen)
1. Sélectionnez **"S'inscrire"** (en bas de l'écran)
2. Choisissez le type **"Garderie"** (carte bleue à droite)
3. Remplissez vos informations personnelles :
   - Nom complet
   - Email
   - Téléphone
   - Mot de passe
4. Cliquez sur **"Créer mon compte"**

#### C. Configuration du profil (Nursery Setup Screen)

##### 📸 ÉTAPE 1/3 : Informations de base
**Ce que vous verrez :**
- Header violet avec gradient élégant
- Indicateurs de progression (premier point blanc, deux points transparents)
- Bouton retour invisible (première étape)

**À remplir :**
1. **Photo de la garderie*** :
   - Cliquez sur la grande zone grise avec l'icône caméra
   - Sélectionnez une photo depuis votre galerie
   - La photo s'affiche en prévisualisation
   - Vous pouvez la changer en cliquant sur le X

2. **Nom de la garderie*** :
   - Exemple : "Les Petits Anges"
   - Icône : building/entreprise

3. **Description** :
   - Zone de texte multiligne
   - Décrivez votre garderie, vos valeurs, votre approche
   - Exemple : "Une garderie familiale offrant un environnement sûr et stimulant..."

4. **Localisation** :
   - **Adresse*** : "123 Rue de la République"
   - **Ville*** : "Tunis"
   - **Code postal** : "1000" (optionnel)

5. Cliquez sur **"Suivant"** (bouton violet avec gradient)

##### 💼 ÉTAPE 2/3 : Détails pratiques
**Ce que vous verrez :**
- Le deuxième indicateur de progression est blanc
- Bouton retour visible en haut à gauche
- Formulaire avec plusieurs sections

**À remplir :**
1. **Téléphone*** : "+216 XX XXX XXX"
2. **Tarif mensuel (TND)*** : "250"
3. **Nombre total de places*** : "30"

4. **Tranche d'âge acceptée** :
   - **Âge minimum*** : "1" (avec suffixe "ans")
   - **Âge maximum*** : "5" (avec suffixe "ans")

5. **Horaires d'ouverture** :
   - **Ouverture*** : "07:00"
   - **Fermeture*** : "18:00"

6. **Équipements disponibles** :
   - Cochez tous les équipements dont vous disposez
   - Les cases cochées deviennent violettes
   - Exemples :
     - ☑ Jardin extérieur
     - ☑ Aire de jeux
     - ☑ Climatisation
     - ☑ Caméras de surveillance

7. Cliquez sur **"Suivant"**

##### 🎨 ÉTAPE 3/3 : Activités proposées
**Ce que vous verrez :**
- Le troisième indicateur de progression est blanc
- Des chips colorées pour chaque activité
- Une carte informative en bas
- Bouton "Terminer" au lieu de "Suivant"

**À faire :**
1. **Sélectionnez les activités** que vous proposez :
   - Cliquez sur chaque activité pour la sélectionner
   - Les chips sélectionnées deviennent violettes avec une icône ✓
   - Activités disponibles :
     - Arts plastiques
     - Musique
     - Sport
     - Lecture
     - Jeux éducatifs
     - Danse
     - Jardinage
     - Cuisine

2. **Lisez le message informatif** :
   - Icône info dans une boîte violette
   - "Vous êtes presque prêt !"
   - Rappel que vous pouvez modifier le profil plus tard

3. Cliquez sur **"Terminer"**

#### D. Confirmation
- Un message de succès apparaît en bas : "Profil de garderie créé avec succès !" (fond vert)
- Vous êtes automatiquement redirigé vers votre **Tableau de bord Garderie**

## 🎨 Éléments visuels à noter

### Design professionnel
- **Couleurs** : Palette violette élégante (#667EEA → #764BA2)
- **Espacement** : Marges et padding harmonieux
- **Typographie** : Hiérarchie claire avec titres en gras
- **Icônes** : Icônes Material Design cohérentes
- **Animations** : Transitions fluides entre les étapes

### Interactions
- **Focus** : Bordure violette sur les champs actifs
- **Hover** : Retour visuel sur tous les boutons
- **Validation** : Messages d'erreur en rouge sous les champs invalides
- **Sélection** : Changement de couleur pour les éléments sélectionnés

## ✅ Validation des données

### Champs obligatoires (*)
Si vous essayez de passer à l'étape suivante sans remplir un champ obligatoire :
- Un message d'erreur rouge apparaît : "Champ requis" ou "Requis"
- Le champ est entouré en rouge
- Vous ne pouvez pas avancer

### Format des données
- **Téléphone** : Format libre (validation future possible)
- **Prix** : Chiffres uniquement
- **Places** : Chiffres uniquement
- **Âges** : Chiffres uniquement
- **Horaires** : Format HH:MM recommandé

## 🔄 Navigation

### Entre les étapes
- **Bouton "Suivant"** : Avance à l'étape suivante (si formulaire valide)
- **Bouton "Retour"** : Revient à l'étape précédente (étapes 2 et 3)
- **Bouton "Terminer"** : Finalise l'inscription (étape 3)
- **Swipe désactivé** : Impossible de glisser pour changer d'étape

### Indicateurs de progression
- 3 points horizontaux en haut
- Point actuel : blanc et plus large
- Points futurs : transparents et petits
- Position centrée sous le titre

## 📱 Responsive

L'écran s'adapte à toutes les tailles :
- **Mobile** : Vue optimale sur smartphones
- **Tablet** : Container centré avec largeur max
- **Desktop** : Vue mobile simulée (maxWidth: 448px)

## 🛠 Prochaines améliorations possibles

1. **Photos multiples** : Galerie de plusieurs photos
2. **Géolocalisation** : Carte interactive pour l'adresse
3. **Horaires détaillés** : Jours d'ouverture spécifiques
4. **Documents** : Upload de licences et certifications
5. **Personnel** : Ajout d'informations sur l'équipe
6. **Prévisualisation** : Voir le profil avant soumission
7. **Sauvegarde automatique** : Brouillon en cas de fermeture

## 💡 Conseils pour une belle présentation

### Photo de garderie
- Utilisez une photo lumineuse et accueillante
- Montrez les espaces de jeu ou les enfants (avec autorisation)
- Format paysage recommandé
- Résolution minimum : 1200x1200px

### Description
- Mettez en avant vos points forts
- Mentionnez votre expérience
- Parlez de votre approche pédagogique
- Soyez authentique et chaleureux

### Activités
- Sélectionnez uniquement celles que vous proposez réellement
- Plus d'activités = plus attractif pour les parents
- Pensez aux activités saisonnières

## 📞 Support

Pour toute question ou problème :
- Consultez la documentation complète : `NURSERY_REGISTRATION.md`
- Vérifiez le résumé d'implémentation : `IMPLEMENTATION_SUMMARY.md`

---

*Guide utilisateur créé le 20 novembre 2025*
*Version 1.0 - JINEN Mobile App*
