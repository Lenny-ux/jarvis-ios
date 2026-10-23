# Jarvis — app iPhone

App plein écran qui ouvre l'interface Jarvis (`https://192.168.1.96:3443`) :
- accepte le certificat https "maison" du serveur Jarvis
- donne l'accès caméra + micro à la page (reconnaissance faciale, voix)
- l'écran ne se met jamais en veille
- reconnexion automatique toutes les 5 s si le serveur ne répond pas
- **appui long à 3 doigts** (1,5 s) : changer l'adresse ou recharger

## Construire l'IPA
1. Mets tout ce dossier dans un dépôt GitHub (branche `main`)
2. L'action « Construire l'IPA Jarvis » se lance toute seule (~5 min)
3. Récupère `Jarvis.ipa` dans **Releases**

## Installer
Sideloadly → glisse `Jarvis.ipa` → ton identifiant Apple → Start.
Avec un compte Apple gratuit, l'app est à réinstaller tous les 7 jours.
