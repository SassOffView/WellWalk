# MindStep Android — Documento di Design
## Versione 1.0 | Pre-sviluppo

---

## 1. SCELTA DEL FRAMEWORK

### ✅ Flutter (Cross-Platform Nativo)

Dopo aver analizzato i requisiti (GPS background, notifiche, Health Connect, widget, Free/Pro tiers), la scelta è **Flutter**.

**Motivazioni:**
| Criterio | Flutter | React Native | Kotlin solo |
|---|---|---|---|
| Android + iOS | ✅ Un codice | ✅ Un codice | ❌ Solo Android |
| Performance | ✅ Ottima | ⚠️ Media | ✅ Massima |
| GPS Background | ✅ Plugin maturo | ✅ Plugin ok | ✅ Nativo |
| Health Connect | ✅ Plugin `health` | ⚠️ Plugin limitato | ✅ Nativo |
| Widget homescreen | ✅ `home_widget` | ⚠️ Complesso | ✅ Nativo |
| In-App Purchase | ✅ `in_app_purchase` | ✅ ok | ✅ Nativo |
| Riproduzione design PWA | ✅ Perfetta | ⚠️ Buona | ✅ Flessibile |
| Scalabilità futura (iOS) | ✅ Inclusa | ✅ Inclusa | ❌ Da rifare |

**Versioni target:**
- Flutter: 3.24+
- Dart: 3.5+
- Android minSdk: 26 (Android 8.0)
- Android targetSdk: 35 (Android 15)
- iOS: 16+ (per la versione futura)

---

## 2. ARCHITETTURA APP

### 2.1 Struttura Progetto Flutter

```
mindstep/
├── android/                    # Config Android nativa
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── res/
│           └── xml/           # Widget config
├── ios/                        # Config iOS (futuro)
├── lib/
│   ├── main.dart               # Entry point
│   ├── app.dart                # MaterialApp, routing, theme
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart     # Palette colori
│   │   │   ├── app_strings.dart    # Tutte le frasi italiane
│   │   │   ├── app_badges.dart     # Definizione badge completa
│   │   │   └── app_config.dart     # Feature flags, versioni
│   │   ├── models/
│   │   │   ├── user_profile.dart
│   │   │   ├── walk_session.dart
│   │   │   ├── routine_item.dart
│   │   │   ├── brainstorm_note.dart
│   │   │   ├── badge_model.dart
│   │   │   ├── day_data.dart
│   │   │   └── subscription_status.dart
│   │   ├── services/
│   │   │   ├── storage/
│   │   │   │   ├── storage_interface.dart   # Abstract
│   │   │   │   ├── local_db_service.dart    # SQLite (Free)
│   │   │   │   └── cloud_sync_service.dart  # Firebase (Pro)
│   │   │   ├── gps_service.dart             # Background GPS
│   │   │   ├── notification_service.dart    # Push notifiche
│   │   │   ├── health_service.dart          # Health Connect / Google Fit
│   │   │   ├── badge_service.dart           # Logica badge (corretta)
│   │   │   ├── speech_service.dart          # Speech-to-text
│   │   │   └── subscription_service.dart   # Free/Pro management
│   │   └── theme/
│   │       ├── app_theme.dart               # Light + Dark themes
│   │       └── app_typography.dart
│   ├── features/
│   │   ├── onboarding/                      # Prima apertura
│   │   ├── home/
│   │   │   ├── walk/                        # GPS tracking
│   │   │   ├── routine/                     # Daily habits
│   │   │   └── brainstorm/                  # Note vocali + testo
│   │   ├── history/                         # Calendario + storico
│   │   ├── analytics/                       # Grafici e statistiche
│   │   ├── achievements/                    # Badge system
│   │   └── settings/                        # Profilo, tema, export
│   ├── subscription/
│   │   ├── paywall_screen.dart              # Schermata upgrade
│   │   └── upgrade_prompts.dart             # Prompt contestuali
│   └── shared/
│       ├── widgets/                         # Widget riutilizzabili
│       └── utils/                           # Helper functions
├── assets/
│   ├── icons/                               # SVG icone badge
│   ├── animations/                          # Lottie animations
│   └── images/                              # Logo, splash
└── pubspec.yaml
```

