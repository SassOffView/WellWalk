import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/models/user_profile.dart';
import 'setup_goals_screen.dart';

/// Setup finale: solo obiettivi giornalieri.
/// Notifiche → richiedere alla prima apertura Home.
/// AI → già scelto nell'onboarding slide 4.
class SetupExtrasScreen extends StatefulWidget {
  const SetupExtrasScreen({super.key});

  @override
  State<SetupExtrasScreen> createState() => _SetupExtrasScreenState();
}

class _SetupExtrasScreenState extends State<SetupExtrasScreen> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final services = context.read<AppServices>();
    final profile = await services.db.loadUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final services = context.read<AppServices>();
    final profile = _profile;

    if (profile == null) {
      // Fallback: profilo non trovato, vai alla home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SetupGoalsScreen(
      profile: profile,
      onBack: () => context.pop(),
      onDone: (updated) async {
        await services.db.saveUserProfile(updated.copyWith(
          hasCompletedOnboarding: true,
        ));
        if (mounted) context.go('/home');
      },
    );
  }
}
