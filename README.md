# E-Senior

Application mobile Flutter conçue pour simplifier l’accès aux contacts et aux fonctions courantes du téléphone : appeler un proche, préparer un message et retrouver ses photos.

Projet étudiant TI350, réalisé en équipe de **trois personnes** en 2025–2026 à l’EFREI. **Ma contribution : la gestion des contacts et la base de données locale.**

## Essayer l’application

Sur **Android**, télécharger `E-Senior-Android.apk` dans [la dernière version disponible](https://github.com/Sebastienrmz/e-senior/releases/latest), puis l’ouvrir sur le téléphone. Il s’agit d’une version de démonstration, distribuée en dehors du Play Store. Aucun compte n’est nécessaire. Utiliser des contacts de démonstration pour commencer.

Pour un premier essai :

1. Ajouter un contact avec son nom et son numéro.
2. Revenir à l’accueil et ouvrir sa fiche.
3. Modifier ce contact dans les paramètres, puis le définir comme contact SOS.
4. Fermer et rouvrir l’application pour vérifier que les informations sont conservées.
5. Préparer un message : E-Senior ouvre l’application SMS ou WhatsApp ; la validation de l’envoi se fait dans cette application.
6. Supprimer le contact et vérifier qu’il disparaît de la liste.

Le bouton SOS demande un maintien de deux secondes, puis une confirmation avant d’ouvrir un appel vers **le contact choisi**. Il ne contacte pas automatiquement les services de secours.

## Fonctions

- Ajout, modification et suppression de contacts, avec photo facultative.
- Jusqu’à douze contacts favoris et un seul contact SOS.
- Conservation locale des contacts et des brouillons dans SQLite.
- Ouverture du téléphone, des SMS et de WhatsApp avec le contact sélectionné.
- Messages rapides et historique local des textes préparés.
- Import de photos, prise de vue et consultation des cinquante dernières images présentes dans le dossier de l’application.
- Réglage de la taille du texte, du retour haptique et du nom affiché.
- Effacement des données locales et des copies de photos importées par l’application.

## Limites du projet

L’historique ne lit pas les SMS du téléphone et ne confirme pas qu’un message a été envoyé ou reçu. Les appels, SMS, photos et applications externes dépendent des possibilités du téléphone et de ses autorisations.

La configuration à distance était une piste du projet ; elle n’est pas implémentée. L’application ne contient ni serveur, ni compte utilisateur, ni chiffrement supplémentaire de la base SQLite.

Android est la cible de démonstration. Les fichiers iOS sont conservés, mais la compilation et les essais sur iPhone nécessitent macOS, Xcode et un appareil compatible. L’application n’est pas prévue pour le navigateur ou Windows.

## Lancer depuis le code

Prérequis : Flutter **3.47.8** (Dart 3.13.7), Android Studio avec le SDK Android et un émulateur, ou un téléphone Android avec le débogage USB activé. Les versions des dépendances sont enregistrées dans `pubspec.lock`.

Cloner ou télécharger le dépôt, puis ouvrir **le dossier contenant `pubspec.yaml`** dans Android Studio ou VS Code. Dans le terminal de ce dossier :

```sh
flutter doctor
flutter pub get
flutter devices
flutter run
```

Choisir un appareil Android. Pour générer l’APK de démonstration :

```sh
flutter build apk --release
```

Le résultat est dans `build/app/outputs/flutter-apk/app-release.apk`. La configuration utilise la signature de développement : elle convient à la démonstration, pas à une publication sur le Play Store.

## Vérifier le projet

```sh
flutter analyze
flutter test
```

Les tests couvrent les contacts, les transactions SQLite, les relations avec les messages et plusieurs parcours d’interface. Les ouvertures d’applications externes sont simulées : aucun appel ni SMS réel n’est effectué par les tests. Le workflow GitHub vérifie le code et les tests, construit l’APK puis vérifie son démarrage sur un émulateur Android avant de publier la démonstration.

## Organisation

```text
lib/
  models/       Contacts et messages
  screens/      Accueil, contacts, messages, galerie et paramètres
  services/     SQLite, préférences et préparation des numéros
  theme/        Couleurs et dimensions communes
  widgets/      Composants réutilisables, dont le bouton SOS
android/        Configuration Android
ios/            Configuration iOS à valider sur macOS
test/           Tests de la base, des modèles et des écrans
```

Le détail des corrections est disponible dans [CORRECTIONS.md](CORRECTIONS.md).
