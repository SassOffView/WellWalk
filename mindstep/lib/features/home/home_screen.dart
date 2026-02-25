import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/daily_insight.dart';
import '../../core/models/day_data.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/quote_service.dart';
import '../../core/services/weather_service.dart';
import '../../shared/widgets/ms_card.dart';
import 'walk/walk_widget.dart';
import 'routine/routine_widget.dart';
import 'brainstorm/brainstorm_widget.dart';

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
                      child: Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.quotes(PhosphorIconsStyle.fill),
                            color: AppColors.cyan,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '"${_quote!.text}"',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '— ${_quote!.author}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                    color: AppColors.cyan,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Passi di oggi (grande, in evidenza) ────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _StepCountCard(
                    steps: _dayData?.walk?.stepCount ?? 0,
                    goal: _profile?.stepGoal ?? 8000,
                  ),
                ),
              ),

              // ── Session Start Card ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SessionStartCard(
                    isDone: _sessionDone,
                    onTap: () async {
                      await context.push('/session');
                      _reload();
                    },
                  ),
                ),
              ),

              // ── Walk Widget ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: WalkWidget(
                    initialDayData: _dayData,
                    onWalkCompleted: _reload,
                    insightForPopup: _insight,
                    userProfile: _profile,
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

              // ── Brainstorm Widget ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: BrainstormWidget(
                    dayData: _dayData,
                    onSaved: _reload,
                    aiPromptOfDay: _insight?.brainstormPrompt,
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

// ─── Step Count Card (grande, in evidenza) ────────────────────────────────────

class _StepCountCard extends StatelessWidget {
  const _StepCountCard({required this.steps, required this.goal});
  final int steps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F1D4A), const Color(0xFF0D1A40)]
              : [AppColors.cyan.withOpacity(0.04), AppColors.cyan.withOpacity(0.01)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$steps',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cyan,
                        fontFamily: 'Inter',
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'passi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cyan.withOpacity(0.7),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.cyan.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$percent% dell\'obiettivo • $goal passi',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Anello circolare compatto
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: _MiniRingPainter(progress: progress),
              child: Center(
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  const _MiniRingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // BG ring
    canvas.drawCircle(center, radius,
        paint..color = AppColors.cyan.withOpacity(0.12));

    if (progress <= 0) return;

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint..color = AppColors.cyan,
    );
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) => old.progress != progress;
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
          border: Border.all(
            color: AppColors.cyan.withOpacity(0.2),
          ),
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

// ─── Session Start Card ───────────────────────────────────────────────────────

class _SessionStartCard extends StatelessWidget {
  const _SessionStartCard({required this.isDone, required this.onTap});
  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return MsCard(
        color: AppColors.cyan.withOpacity(0.07),
        borderColor: AppColors.cyan.withOpacity(0.3),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  color: AppColors.cyan,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Momento completato oggi',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ottimo lavoro. Domani sarà ancora qui per te.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1D4A), Color(0xFF162055)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cyan.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIcons.waves(PhosphorIconsStyle.fill),
              size: 34,
              color: AppColors.cyan,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Il tuo momento di chiarezza',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '60 secondi per te. Anche oggi.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.cyan,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Inizia',
                style: TextStyle(
                  color: Color(0xFF0A1128),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
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
