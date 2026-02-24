import 'package:flutter/material.dart';
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
  bool _loading = true;
  bool _sessionDone = false;

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

      // Carica insight AI in background (solo per il popup della camminata)
      if (profile != null) {
        _loadInsight(services, profile);
      }
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.cyan,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // ── App Bar ───────────────────────────────────────────────
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
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            PhosphorIcons.waves(PhosphorIconsStyle.fill),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Quote motivazionale (API, fissa) ──────────────────────
              if (_quote != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: MsCard(
                      color: isDark
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

              // ── Walk Widget (insight passato per popup) ───────────────
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
              width: 36, height: 36,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