### 2.2 Dipendenze Flutter (pubspec.yaml)

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter
  get_it: ^7.7.0                    # Dependency injection
  go_router: ^14.0.0                # Navigazione

  # State Management
  flutter_bloc: ^8.1.5              # BLoC pattern
  equatable: ^2.0.5

  # Storage - Free (Locale)
  sqflite: ^2.3.3                   # SQLite database
  shared_preferences: ^2.2.3        # Preferenze semplici
  path_provider: ^2.1.3

  # Storage - Pro (Cloud)
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.3
  cloud_firestore: ^5.2.0
  firebase_storage: ^12.1.0

  # GPS & Location
  geolocator: ^13.0.0               # Geolocalizzazione
  background_location: ^0.9.0       # GPS background

  # Notifiche
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4

  # Health Connect / Google Fit
  health: ^10.2.0

  # Widget homescreen
  home_widget: ^0.5.0

  # Speech Recognition
  speech_to_text: ^6.6.2

  # In-App Purchases (Free/Pro)
  in_app_purchase: ^3.2.1
  in_app_purchase_android: ^0.3.5

  # UI
  flutter_svg: ^2.0.10              # SVG rendering
  lottie: ^3.1.0                    # Animazioni
  fl_chart: ^0.68.0                 # Grafici analytics
  percent_indicator: ^4.2.3         # Progress rings

  # Utils
  intl: ^0.19.0                     # Date formatting (italiano)
  url_launcher: ^6.3.0              # Links AI esterni
  share_plus: ^10.0.3               # Condivisione note
  permission_handler: ^11.3.1       # Permessi runtime

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
```

---

## 3. FREE vs PRO TIERS

### Filosofia
- **FREE**: App completa e funzionale (come la PWA). Dati salvati localmente.
- **PRO**: Tutto il Free + backup cloud + funzionalità avanzate.

### 3.1 Feature Matrix

| Funzionalità | FREE | PRO |
|---|:---:|:---:|
| Storage | Locale (SQLite) | Cloud (Firebase) + Locale |
| Sincronizzazione multi-dispositivo | ❌ | ✅ |
| Backup automatico | ❌ | ✅ |
| Numero routine | Max 5 | Illimitato |
| Storico | 30 giorni | Illimitato |
| Walk tracking (foreground) | ✅ | ✅ |
| GPS background (schermo spento) | ❌ | ✅ |
| Brainstorming (testo) | ✅ | ✅ |
| Brainstorming (voce) | ❌ | ✅ |
| Badge di base (10) | ✅ | ✅ |
| Tutti i badge (20) | ❌ | ✅ |
| Notifiche push (base) | ✅ | ✅ |
| Notifiche intelligenti (AI-driven) | ❌ | ✅ |
| Analytics settimanali | ✅ | ✅ |
| Analytics mensili e annuali | ❌ | ✅ |
| Health Connect / Google Fit | ❌ | ✅ |
| Widget homescreen | ❌ | ✅ |
| Export JSON | ✅ | ✅ |
| Export PDF + CSV | ❌ | ✅ |
| Integrazione AI (Claude, GPT, Gemini) | ❌ | ✅ |
| Badge esclusivi Pro | ❌ | ✅ |
| Tema personalizzabile | Base (3 preset) | Completo |

### 3.2 Prezzi Suggeriti

| Piano | Prezzo | Descrizione |
|---|---|---|
| FREE | €0 | Per sempre, nessuna scadenza |
| PRO Mensile | €3,99/mese | Cancella quando vuoi |
| PRO Annuale | €29,99/anno | Risparmia il 37% |

---

## 4. SISTEMA BADGE — RIVISTO E CORRETTO

### 4.1 Bug Rilevati nella PWA (da correggere)

| # | Bug | Causa | Fix Android |
|---|---|---|---|
| 1 | Badge non appaiono al primo avvio | `checkMilestones('check_all')` mai chiamato | Verifica badge all'avvio dell'app |
| 2 | Badge "Primo Passo" mai sbloccato | `checkMilestones('walks')` mai chiamato | Chiama badge check al completamento walk |
| 3 | "Primo Pensiero" sbloccabile più volte | Flag `firstBrainstorm` è per-giorno, non globale | Flag globale nel profilo utente |
| 4 | Badge tagliati su schermi piccoli | `max-height:400px` + overflow | Layout scrollable senza height limit |
| 5 | Race condition nel display | `updateBadges()` chiamato prima del save | Await async storage prima del render |
| 6 | `countTotalWalks()` esiste ma mai usato | Codice morto | Integrato nel BadgeService |

### 4.2 Nuovi Badge (20 totali — 10 Free + 10 Pro)

#### CATEGORIA: CAMMINATA 🚶 (Walk)

| ID | Nome | Tier | Icona | Requisito | Frase di sblocco |
|---|---|---|---|---|---|
| `first_walk` | **Primo Passo** | Free | 👟 Scarpa con scia | Completa la prima camminata | *"Ogni grande viaggio inizia con un solo passo. Il tuo è appena cominciato."* |
| `walk_10` | **Esploratore** | Free | 🗺️ Mappa con percorso | 10 camminate totali | *"Dieci camminate, dieci storie. Stai costruendo qualcosa di bello."* |
| `walk_50` | **Camminatore** | Pro | 🥾 Scarpone da trekking | 50 camminate totali | *"Cinquanta volte hai scelto di muoverti. Sei un vero camminatore."* |
| `walk_100` | **Centurione** | Pro | 🏅 Medaglia con numero 100 | 100 camminate totali | *"Cento passi verso una vita migliore. Sei straordinario."* |

#### CATEGORIA: DISTANZA 📍 (Distance)

| ID | Nome | Tier | Icona | Requisito | Frase di sblocco |
|---|---|---|---|---|---|
| `km_5` | **Cinque Km** | Free | 🏁 Bandiera del traguardo | 5km totali | *"5 km di strada percorsa. Il corpo ti ringrazia."* |
| `km_10` | **Decathlon** | Free | 🎯 Bersaglio centrato | 10km totali | *"10 km. Ogni chilometro è una scelta di vivere bene."* |
| `km_50` | **Mezzo Centenario** | Pro | ⭐ Stella con numero 50 | 50km totali | *"50 km sotto i piedi. Stai riscrivendo i tuoi limiti."* |
| `km_100` | **Centochilomentri** | Pro | 🏆 Coppa dorata | 100km totali | *"100 km. Una distanza che racconta chi sei diventato."* |

#### CATEGORIA: DURATA ⏱️ (Time)

| ID | Nome | Tier | Icona | Requisito | Frase di sblocco |
|---|---|---|---|---|---|
| `time_20` | **Venti Minuti** | Free | ⏱️ Timer con freccia | Camminata da 20 min | *"20 minuti di presenza. La mente si è già ringraziata."* |
| `time_40` | **Quaranta Minuti** | Free | ⌛ Clessidra piena | Camminata da 40 min | *"40 minuti di libertà. Questo è il tuo tempo, ben speso."* |
| `time_60` | **L'Ora Intera** | Pro | 🕐 Orologio con corona | Camminata da 60 min | *"Un'ora. Non tutti hanno questa dedizione. Tu sì."* |

#### CATEGORIA: ROUTINE ✅ (Habits)

| ID | Nome | Tier | Icona | Requisito | Frase di sblocco |
|---|---|---|---|---|---|
| `routine_first` | **Inizio** | Free | 🌱 Germoglio | Prima routine completata | *"La prima volta è sempre la più importante. Ottimo inizio."* |
| `routine_50pct` | **A Metà** | Free | 📊 Grafico al 50% | 50% routine in un giorno | *"Metà fatta è già un grande risultato. Continua così."* |
| `routine_100pct` | **Perfetto** | Free | ✨ Stella brillante | 100% routine in un giorno | *"Giornata perfetta. Tutte le abitudini completate. Sei inarrestabile."* |

#### CATEGORIA: STREAK 🔥 (Consecutività)

| ID | Nome | Tier | Icona | Requisito | Frase di sblocco |
|---|---|---|---|---|---|
| `streak_7` | **Settimana di Fuoco** | Free | 🔥 Fiamma con 7 | 7 giorni consecutivi | *"7 giorni senza fermarsi. Stai creando un'abitudine vera."* |
| `streak_30` | **Guerriero del Mese** | Pro | ⚡ Fulmine con corona | 30 giorni consecutivi | *"Un mese intero. Questa non è più un'abitudine, è il tuo stile di vita."* |
| `streak_90` | **Mente di Acciaio** | Pro | 💎 Diamante | 90 giorni consecutivi | *"90 giorni. Hai trasformato te stesso. Questo è il cambiamento reale."* |

#### CATEGORIA: MENTE 💭 (Brainstorm)

| ID | Nome | Tier | Icona | Requisito | Frase di sblocco |
|---|---|---|---|---|---|
| `brain_first` | **Primo Pensiero** | Free | 💭 Nuvola pensiero | Prima nota brainstorm | *"Hai iniziato a dare voce ai tuoi pensieri. La mente cammina con te."* |
| `brain_10` | **Pensatore** | Pro | 🧠 Cervello stilizzato | 10 note brainstorm | *"Dieci idee catturate. Ogni pensiero scritto vale oro."* |

#### CATEGORIA: SPECIALI ⭐ (Speciali)

| ID | Nome | Tier | Icona | Requisito | Frase di sblocco |
|---|---|---|---|---|---|
| `special_combo` | **Mente e Corpo** | Pro | 🌊 Onda (brand icon) | Walk + Routine + Brain nello stesso giorno | *"Corpo, mente e abitudini in un solo giorno. Sei completo."* |

---

## 5. FRASI MOTIVAZIONALI

### 5.1 Notifiche Mattutine (7:00-9:00)

```
"Buongiorno! Il tuo corpo è pronto. La tua mente ti aspetta."
"Inizia la giornata muovendo un passo. Il resto verrà da sé."
"Ogni mattina è una pagina bianca. Scrivila con le tue scarpe."
"Il sole è già fuori. Metti le scarpe e raggiungilo."
"Le tue routine ti aspettano. 5 minuti per iniziare, un giorno per crescere."
"Un passo oggi vale più di mille pensieri domani."
"Ciao {nome}! Come ti senti stamattina? Muoviti un po' e scoprilo."
```

### 5.2 Notifiche Pomeridiane (13:00-15:00)

```
"Il pomeriggio è il momento perfetto per una pausa camminata."
"La testa è affollata? Cammina e lascia che i pensieri si sistemino da soli."
"Hai già completato le tue routine oggi? Un piccolo check ora."
"Una camminata di 20 minuti dopo pranzo fa miracoli. Provalo."
"{nome}, le tue routine di oggi ti stanno aspettando."
```

### 5.3 Notifiche Serali (19:00-21:00)

```
"Stai per chiudere la giornata. Hai catturato i tuoi pensieri?"
"Prima di smettere: 10 minuti di camminata serale per dormire meglio."
"Hai camminato oggi? Il tuo futuro te lo ringrazierà."
"La giornata finisce. Un pensiero da registrare prima di dormire?"
"Routine completata? Fantastico. Domani si ricomincia."
```

### 5.4 Notifiche di Achievement (Badge)

*(Già incluse nel sistema badge sopra — vengono mostrate con animazione confetti)*

### 5.5 Frasi Quote of the Day (Italiane locali)

```
"Il segreto per andare avanti è cominciare." — Mark Twain
"Non aspettare. Il momento non sarà mai perfetto." — Napoleone Hill
"Chi cammina piano va lontano e va sano." — Proverbio italiano
"Il corpo raggiunge ciò che la mente crede." — Anonimo
"Ogni giorno è una nuova opportunità di cambiare la tua vita." — Anonimo
"La salute è la vera ricchezza, non l'oro o l'argento." — Mahatma Gandhi
"Muoviti ogni giorno. Non perché devi, ma perché puoi." — Anonimo
"La mente è tutto. Sei ciò che pensi." — Buddha
"Un passo dopo l'altro, e la montagna è vinta." — Proverbio
"Il movimento è vita. La vita è movimento." — Joseph Pilates
"Mens sana in corpore sano." — Giovenale
"Fai ogni giorno qualcosa che non sai fare." — Eleanor Roosevelt
"Il successo è la somma di piccoli sforzi ripetuti ogni giorno." — Robert Collier
"Prima cura il tuo corpo; senza salute non c'è felicità." — Anonimo
"Cammina come se stessi baciando la Terra con i tuoi piedi." — Thich Nhat Hanh
```

### 5.6 Frasi Schermata Onboarding

```
Schermata 1 (Benvenuto):
"Unisci corpo e mente.
 Cammina, rifletti, cresci ogni giorno."

