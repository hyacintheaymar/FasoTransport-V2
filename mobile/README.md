# FasoTransport Mobile (Flutter)

Ce dossier contient l'application mobile Flutter pour:

- Passager: recherche d'horaires, reservation, billets QR
- Agent: scan et validation des QR

## Demarrage

```bash
flutter pub get
flutter run
```

## Configuration API

Modifier `lib/config.dart` pour pointer vers votre backend local ou cloud.

Option recommandee: surcharger l'URL au lancement avec `--dart-define`.

Exemples:

```bash
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000

# Appareil Android physique (meme reseau Wi-Fi que le PC)
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:4000
```

Assurez-vous que le backend ecoute sur `0.0.0.0:4000` (Docker expose deja `4000:4000`).
