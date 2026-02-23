/// Tutte le stringhe dell'app in italiano
class AppStrings {
  AppStrings._();

  // ── APP ────────────────────────────────────────────────────────────────
  static const appName = 'MindStep';
  static const tagline = 'Unisci corpo e mente.\nCammina, rifletti, cresci ogni giorno.';

  // ── NAVIGAZIONE ────────────────────────────────────────────────────────
  static const navHome = 'Home';
  static const navHistory = 'Storico';
  static const navAnalytics = 'Dati';
  static const navAchievements = 'Traguardi';
  static const navSettings = 'Altro';

  // ── ONBOARDING ─────────────────────────────────────────────────────────
  static const onboardingSkip = 'Salta';
  static const onboardingNext = 'Avanti';
  static const onboardingStart = 'Inizia';
  static const onboardingGetStarted = 'Cominciamo!';

  static const List<Map<String, String>> onboardingSlides = [
    {
      'title': 'Benvenuto in MindStep',
      'body': 'Unisci corpo e mente.\nCammina, rifletti, cresci ogni giorno.',
      'emoji': '🌊',
    },
    {
      'title': 'Traccia ogni passo',
      'body': 'La distanza che percorri\nconstruisce la persona che diventi.',
      'emoji': '🚶',
    },
    {
      'title': 'Le piccole abitudini',
      'body': 'fanno i grandi cambiamenti.\nOgni giorno, un passo alla volta.',
      'emoji': '✅',
    },
    {
      'title': 'Cattura i tuoi pensieri',
      'body': 'Le idee migliori nascono\nmentre cammini. Non perderle.',
      'emoji': '💭',
    },
    {
      'title': 'Il viaggio inizia adesso',
      'body': 'Un passo alla volta.\nSei pronto?',
      'emoji': '🎯',
    },
  ];

  // ── SETUP PROFILO ──────────────────────────────────────────────────────
  static const setupTitle = 'Raccontaci di te';
  static const setupSubtitle = 'Questi dati rimangono sul tuo dispositivo';
  static const setupNameLabel = 'Come ti chiami?';
  static const setupNameHint = 'Il tuo nome';
  static const setupAgeLabel = 'Quanti anni hai?';
  static const setupAgeHint = 'Età';
  static const setupGenderLabel = 'Genere';
  static const setupGenderM = 'Uomo';
  static const setupGenderF = 'Donna';
  static const setupGenderA = 'Preferisco non specificare';
  static const setupRoutinesTitle = 'Le tue prime abitudini';
  static const setupRoutinesSubtitle =
      'Aggiungi le routine che vuoi completare ogni giorno\n(puoi sempre modificarle dopo)';
  static const setupRoutineHint = 'Es. Meditazione 10 min';
  static const setupRoutineAdd = 'Aggiungi abitudine';
  static const setupRoutineSkip = 'Salto per ora';
  static const setupContinue = 'Continua';
  static const setupDone = 'Inizia il viaggio';
  static const setupFreeLimit = 'Piano Free: max 5 abitudini';

  // ── HOME ───────────────────────────────────────────────────────────────
  static const homeGreetingMorning = 'Buongiorno';
  static const homeGreetingAfternoon = 'Buon pomeriggio';
  static const homeGreetingEvening = 'Buonasera';

  // ── WALK ───────────────────────────────────────────────────────────────
  static const walkTitle = 'Camminata di oggi';
  static const walkStart = 'Inizia camminata';
  static const walkPause = 'Pausa';
  static const walkResume = 'Riprendi';
  static const walkStop = 'Ferma';
  static const walkKm = 'km';
  static const walkSpeed = 'km/h';
  static const walkCalories = 'kcal';
  static const walkMinutes = 'min';
  static const walkCompleted = 'Camminata completata!';
  static const walkSummary = 'Ottimo lavoro! Ecco il riepilogo:';
  static const walkSave = 'Salva';
  static const walkShare = 'Condividi';
  static const walkDiscard = 'Scarta';
  static const walkLocationPermission =
      'Per tracciare la camminata è necessario il permesso di localizzazione.';
  static const walkLocationPermissionDeny =
      'Senza permesso di localizzazione non puoi tracciare la camminata.';
  static const walkBackgroundProOnly =
      'Il tracciamento in background è una funzionalità PRO';
  static const walkBackgroundProDesc =
      'Con il piano PRO puoi continuare a tracciare la camminata anche con lo schermo spento.';

  // ── ROUTINE ────────────────────────────────────────────────────────────
  static const routineTitle = 'Le tue routine';
  static const routineEmpty = 'Nessuna routine aggiunta.\nTocca + per iniziare.';
  static const routineAdd = 'Nuova abitudine';
  static const routineEdit = 'Modifica';
  static const routineDelete = 'Elimina';
  static const routineProgress = 'completate';
  static const routineAllDone = 'Perfetto! Tutte le routine completate! ✨';
  static const routineHalfDone = 'Ottimo lavoro! Sei a metà strada! 📊';
  static const routineFreeLimitReached =
      'Hai raggiunto il limite di 5 abitudini del piano Free.\nUpgrade a PRO per abitudini illimitate.';