Schermata 2 (Walk):
"Traccia ogni passo.
 La distanza che percorri costruisce la persona che diventi."

Schermata 3 (Routine):
"Le piccole abitudini
 fanno i grandi cambiamenti."

Schermata 4 (Brainstorm):
"Le idee migliori nascono
 mentre cammini. Catturale."

Schermata 5 (Pronto!):
"Il viaggio inizia adesso.
 Un passo alla volta."
```

### 5.7 Frasi Schermata Vuota (Empty States)

```
Nessuna camminata ancora:
"Non hai ancora camminato oggi. Ogni grande viaggio inizia con un passo."

Nessuna routine:
"Aggiungi la tua prima abitudine. Anche qualcosa di piccolo conta."

Nessuna nota brainstorm:
"La tua mente ha cose da dire. Inizia a scriverle qui."

Nessun dato storico:
"Il tuo diario è ancora vuoto. Inizia oggi la tua storia."

Nessun badge:
"I tuoi traguardi ti aspettano. Inizia a camminare per sbloccarli."
```

---

## 6. SCHERMATE E FLUSSO NAVIGAZIONE

### 6.1 Flusso Onboarding

```
Splash Screen (2s)
    ↓
Onboarding 5 slides (solo prima volta)
    ↓
Setup Profilo
  ├── Nome
  ├── Età
  └── Genere
    ↓
