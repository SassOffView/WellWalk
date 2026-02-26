import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/daily_insight.dart';
import '../../core/models/day_data.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/walk_session.dart';
import '../../core/services/quote_service.dart';
import '../../core/services/weather_service.dart';
import '../../shared/widgets/ms_card.dart';
import 'routine/routine_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile;
  DayData? _dayData;
  DailyInsight? _insight;
  DailyQuote? _quote;
  WeatherData? _weather;
  bool _loading = true;
  bool _sessionDone = false;
  bool _locationPermissionAsked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final services = context.read<AppServices>();
    final results = await Future.wait([
      services.db.loadUserProfile(),
      services.db.loadDayData(DateTime.now()),
      services.db.hasSessionToday(),
    ]);
    final profile = results[0] as UserProfile?;
    final dayData = results[1] as DayData;
    final sessionDone = results[2] as bool;

    // Controlla badge al caricamento
    await services.badges.checkAllBadgesOnStartup(isPro: services.isPro);

    // Carica quote giornaliera
    DailyQuote? quote;
    try {
      quote = await services.quotes
          .getDailyQuote(profile?.preferredLanguage ?? 'it');
    } catch (_) {}

    if (mounted) {
      setState(() {
        _profile = profile;
        _dayData = dayData;
        _sessionDone = sessionDone;
        _quote = quote;
        _loading = false;
      });

      // Carica insight AI in background
      if (profile != null) {
        _loadInsight(services, profile);
      }

      // Chiede permesso GPS alla prima apertura e carica meteo
      _requestLocationAndWeather(services);

      // Popup notifiche alla prima apertura (se onboarding completato)
      if (profile?.hasCompletedOnboarding == true) {
        _maybeShowNotificationPrompt();
      }
    }
  }

  Future<void> _requestLocationAndWeather(AppServices services) async {
    if (_locationPermissionAsked) return;
    _locationPermissionAsked = true;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );
        final w = await services.weather.getWeather(
            pos.latitude, pos.longitude);
        if (mounted) setState(() => _weather = w);
      }
    } catch (_) {}
  }

  Future<void> _maybeShowNotificationPrompt() async {
    const key = 'notification_prompt_shown';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);

    // Breve pausa per lasciar rendere la home prima di mostrare il popup
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final services = context.read<AppServices>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Attiva i promemoria',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Vuoi ricevere notifiche per i tuoi promemoria giornalieri e i badge sbloccati?\n\nPuoi cambiare questa scelta in qualsiasi momento nelle impostazioni.',
          style: TextStyle(color: AppColors.darkTextSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Non ora',
              style: TextStyle(color: AppColors.darkTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: AppColors.navyDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Abilita'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await services.notifications.requestPermission();
    }
  }

  Future<void> _loadInsight(AppServices services, UserProfile profile) async {
    try {
      final insight = await services.aiInsight.getDailyInsight(profile);
      if (mounted) {
        setState(() => _insight = insight);
        if (insight.generatedBy != 'locale') {
          services.updateMorningMessageWithInsight(insight.motivationalMessage);
        }
      }
    } catch (_) {}
  }

  Future<void> _reload() async {
    final services = context.read<AppServices>();
    final results = await Future.wait([
      services.db.loadDayData(DateTime.now()),
      services.db.hasSessionToday(),
    ]);
    if (mounted) {
      setState(() {
        _dayData = results[0] as DayData;
        _sessionDone = results[1] as bool;
      });
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return AppStrings.homeGreetingMorning;
    if (h < 18) return AppStrings.homeGreetingAfternoon;
    return AppStrings.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.cyan,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // ── App Bar con meteo ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()}, ${_profile?.firstName ?? 'amico'}!',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // Widget meteo animato (top right)
                      _WeatherBadge(weather: _weather),
                    ],
                  ),
                ),
              ),

              // ── Quote motivazionale ─────────────────────────────────────
              if (_quote != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: MsCard(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.navyMid
                          : AppColors.cyan.withOpacity(0.05),
                      borderColor: AppColors.cyan.withOpacity(0.2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              PhosphorIcon(
                                PhosphorIcons.quotes(PhosphorIconsStyle.fill),
                                color: AppColors.cyan,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Citazione del giorno',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cyan.withOpacity(0.7),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '"${_quote!.text}"',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '— ${_quote!.author}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Clarity Session Widget (unifica passi + sessione + GPS + voce) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _ClaritySessionWidget(
                    initialDayData: _dayData,
                    userProfile: _profile,
                    insightForPopup: _insight,
                    sessionDone: _sessionDone,
                    onSessionComplete: _reload,
                  ),
                ),
              ),

              // ── Routine Widget ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: RoutineWidget(
                    dayData: _dayData,
                    onChanged: _reload,
                  ),
                ),
              ),

              // ── Musica ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildMusicSection(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMusicSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MsSectionHeader(title: AppStrings.musicTitle),
          Row(
            children: [
              _MusicButton(
                label: 'Spotify',
                color: const Color(0xFF1DB954),
                icon: PhosphorIcons.musicNote(),
                url: 'https://open.spotify.com',
              ),
              const SizedBox(width: 8),
              _MusicButton(
                label: 'YouTube',
                color: const Color(0xFFFF0000),
                icon: PhosphorIcons.youtubeLogo(),
                url: 'https://music.youtube.com',
              ),
              const SizedBox(width: 8),
              _MusicButton(
                label: 'Apple',
                color: const Color(0xFFFA243C),
                icon: PhosphorIcons.appleLogo(),
                url: 'https://music.apple.com',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    const days = [
      'lunedì', 'martedì', 'mercoledì', 'giovedì',
      'venerdì', 'sabato', 'domenica'
    ];
    const months = [
      'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
      'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

// ─── Clarity Session Widget ───────────────────────────────────────────────────
// Walking-Brain: 3 anelli concentrici + stati bottone dinamici
// idle:   anelli vuoti + "Inizia WalkingBrain"
// active: anelli con progresso live + "Interrompi sessione"
// paused: anelli congelati + "Riprendi / Termina"
// done:   card completamento + "Esporta Brain-Storming"

enum _SessionPhase { idle, active, paused, done }

class _ClaritySessionWidget extends StatefulWidget {
  const _ClaritySessionWidget({
    required this.initialDayData,
    required this.userProfile,
    required this.insightForPopup,
    required this.sessionDone,
    required this.onSessionComplete,
  });

  final DayData? initialDayData;
  final UserProfile? userProfile;
  final DailyInsight? insightForPopup;
  final bool sessionDone;
  final VoidCallback onSessionComplete;

  @override
  State<_ClaritySessionWidget> createState() => _ClaritySessionWidgetState();
}

class _ClaritySessionWidgetState extends State<_ClaritySessionWidget> {
  late _SessionPhase _phase;

  // GPS / Walk
  WalkSession? _walkSession;
  bool _requestingPermission = false;
  bool _insightShown = false;

  // Pedometro
  int _stepCountBase = 0;
  int _currentSteps = 0;
  StreamSubscription<StepCount>? _stepSub;

  // Voce
  final _speechToText = SpeechToText();
  bool _speechAvailable = false;
  bool _isRecording = false;
  String _accumulatedText = '';
  final _transcriptController = TextEditingController();

  // Export dopo sessione completata
  String _lastSavedTranscript = '';

  AppServices get _services => context.read<AppServices>();

  @override
  void initState() {
    super.initState();
    _phase = widget.sessionDone ? _SessionPhase.done : _SessionPhase.idle;

    _services.gps.onSessionUpdate = (session) {
      if (mounted) setState(() => _walkSession = session);
    };
    _services.gps.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    };

    _initSpeech();
  }

  @override
  void didUpdateWidget(_ClaritySessionWidget old) {
    super.didUpdateWidget(old);
    if (widget.sessionDone && !old.sessionDone && _phase == _SessionPhase.idle) {
      setState(() => _phase = _SessionPhase.done);
    }
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speechToText.initialize(
      onStatus: (status) {
        // Riavvia automaticamente dopo silenzio per non interrompere mai la rec
        if (status == 'notListening' && _isRecording && mounted) {
          _restartListening();
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _initPedometer() {
    _stepSub?.cancel();
    try {
      _stepSub = Pedometer.stepCountStream.listen(
        (event) {
          if (!mounted) return;
          if (_stepCountBase == 0) _stepCountBase = event.steps;
          final steps = event.steps - _stepCountBase;
          setState(() => _currentSteps = steps > 0 ? steps : 0);
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  // ── Avvia sessione ────────────────────────────────────────────────────

  Future<void> _startSession() async {
    setState(() => _requestingPermission = true);

    final hasPerm = await _services.gps.requestPermissions(
      backgroundRequired: _services.isPro,
    );

    setState(() => _requestingPermission = false);

    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.walkLocationPermissionDeny)),
        );
      }
      return;
    }

    // Pedometro
    _stepCountBase = 0;
    _currentSteps = 0;
    _initPedometer();

    // GPS
    await _services.gps.startWalk();

    // Voce
    _accumulatedText = '';
    _transcriptController.text = '';
    _isRecording = true;
    if (_speechAvailable) await _startListening();

    setState(() => _phase = _SessionPhase.active);

    // Notifica persistente
    await _services.notifications.showWalkOngoing(
      distance: '0.00',
      time: '00:00',
      isPaused: false,
    );

    // Insight popup (una volta sola)
    if (!_insightShown && widget.insightForPopup != null && mounted) {
      _insightShown = true;
      _showInsightPopup(widget.insightForPopup!);
    }
  }

  // ── Speech helpers ────────────────────────────────────────────────────

  Future<void> _startListening() async {
    _accumulatedText = _transcriptController.text.trim();
    await _speechToText.listen(
      onResult: (result) {
        if (!mounted || !_isRecording) return;
        final newPart = result.recognizedWords;
        final sep =
            _accumulatedText.isNotEmpty && newPart.isNotEmpty ? ' ' : '';
        setState(() {
          _transcriptController.text = '$_accumulatedText$sep$newPart';
          _transcriptController.selection = TextSelection.fromPosition(
            TextPosition(offset: _transcriptController.text.length),
          );
        });
      },
      localeId: 'it_IT',
      listenFor: const Duration(minutes: 30),
      pauseFor: const Duration(seconds: 60), // 60s di silenzio tollerati
    );
  }

  Future<void> _restartListening() async {
    if (!_isRecording || !_speechAvailable) return;
    _accumulatedText = _transcriptController.text.trim();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || !_isRecording) return;
    await _startListening();
  }

  // ── Pausa / Riprendi sessione ─────────────────────────────────────────

  Future<void> _pauseSession() async {
    _isRecording = false;
    if (_speechToText.isListening) await _speechToText.stop();
    _services.gps.pauseWalk();
    await _services.notifications.showWalkOngoing(
      distance: _walkSession?.formattedDistance ?? '0.00',
      time: _walkSession?.formattedTimeFull ?? '00:00:00',
      isPaused: true,
    );
    if (mounted) setState(() => _phase = _SessionPhase.paused);
  }

  Future<void> _resumeSession() async {
    _services.gps.resumeWalk();
    _isRecording = true;
    if (_speechAvailable) await _startListening();
    await _services.notifications.showWalkOngoing(
      distance: _walkSession?.formattedDistance ?? '0.00',
      time: _walkSession?.formattedTimeFull ?? '00:00:00',
      isPaused: false,
    );
    if (mounted) setState(() => _phase = _SessionPhase.active);
  }

  // ── Ferma sessione ────────────────────────────────────────────────────

  Future<void> _stopSession() async {
    _isRecording = false;
    if (_speechToText.isListening) _speechToText.stop();
    _stepSub?.cancel();

    final completed = _services.gps.stopWalk();
    await _services.notifications.cancelWalkOngoing();

    if (completed == null) {
      setState(() => _phase = _SessionPhase.idle);
      return;
    }

    final withSteps = completed.copyWith(stepCount: _currentSteps);
    if (!mounted) return;
    _showSummary(withSteps);
  }

  void _showSummary(WalkSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SessionSummarySheet(
        session: session,
        transcript: _transcriptController.text.trim(),
        onSave: () async {
          Navigator.pop(ctx);
          await _saveSession(session);
        },
        onDiscard: () {
          Navigator.pop(ctx);
          setState(() {
            _phase = _SessionPhase.idle;
            _walkSession = null;
            _currentSteps = 0;
            _stepCountBase = 0;
            _transcriptController.text = '';
            _accumulatedText = '';
          });
        },
      ),
    );
  }

  Future<void> _saveSession(WalkSession session) async {
    final today = DateTime.now();
    await _services.db.saveWalkSession(session, today);

    final transcript = _transcriptController.text.trim();
    if (transcript.isNotEmpty) {
      await _services.db.saveBrainstormNote(today, transcript);
      final minutes = session.activeMinutes.clamp(1, 60);
      await _services.db.addBrainstormMinutes(today, minutes);
    }

    final dayData = await _services.db.loadDayData(today);
    final newBadges = await _services.badges.onWalkCompleted(
      walkMinutes: session.activeMinutes,
      isPro: _services.isPro,
      dayData: dayData,
    );

    if (_services.isPro) {
      final profile = await _services.db.loadUserProfile();
      await _services.health.syncWalkSession(
        session,
        weightKg: profile?.effectiveWeightKg ?? 65,
      );
    }

    setState(() {
      _lastSavedTranscript = transcript;
      _walkSession = null;
      _currentSteps = 0;
      _stepCountBase = 0;
      _transcriptController.text = '';
      _accumulatedText = '';
      _phase = _SessionPhase.done;
    });

    widget.onSessionComplete();

    if (newBadges.isNotEmpty && mounted) {
      for (final badge in newBadges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Traguardo: ${badge.name}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  // ── Insight popup ─────────────────────────────────────────────────────

  void _showInsightPopup(DailyInsight insight) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Il tuo insight di oggi',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                insight.insight,
                style:
                    Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
              if (insight.walkTip != null && insight.walkTip!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    insight.walkTip!,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: AppColors.cyan,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Inizia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _speechToText.cancel();
    _transcriptController.dispose();
    _services.gps.onSessionUpdate = null;
    _services.gps.onError = null;
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _SessionPhase.idle:
        return _buildSessionCard(context);
      case _SessionPhase.active:
        return _buildSessionCard(context);
      case _SessionPhase.paused:
        return _buildSessionCard(context);
      case _SessionPhase.done:
        return _buildDone(context);
    }
  }

  // ── Session Card: 3 anelli + bottoni dinamici ────────────────────────

  Widget _buildSessionCard(BuildContext context) {
    final session = _walkSession;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stepGoal = widget.userProfile?.stepGoal ?? 8000;
    final walkGoal = (widget.userProfile?.walkMinutesGoal ?? 30).toDouble();
    final brainGoal = (widget.userProfile?.brainstormMinutesGoal ?? 10).toDouble();

    // Dati passi: durante sessione usa _currentSteps, altrimenti dayData
    final stepsDisplay = _phase == _SessionPhase.idle
        ? (widget.initialDayData?.walk?.stepCount ?? 0)
        : _currentSteps;
    final stepsProgress = (stepsDisplay / stepGoal).clamp(0.0, 1.0);
    final walkMin = session?.activeMinutes.toDouble() ?? 0.0;
    final walkProgress = (walkMin / walkGoal).clamp(0.0, 1.0);
    final brainProgress = (walkMin / brainGoal).clamp(0.0, 1.0); // stesso timer

    final statusColor = _phase == _SessionPhase.active
        ? AppColors.success
        : _phase == _SessionPhase.paused
            ? AppColors.warning
            : AppColors.cyan.withOpacity(0.4);
    final statusLabel = _phase == _SessionPhase.active
        ? 'IN SESSIONE'
        : _phase == _SessionPhase.paused
            ? 'IN PAUSA'
            : 'WALKING BRAIN';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A1830), const Color(0xFF0D1E3A)]
              : [AppColors.cyan.withOpacity(0.04), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _phase == _SessionPhase.idle
              ? AppColors.cyan.withOpacity(0.2)
              : AppColors.cyan.withOpacity(0.4),
        ),
        boxShadow: _phase != _SessionPhase.idle
            ? [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        children: [
          // ── Header status row ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              if (_phase == _SessionPhase.active && _speechAvailable)
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isRecording ? AppColors.error : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isRecording ? '● REC' : 'MIC OFF',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _isRecording ? AppColors.error : Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── 3 anelli concentrici ───────────────────────────────────
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _ThreeRingPainter(
                    stepsProgress: stepsProgress,
                    brainProgress: brainProgress,
                    walkProgress: walkProgress,
                  ),
                ),
                // Centro anelli: contenuto fase
                _buildRingCenter(context, session, stepsDisplay),
              ],
            ),
          ),

          // ── Legenda anelli ─────────────────────────────────────────
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RingLegend(color: const Color(0xFF9C27B0), label: 'Passi'),
              const SizedBox(width: 16),
              _RingLegend(color: AppColors.cyan, label: 'Brainstorm'),
              const SizedBox(width: 16),
              _RingLegend(color: const Color(0xFF4CAF50), label: 'Cammino'),
            ],
          ),

          // ── Trascrizione live (solo active) ───────────────────────
          if (_phase == _SessionPhase.active && _speechAvailable) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 60, maxHeight: 120),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isRecording
                      ? AppColors.error.withOpacity(0.35)
                      : AppColors.cyan.withOpacity(0.15),
                ),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: _transcriptController.text.isEmpty
                    ? Text(
                        'Sto ascoltando...',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black26,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        _transcriptController.text,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Bottoni dinamici ───────────────────────────────────────
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildRingCenter(
      BuildContext context, WalkSession? session, int stepsDisplay) {
    switch (_phase) {
      case _SessionPhase.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIcons.personSimpleWalk(PhosphorIconsStyle.fill),
              size: 36,
              color: AppColors.cyan.withOpacity(0.7),
            ),
            const SizedBox(height: 6),
            Text(
              '$stepsDisplay',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.cyan,
                height: 1.0,
                letterSpacing: -1,
              ),
            ),
            const Text(
              'passi',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.cyan,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case _SessionPhase.active:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              session?.formattedTimeFull ?? '00:00:00',
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.cyan,
                height: 1.0,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$stepsDisplay passi',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.cyan.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${session?.formattedDistance ?? '0.00'} km',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.cyan.withOpacity(0.5),
              ),
            ),
          ],
        );
      case _SessionPhase.paused:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIcons.pause(PhosphorIconsStyle.fill),
              size: 32,
              color: AppColors.warning,
            ),
            const SizedBox(height: 6),
            Text(
              session?.formattedTimeFull ?? '00:00:00',
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$stepsDisplay passi',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.warning.withOpacity(0.7),
              ),
            ),
          ],
        );
      case _SessionPhase.done:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (_phase) {
      case _SessionPhase.idle:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _requestingPermission ? null : _startSession,
            icon: _requestingPermission
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : PhosphorIcon(
                    PhosphorIcons.play(PhosphorIconsStyle.fill),
                    size: 18,
                    color: const Color(0xFF0A1128),
                  ),
            label: Text(
              _requestingPermission ? 'Attendere…' : 'Inizia WalkingBrain',
              style: const TextStyle(
                color: Color(0xFF0A1128),
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      case _SessionPhase.active:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pauseSession,
            icon: PhosphorIcon(
              PhosphorIcons.pause(PhosphorIconsStyle.fill),
              size: 18,
              color: Colors.white,
            ),
            label: const Text(
              'Interrompi sessione',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      case _SessionPhase.paused:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resumeSession,
                icon: PhosphorIcon(
                  PhosphorIcons.play(PhosphorIconsStyle.fill),
                  size: 16,
                  color: const Color(0xFF0A1128),
                ),
                label: const Text(
                  'Riprendi',
                  style: TextStyle(
                    color: Color(0xFF0A1128),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _stopSession,
                icon: PhosphorIcon(
                  PhosphorIcons.stop(PhosphorIconsStyle.fill),
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Termina',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        );
      case _SessionPhase.done:
        return const SizedBox.shrink();
    }
  }

  // ── Done: card completamento + esporta ────────────────────────────────

  Widget _buildDone(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    color: AppColors.cyan,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sessione completata oggi',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ottimo lavoro. Torna domani per il prossimo passo.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_lastSavedTranscript.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _exportBrainstorm(context),
              icon: PhosphorIcon(
                PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                size: 18,
                color: isDark ? const Color(0xFF0A1128) : Colors.white,
              ),
              label: Text(
                'Esporta Brain-Storming',
                style: TextStyle(
                  color: isDark ? const Color(0xFF0A1128) : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.cyanLight : AppColors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _exportBrainstorm(BuildContext context) async {
    final text = '''
🧠 Brain-Storming MindStep — ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

$_lastSavedTranscript

---
Inviato dall'app MindStep. Puoi analizzare queste idee e aiutarmi a organizzarle?
''';
    try {
      await Share.share(text, subject: 'Brain-Storming MindStep');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore export: $e')),
        );
      }
    }
  }
}

// ── Ring legend item ──────────────────────────────────────────────────────────

class _RingLegend extends StatelessWidget {
  const _RingLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Session Summary Bottom Sheet ──────────────────────────────────────────────

class _SessionSummarySheet extends StatelessWidget {
  const _SessionSummarySheet({
    required this.session,
    required this.transcript,
    required this.onSave,
    required this.onDiscard,
  });

  final WalkSession session;
  final String transcript;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          PhosphorIcon(
            PhosphorIcons.star(PhosphorIconsStyle.fill),
            size: 48,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.walkCompleted,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.walkSummary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              _SummaryStat(
                label: 'Distanza',
                value: '${session.formattedDistance} km',
                icon: PhosphorIcons.mapPin(),
              ),
              _SummaryStat(
                label: 'Tempo',
                value: session.formattedTime,
                icon: PhosphorIcons.timer(),
              ),
              _SummaryStat(
                label: 'Passi',
                value: '${session.stepCount}',
                icon: PhosphorIcons.footprints(),
              ),
              _SummaryStat(
                label: 'Calorie',
                value: '${session.formattedCalories} kcal',
                icon: PhosphorIcons.flame(),
              ),
            ],
          ),

          // Trascrizione preview (se presente)
          if (transcript.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                        size: 14,
                        color: AppColors.cyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Trascrizione vocale',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    transcript.length > 150
                        ? '${transcript.substring(0, 150)}…'
                        : transcript,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDiscard,
                  child: const Text(AppStrings.walkDiscard),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: PhosphorIcon(
                    PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                    size: 18,
                  ),
                  label: const Text(AppStrings.walkSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final PhosphorIconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          PhosphorIcon(icon, size: 20, color: AppColors.cyan),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.cyan,
            ),
            textAlign: TextAlign.center,
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

// ─── Three Ring Painter ───────────────────────────────────────────────────────

class _ThreeRingPainter extends CustomPainter {
  const _ThreeRingPainter({
    required this.stepsProgress,
    required this.brainProgress,
    required this.walkProgress,
  });

  final double stepsProgress;
  final double brainProgress;
  final double walkProgress;

  static const _ringWidth = 14.0;
  static const _gap = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 4;
    final midRadius = outerRadius - _ringWidth - _gap;
    final innerRadius = midRadius - _ringWidth - _gap;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth
      ..strokeCap = StrokeCap.round;

    // ── Outer ring: steps (purple) ──────────────────────────────────
    canvas.drawCircle(
        center,
        outerRadius,
        trackPaint..color = const Color(0xFF9C27B0).withOpacity(0.12));
    if (stepsProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -pi / 2,
        2 * pi * stepsProgress.clamp(0.0, 1.0),
        false,
        progressPaint..color = const Color(0xFF9C27B0),
      );
    }

    // ── Middle ring: brainstorm (cyan) ──────────────────────────────
    canvas.drawCircle(
        center,
        midRadius,
        trackPaint..color = AppColors.cyan.withOpacity(0.12));
    if (brainProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: midRadius),
        -pi / 2,
        2 * pi * brainProgress.clamp(0.0, 1.0),
        false,
        progressPaint..color = AppColors.cyan,
      );
    }

    // ── Inner ring: walk minutes (green) ───────────────────────────
    canvas.drawCircle(
        center,
        innerRadius,
        trackPaint..color = const Color(0xFF4CAF50).withOpacity(0.12));
    if (walkProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        -pi / 2,
        2 * pi * walkProgress.clamp(0.0, 1.0),
        false,
        progressPaint..color = const Color(0xFF4CAF50),
      );
    }
  }

  @override
  bool shouldRepaint(_ThreeRingPainter old) =>
      old.stepsProgress != stepsProgress ||
      old.brainProgress != brainProgress ||
      old.walkProgress != walkProgress;
}

// ─── Weather Badge (top right, animated) ─────────────────────────────────────

class _WeatherBadge extends StatefulWidget {
  const _WeatherBadge({this.weather});
  final WeatherData? weather;

  @override
  State<_WeatherBadge> createState() => _WeatherBadgeState();
}

class _WeatherBadgeState extends State<_WeatherBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _scaleAnim = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.weather;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : AppColors.cyan.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: w != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(w.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        w.tempFormatted,
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                          height: 1.0,
                        ),
                      ),
                      if (w.city.isNotEmpty)
                        Text(
                          w.city,
                          style: TextStyle(
                            color: AppColors.cyan.withOpacity(0.6),
                            fontSize: 9,
                            fontFamily: 'Inter',
                          ),
                        ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌤️', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text(
                    '—',
                    style: TextStyle(
                      color: AppColors.cyan.withOpacity(0.5),
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Music Button ─────────────────────────────────────────────────────────────

class _MusicButton extends StatelessWidget {
  const _MusicButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.url,
  });

  final String label;
  final Color color;
  final PhosphorIconData icon;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              PhosphorIcon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