  // ── BRAINSTORM ─────────────────────────────────────────────────────────
  static const brainTitle = 'Brainstorming';
  static const brainRecord = 'Registra vocale';
  static const brainStopRecord = 'Ferma registrazione';
  static const brainWrite = 'Scrivi nota';
  static const brainPlaceholder =
      'I tuoi pensieri di oggi...\nParla o scrivi mentre cammini.';
  static const brainSave = 'Salva nota';
  static const brainExport = 'Esporta';
  static const brainSendAI = 'Invia a AI';
  static const brainClear = 'Cancella';
  static const brainSaved = 'Nota salvata';
  static const brainVoiceProOnly = 'La registrazione vocale è PRO';
  static const brainVoiceProDesc =
      'Con il piano PRO puoi registrare i tuoi pensieri con la voce mentre cammini.';
  static const brainAIOptions = 'Scegli l\'AI';

  // ── STORICO ────────────────────────────────────────────────────────────
  static const historyTitle = 'Il tuo storico';
  static const historyEmpty = 'Nessuna attività in questo mese.';
  static const historyWalk = 'Camminata';
  static const historyRoutine = 'Routine';
  static const historyNotes = 'Note';
  static const historyRestrictedFree =
      'Visualizza gli ultimi 30 giorni con il piano Free.\nUpgrade a PRO per lo storico completo.';

  // ── ANALYTICS ─────────────────────────────────────────────────────────
  static const analyticsTitle = 'I tuoi dati';
  static const analyticsWeekly = 'Settimana';
  static const analyticsMonthly = 'Mese';
  static const analyticsYearly = 'Anno';
  static const analyticsActivedays = 'Giorni attivi';
  static const analyticsTotalKm = 'Km totali';
  static const analyticsAvgRoutine = 'Media routine';
  static const analyticsStreak = 'Streak';
  static const analyticsStreakDays = 'giorni';
  static const analyticsMonthlyProOnly =
      'Analytics mensili e annuali sono disponibili con PRO.';

  // ── BADGE ─────────────────────────────────────────────────────────────
  static const achievementsTitle = 'I tuoi traguardi';
  static const achievementsEmpty = 'Completa camminate e routine per sbloccare i tuoi traguardi!';
  static const badgeLocked = 'Bloccato';
  static const badgeUnlocked = 'Sbloccato';
  static const badgeProOnly = 'Disponibile con PRO';

  // ── SETTINGS ──────────────────────────────────────────────────────────
  static const settingsTitle = 'Impostazioni';
  static const settingsProfile = 'Il mio profilo';
  static const settingsTheme = 'Tema';
  static const settingsThemeLight = 'Chiaro';
  static const settingsThemeDark = 'Scuro';
  static const settingsThemeAuto = 'Automatico';
  static const settingsNotifications = 'Notifiche';
  static const settingsHealthConnect = 'Health Connect';
  static const settingsRoutines = 'Gestisci routine';
  static const settingsExportJSON = 'Esporta dati (JSON)';
  static const settingsExportPDF = 'Esporta report (PDF)';
  static const settingsExportPDFPro = 'Export PDF — PRO';
  static const settingsReset = 'Reimposta app';
  static const settingsResetConfirm =
      'Sei sicuro? Tutti i tuoi dati verranno eliminati definitivamente.';
  static const settingsResetConfirmButton = 'Sì, elimina tutto';
  static const settingsCancel = 'Annulla';
  static const settingsVersion = 'Versione';
  static const settingsFeedback = 'Invia feedback';
  static const settingsPrivacy = 'Privacy Policy';

  // ── SUBSCRIPTION ──────────────────────────────────────────────────────
  static const proTitle = 'MindStep PRO';
  static const proSubtitle = 'Sblocca il tuo potenziale completo';
  static const proMonthly = '€3,99 / mese';
  static const proAnnual = '€29,99 / anno';
  static const proAnnualSave = 'Risparmia il 37%';
  static const proFreeTrial = '7 giorni gratuiti';
  static const proUpgrade = 'Passa a PRO';
  static const proRestore = 'Ripristina acquisti';
  static const proFeatureGPS = 'GPS in background (schermo spento)';
  static const proFeatureVoice = 'Registrazione vocale brainstorm';
  static const proFeatureCloud = 'Backup e sync cloud';
  static const proFeatureWidget = 'Widget sulla home Android';
  static const proFeatureHealth = 'Integrazione Health Connect';
  static const proFeatureBadges = 'Tutti i 20 traguardi';
  static const proFeatureAnalytics = 'Analytics mensili e annuali';
  static const proFeatureAI = 'Integrazione AI (Claude, ChatGPT, Gemini)';
  static const proFeatureExport = 'Export PDF e CSV';
  static const proFeatureUnlimited = 'Routine illimitate';