Setup Routine (skip possibile)
  └── Aggiungi fino a 5 routine (Free) / illimitate (Pro)
    ↓
Main App → Home Tab
```

### 6.2 Navigazione Principale (Bottom Navigation Bar)

```
┌─────────────────────────────────────┐
│            CONTENT AREA             │
├─────────┬────────┬───────┬──────────┤
│  🏠     │  📅    │  📊   │  🏅  │  ⚙️  │
│  Home   │Storico │ Dati  │Traguardi │Altro│
└─────────┴────────┴───────┴──────────┘
```

### 6.3 Schermata Home — Layout Android

```
┌────────────────────────────────┐
│  MindStep           🌤️ 18°C    │  ← AppBar con meteo
├────────────────────────────────┤
│  Ciao Marco! 👋                │
│  "Quote del giorno..."          │
├────────────────────────────────┤
│  ┌──────────────────────────┐  │
│  │     CAMMINATA OGGI       │  │
│  │   ⭕ Ring progresso      │  │
│  │   0:00:00  0.0km  0kcal  │  │
│  │   [▶ INIZIA CAMMINATA]   │  │
│  └──────────────────────────┘  │
├────────────────────────────────┤
│  LE TUE ROUTINE                │
│  ▓▓▓▓░░░░░░░░ 40%             │
│  ☑ Meditazione mattutina       │
│  ☑ Lettura 20 min              │
│  ☐ Stretching                  │
│  ☐ Acqua 2L                    │
│  ☐ Journaling serale           │
├────────────────────────────────┤
│  BRAINSTORMING                 │
│  🎤 [Registra vocale] (Pro)    │
│  📝 [Scrivi nota]              │
│  ┌──────────────────────────┐  │
│  │ La tua nota appare qui...│  │
│  └──────────────────────────┘  │
│  [Invia a AI] [Esporta]        │
├────────────────────────────────┤
│  MUSICA                        │
│  [Spotify] [YouTube] [Apple]   │
└────────────────────────────────┘
```

### 6.4 Walk Tracking — Stati

```
STATO: IDLE
┌────────────────────────────────┐
│      ⭕ 0:00:00                │
│      Grande cerchio grigio     │
│      0.0 km  │  0.0 km/h       │
│      0 kcal  │  0 min          │
│  [▶ INIZIA CAMMINATA]          │
└────────────────────────────────┘

