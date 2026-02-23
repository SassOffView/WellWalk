# MindStep — Setup Android Studio

## Prerequisiti

1. **Android Studio** (Hedgehog 2023.1.1 o superiore)
2. **Flutter SDK** 3.24+ installato
3. **Dart** 3.5+
4. **Java** 17+

---

## Installazione Flutter SDK

Se non hai ancora Flutter:

```bash
# macOS / Linux
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verifica
flutter doctor
```

---

## Aprire il Progetto in Android Studio

1. Apri Android Studio
2. **File → Open** → seleziona la cartella `/path/to/WellWalk/mindstep`
3. Aspetta che Android Studio riconosca il progetto Flutter
4. Esegui **flutter pub get** nel terminale integrato:

```bash
flutter pub get
```

---

## Setup Firebase (per sincronizzazione PRO)

1. Vai su [Firebase Console](https://console.firebase.google.com)
2. Crea un nuovo progetto "MindStep"
3. Aggiungi app Android con package name `com.mindstep.app`
4. Scarica `google-services.json` e posizionalo in:
   ```
   mindstep/android/app/google-services.json
   ```
5. Per iOS (futuro): scarica `GoogleService-Info.plist` e mettilo in `mindstep/ios/Runner/`

---

## Font Inter

Scarica i font Inter da Google Fonts e mettili in:
```
mindstep/assets/fonts/
  Inter-Regular.ttf
  Inter-Medium.ttf
  Inter-SemiBold.ttf
  Inter-Bold.ttf
  Inter-ExtraBold.ttf
```

Oppure usa `google_fonts` package (già incluso in pubspec.yaml) che li scarica automaticamente.

---

## Aggiorna pubspec.yaml se non usi font locali

Se usi Google Fonts direttamente (senza file locali), rimuovi la sezione `fonts:` dal pubspec.yaml e usa:

```dart
// Nel codice, sostituisci 'Inter' con:
import 'package:google_fonts/google_fonts.dart';
GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)
```

---

## Eseguire l'App

### Emulatore
1. **Tools → AVD Manager** → Crea dispositivo (API 26+)
2. Avvia l'emulatore
3. Premi **Run ▶** in Android Studio

### Dispositivo Fisico
1. Abilita **Modalità Sviluppatore** sul telefono
2. Collega via USB
3. Premi **Run ▶**

### Da terminale
```bash
flutter run
```

---

## Build APK/AAB per Play Store

```bash
# APK per test
flutter build apk --release

# AAB per Google Play
flutter build appbundle --release

# Output in:
# build/app/outputs/bundle/release/app-release.aab
```

---

## Firma dell'App

1. Genera keystore:
```bash
keytool -genkey -v -keystore ~/mindstep-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mindstep
```

2. Crea `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=mindstep
storeFile=/path/to/mindstep-release.jks
```

3. Aggiorna `android/app/build.gradle` per usare la firma.

---

## Funzionalità che richiedono configurazione aggiuntiva

| Feature | Configurazione |
|---|---|
| Firebase (Pro cloud) | `google-services.json` nella cartella `android/app/` |
| In-App Purchase | Configurare prodotti su Google Play Console |
| Health Connect | App deve essere su Play Store o in testing interno |
| GPS Background | Permesso `ACCESS_BACKGROUND_LOCATION` già nel manifest |
| Notifiche esatte | `SCHEDULE_EXACT_ALARM` già nel manifest |

---

## Struttura file generati

```
mindstep/
├── lib/
│   ├── main.dart               ← Entry point
│   ├── app.dart                ← Routing + Providers
│   ├── core/
│   │   ├── constants/          ← Colori, stringhe, badge
│   │   ├── models/             ← Modelli dati
│   │   ├── services/           ← GPS, DB, Badge, Notifiche, Health
│   │   └── theme/              ← Light/Dark theme
│   ├── features/
│   │   ├── onboarding/         ← Primo avvio + setup profilo
│   │   ├── home/               ← Walk + Routine + Brainstorm
│   │   ├── history/            ← Calendario storico
│   │   ├── analytics/          ← Grafici e dati
│   │   ├── achievements/       ← Badge system (20 badge)
│   │   └── settings/           ← Impostazioni + Export
│   └── subscription/           ← Paywall Free/PRO
└── android/
    ├── app/src/main/
    │   ├── AndroidManifest.xml ← Permessi + Widget + Health
    │   ├── kotlin/             ← MainActivity + Widget receivers
    │   └── res/                ← Layouts widget
    ├── build.gradle
    └── settings.gradle
```

---

## Note sui Bug Risolti dalla PWA

6 bug del sistema badge sono stati risolti nel codice Android:

1. ✅ Badge verificati all'avvio dell'app (non solo su azione)
2. ✅ `checkMilestones('walks')` ora chiamato al completamento camminata
3. ✅ Flag `hasBrainstormedEver` globale nel profilo (non per-giorno)
4. ✅ Griglia badge scrollabile nativa (no max-height che tagliava)
5. ✅ Operazioni storage async sequential (no race condition)
6. ✅ `countTotalWalks()` integrato nel BadgeService e usato correttamente

---

*MindStep Android v1.0 — Creato il 23 Febbraio 2026*
