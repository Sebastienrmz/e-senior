# Remise en ordre du dépôt

L’objectif est de conserver l’application du groupe et de corriger les problèmes rencontrés à sa reprise.

- Retrait des caches Flutter, fichiers de compilation, réglages locaux et profil de navigateur présents dans l’archive. Les originaux restent dans l’archive.
- Conservation des cibles Android et iOS ; retrait des cibles de démarrage web et bureau qui ne fonctionnaient pas avec le stockage utilisé.
- Ouverture partagée de SQLite et possibilité de tester le service sur une base isolée.
- Activation des clés étrangères ; les messages d’un contact sont supprimés avec lui.
- Transactions pour l’ajout et la modification du contact SOS. Une écriture qui échoue conserve le contact SOS précédent et les messages existants.
- Limite de douze favoris vérifiée aussi dans le service de base de données.
- Correction des initiales des noms entourés d’espaces.
- Correction du choix WhatsApp, qui ouvrait également les SMS, et des numéros français destinés à WhatsApp.
- Encodage du texte des SMS et signalement d’une application externe indisponible.
- Initialisation des dates françaises pour afficher les anciennes conversations.
- Conservation des photos prises depuis l’accueil et de leur extension lors de l’import.
- Prise en compte de la taille du texte et du réglage du retour haptique.
- Suppression des affirmations non prises en charge : chiffrement AES, conformité RGPD garantie et configuration distante opérationnelle.
- Ajout des déclarations nécessaires aux photos sur iOS et à la recherche d’applications externes sur Android.
- Remplacement du test de compteur Flutter par des tests adaptés à E-Senior.

Les tests automatiques ne remplacent pas un essai sur téléphone : permissions, appareil photo et applications SMS/WhatsApp doivent être vérifiés sur l’appareil utilisé pour la présentation.