STATO: ACTIVE (foreground)
┌────────────────────────────────┐
│      ⭕ 00:23:45  ← animato    │
│      Cerchio cyan progress     │
│      2.3 km  │  5.9 km/h       │
│      180 kcal│  23 min         │
│  [⏸ PAUSA]  [⏹ FERMA]         │
└────────────────────────────────┘

STATO: BACKGROUND (Pro — schermo spento)
→ Notifica persistente:
  "🚶 Camminata in corso | 2.3km | 23:45"
  [Pausa] [Stop]

STATO: PAUSED
┌────────────────────────────────┐
│      ⭕ 00:23:45  ← statico    │
│      Cerchio semi-trasparente  │
│      2.3 km  │  —              │
│      180 kcal│  23 min         │
│  [▶ RIPRENDI]  [⏹ FERMA]      │
└────────────────────────────────┘

STATO: COMPLETED
→ Modal con riepilogo:
  "Ottima camminata! 🎉"
  [Distanza] [Tempo] [Velocità] [Calorie]
  [Salva] [Condividi]
```

---

## 7. GPS BACKGROUND — LOGICA PAUSE/RESUME

### 7.1 Architettura GPS Service

```dart
// Foreground Walk (Free + Pro)
// - Usa geolocator plugin
// - Si ferma quando app va in background