  // ── NOTIFICHE ─────────────────────────────────────────────────────────
  static const notifWalkOngoing = 'Camminata in corso';
  static const notifWalkPaused = 'Camminata in pausa';
  static const notifMorningDefault = 'Buongiorno! Inizia la giornata con un passo.';
  static const notifStreakWarning = '⚠️ Non perdere la tua streak!';
  static const notifBadgePrefix = '🏅 Traguardo sbloccato: ';

  static const List<String> morningMessages = [
    'Buongiorno! Il tuo corpo è pronto. La tua mente ti aspetta.',
    'Inizia la giornata muovendo un passo. Il resto verrà da sé.',
    'Ogni mattina è una pagina bianca. Scrivila con le tue scarpe.',
    'Il sole è già fuori. Metti le scarpe e raggiungilo.',
    'Un passo oggi vale più di mille pensieri domani.',
  ];

  static const List<String> afternoonMessages = [
    'Il pomeriggio è il momento perfetto per una pausa camminata.',
    'La testa è affollata? Cammina e lascia che i pensieri si sistemino.',
    'Hai già completato le tue routine oggi?',
    'Una camminata di 20 minuti fa miracoli. Provalo.',
  ];

  static const List<String> eveningMessages = [
    'Stai per chiudere la giornata. Hai catturato i tuoi pensieri?',
    'Prima di smettere: 10 minuti di camminata serale per dormire meglio.',
    'Routine completate? Ottimo. Domani si ricomincia ancora più forti.',
    'La giornata finisce. Un pensiero da registrare prima di dormire?',
  ];

  // ── QUOTES LOCALI ─────────────────────────────────────────────────────
  static const List<String> localQuotes = [
    '"Il segreto per andare avanti è cominciare." — Mark Twain',
    '"Non aspettare. Il momento non sarà mai perfetto." — N. Hill',
    '"Chi cammina piano va lontano e va sano." — Proverbio italiano',
    '"Il corpo raggiunge ciò che la mente crede." — Anonimo',
    '"Mens sana in corpore sano." — Giovenale',
    '"Muoviti ogni giorno. Non perché devi, ma perché puoi." — Anonimo',
    '"La mente è tutto. Sei ciò che pensi." — Buddha',
    '"Un passo dopo l\'altro, e la montagna è vinta." — Proverbio',
    '"Il movimento è vita. La vita è movimento." — Joseph Pilates',
    '"Fai ogni giorno qualcosa che non sai fare." — Eleanor Roosevelt',
    '"Il successo è la somma di piccoli sforzi ripetuti ogni giorno." — R. Collier',
    '"Cammina come se stessi baciando la Terra con i tuoi piedi." — T. N. Hanh',
    '"La salute è la vera ricchezza, non l\'oro." — Mahatma Gandhi',
    '"Ogni grande viaggio inizia con un solo passo." — Lao Tzu',
    '"La forza non viene dalla vittoria. Viene dalla lotta." — Arnold S.',
  ];

  // ── EMPTY STATES ──────────────────────────────────────────────────────
  static const emptyWalk =
      'Non hai ancora camminato oggi.\nOgni grande viaggio inizia con un passo.';
  static const emptyRoutine =
      'Aggiungi la tua prima abitudine.\nAnche qualcosa di piccolo conta.';
  static const emptyBrainstorm =
      'La tua mente ha cose da dire.\nInizia a scriverle qui.';
  static const emptyHistory = 'Il tuo diario è ancora vuoto.\nInizia oggi la tua storia.';
  static const emptyAchievements =
      'I tuoi traguardi ti aspettano.\nInizia a camminare per sbloccarli.';

  // ── ERRORI ────────────────────────────────────────────────────────────
  static const errorGeneric = 'Qualcosa è andato storto. Riprova.';
  static const errorNoInternet = 'Nessuna connessione. Alcune funzioni non sono disponibili.';
  static const errorPermissionLocation = 'Permesso localizzazione negato.';
  static const errorPermissionMicrophone = 'Permesso microfono negato.';

  // ── AI ────────────────────────────────────────────────────────────────
  static const aiPromptPrefix =
      'Analizza questi miei pensieri del giorno e dammi insights, pattern e suggerimenti concreti:\n\n';
  static const aiClaude = 'Claude';
  static const aiChatGPT = 'ChatGPT';
  static const aiGemini = 'Gemini';
  static const aiCopilot = 'Copilot';

  // ── MUSICA ────────────────────────────────────────────────────────────
  static const musicTitle = 'Musica';
  static const musicSpotify = 'Spotify';
  static const musicYouTube = 'YouTube Music';
  static const musicApple = 'Apple Music';
  static const musicCustom = 'Link personalizzato';
}