// Background Walk (Pro only)
// - Usa background_location plugin
// - Foreground Service Android (notifica persistente obbligatoria)
// - Salva posizioni ogni 5 secondi
// - Pausa/Riprendi mantiene il percorso
```

### 7.2 Logica Pause/Resume (corretta)

```
AVVIA WALK:
  1. Richiedi permesso location (always — Pro)
  2. Crea WalkSession con startTime, sessionId
  3. Salva checkpoint: { lat, lng, timestamp, distance: 0 }
  4. Avvia Foreground Service (Pro) con notifica
  5. Inizia watchPosition ogni 5s

PAUSA:
  1. Stoppa watchPosition
  2. Salva ultimo checkpoint con flag isPaused = true
  3. Registra pauseTime
  4. Aggiorna notifica: "In pausa | 2.3km percorsi"
  5. Conserva in memoria: lastPosition, totalDistance, elapsedTime

RIPRENDI:
  1. NON resettare totalDistance o elapsedTime
  2. Registra resumeTime
  3. Imposta "lastValidPosition" = ultimo checkpoint salvato
  4. Inizia di nuovo watchPosition
  5. Ignora primo punto se troppo distante dall'ultimo (> 50m → possibile drift GPS)
  6. Aggiorna notifica: "In corso | 2.3km"

FERMA:
  1. Calcola tempo totale = sum(segmenti attivi, esclusi pausa)
  2. Salva WalkSession completa nel DB
  3. Ferma Foreground Service
  4. Avvia badge check
  5. Sincronizza Health Connect (Pro)
  6. Mostra riepilogo
```

### 7.3 Haversine Distance (portato dal JS)

```dart
double calcDistance(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0; // Earth radius in meters
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
      sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c; // distance in meters
}
```

### 7.4 Filtro Anti-Drift GPS

```dart
// Ignora posizioni con accuratezza > 20m
// Ignora salti di distanza > 100m in < 5 secondi (impossibile a piedi)
// Minima distanza per registrare nuovo punto: 5m
```

---

## 8. SISTEMA NOTIFICHE

### 8.1 Tipi di Notifiche

| Tipo | ID | Trigger | Orario | Free | Pro |
|---|---|---|---|---|---|
| Reminder mattutino | `morning_reminder` | Schedulata | 8:00 | ✅ | ✅ |
| Reminder routine | `routine_reminder` | Schedulata | Custom | ✅ | ✅ |
| Walk reminder | `walk_reminder` | Schedulata | Custom | ✅ | ✅ |
| Brain reminder | `brain_reminder` | Schedulata | Custom | ❌ | ✅ |
| Walk in corso | `walk_ongoing` | GPS attivo | Real-time | ✅ | ✅ |
| Badge sbloccato | `badge_unlock` | Evento | Real-time | ✅ | ✅ |
| Streak in pericolo | `streak_warning` | Check sera | 20:00 | ❌ | ✅ |
| Obiettivo vicino | `goal_approaching` | Check | Real-time | ❌ | ✅ |

### 8.2 Canali Notifica Android

```dart
NotificationChannel(
  id: 'walk_tracking',
  name: 'Camminata in corso',
  importance: Importance.low,   // Non disturba
  showBadge: false,
)

NotificationChannel(
  id: 'reminders',
  name: 'Promemoria',
  importance: Importance.defaultImportance,
)

NotificationChannel(
  id: 'achievements',
  name: 'Traguardi',
  importance: Importance.high,
  sound: 'achievement_sound',
)
```

---

## 9. HEALTH CONNECT & GOOGLE FIT

### 9.1 Dati Sincronizzati

| Dato MindStep | Health Connect Type | Direzione |
|---|---|---|
| Distanza camminata | `DistanceRecord` | → Write |
| Calorie bruciate | `ActiveCaloriesBurnedRecord` | → Write |
| Durata esercizio | `ExerciseSessionRecord` | → Write |
| Passi (stima) | `StepsRecord` | ← Read + Write |
| Frequenza cardiaca | `HeartRateRecord` | ← Read |
| Sonno | `SleepSessionRecord` | ← Read |

### 9.2 Permessi Richiesti

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.WRITE_STEPS"/>
<uses-permission android:name="android.permission.health.READ_DISTANCE"/>
<uses-permission android:name="android.permission.health.WRITE_DISTANCE"/>
<uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED"/>
<uses-permission android:name="android.permission.health.WRITE_ACTIVE_CALORIES_BURNED"/>
<uses-permission android:name="android.permission.health.WRITE_EXERCISE"/>
```

---

## 10. WIDGET HOMESCREEN

### 10.1 Widget "Oggi al Volo"

```
┌─────────────────────────────────┐
│ MindStep                    🟢  │
│                                 │
│ 🚶 0.0 km   ✅ 2/5  💭 0 note  │
│                                 │
│ [▶ Inizia Camminata]           │
└─────────────────────────────────┘
Dimensione: 4x1 (half-width)
```

### 10.2 Widget "Statistiche Giorno"

```
┌──────────────────┐
│ MindStep  Oggi   │
│                  │
│  ⭕ 40%          │
│  Routine         │
│                  │
│  2.3 km          │
│  Percorsi        │
└──────────────────┘
Dimensione: 2x2
```

---

## 11. COLORI & DESIGN SYSTEM (Flutter)

### 11.1 Palette (identica alla PWA)

```dart
// Light Mode
primary: Color(0xFF00D4FF),        // Cyan
primaryDark: Color(0xFF00B4D8),
secondary: Color(0xFF5CE1E6),
accent: Color(0xFF3B4FA0),         // Navy
background: Color(0xFFFFFFFF),
bgSecondary: Color(0xFFF5F7FA),
textPrimary: Color(0xFF0F1419),
textSecondary: Color(0xFF4A5568),
border: Color(0xFFE5E7EB),

// Dark Mode
primaryDark_bg: Color(0xFF0A1128),    // Navy darkest
bgSecondaryDark: Color(0xFF1A2357),
textDark: Color(0xFFFFFFFF),
primaryInDark: Color(0xFF5CE1E6),
```

### 11.2 Tipografia (Google Fonts: Inter)

```dart
TextStyle heading1 = TextStyle(
  fontFamily: 'Inter',
  fontSize: 28, fontWeight: FontWeight.w800
);
TextStyle heading2 = TextStyle(
  fontFamily: 'Inter',
  fontSize: 22, fontWeight: FontWeight.w700
);
TextStyle timerStyle = TextStyle(
  fontFamily: 'Courier New',
  fontSize: 48, fontWeight: FontWeight.w600
);
```

### 11.3 Icone Badge — Descrizione Visiva SVG

Ogni badge ha un'icona custom SVG da creare. Stile: lineare, 2px stroke, colore cyan su sfondo circolare.

| Badge | Icona SVG Descrizione |
|---|---|
| Primo Passo | Impronta di scarpa con scia punteggiata |
| Esploratore | Mappa arrotolata con punto X |
| Camminatore | Due scarpe stilizzate |
| Centurione | Scudo con numero 100 |
| Cinque Km | Bandiera del traguardo su linea |
| Decathlon | Bersaglio concentrico |
| Mezzo Centenario | Stelle con numero 50 |
| Cento Chilometri | Coppa stilizzata |
| Venti Minuti | Timer con freccia e 20 |
| Quaranta Minuti | Clessidra piena |
| L'Ora Intera | Orologio con cerchio completo |
| Inizio | Germoglio che sboccia |
| A Metà | Cerchio a metà pieno |
| Perfetto | Check circondato da stelle |
| Settimana di Fuoco | Fiamma con 7 giorni |
| Guerriero del Mese | Fulmine con corona |
| Mente di Acciaio | Diamante stilizzato |
| Primo Pensiero | Nuvola pensiero con matita |
| Pensatore | Cervello con onde |
| Mente e Corpo | Onda (logo MindStep) con doppia spirale |

---

## 12. PIANO DI SVILUPPO

### Fase 1 — Foundation (Settimana 1-2)
1. Setup Flutter project
2. Design system (colori, font, componenti base)
3. Modelli dati (User, Walk, Routine, Badge, DayData)
4. Storage locale (SQLite + SharedPreferences)
5. Navigazione (GoRouter, Bottom Nav)
6. Onboarding flow

### Fase 2 — Core Features (Settimana 3-4)
7. Home screen completa
8. Walk tracking (foreground GPS)
9. Routine system
10. Brainstorming (testo)
11. Sistema badge (tutti i 20, con bug risolti)
12. History / Calendar

### Fase 3 — Analytics & Polish (Settimana 5)
13. Analytics screen (grafici fl_chart)
14. Settings screen
15. Dark mode
16. Animazioni e transizioni
17. Citazioni del giorno

### Fase 4 — Pro Features (Settimana 6-7)
18. GPS Background (Foreground Service)
19. Speech recognition (brainstorm vocale)
20. Notifiche push (scheduling)
21. Health Connect / Google Fit
22. Widget homescreen
23. Firebase integration (cloud sync)
24. In-app purchase (Free/Pro paywall)
25. AI integration (links)

### Fase 5 — QA & Release (Settimana 8)
26. Testing su dispositivi fisici
27. Fix bug
28. Play Store assets (screenshot, descrizione)
29. Build release + firma APK
30. Publish su Google Play (alpha → beta → production)

---

*Documento creato il 23 Febbraio 2026*
*Versione 1.0 — Pre-sviluppo*
*Pronto per review → poi si scrive il codice*
