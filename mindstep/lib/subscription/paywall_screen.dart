import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../shared/widgets/ms_card.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _annualSelected = true;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyDark, AppColors.navyMid],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Close
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => context.pop(),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.brandGradient,
                          boxShadow: AppColors.cyanGlow,
                        ),
                        child: const Center(
                          child: Text('🌊', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        AppStrings.proTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        AppStrings.proSubtitle,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Feature list
                      ..._features.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.cyan,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                f,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                      const SizedBox(height: 28),

                      // Plan selector
                      Row(
                        children: [
                          Expanded(
                            child: _PlanCard(
                              label: 'Mensile',
                              price: AppStrings.proMonthly,
                              isSelected: !_annualSelected,
                              onTap: () => setState(() => _annualSelected = false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _PlanCard(
                                  label: 'Annuale',
                                  price: AppStrings.proAnnual,
                                  isSelected: _annualSelected,
                                  onTap: () => setState(() => _annualSelected = true),
                                ),
                                Positioned(
                                  top: -10,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      AppStrings.proAnnualSave,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _purchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyan,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Column(
                                  children: [
                                    Text(
                                      AppStrings.proUpgrade,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      _annualSelected
                                          ? AppStrings.proAnnual
                                          : AppStrings.proMonthly,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          AppStrings.proRestore,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Annulla in qualsiasi momento. Nessun impegno.',
                        style: TextStyle(color: Colors.white30, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _features = [
    AppStrings.proFeatureGPS,
    AppStrings.proFeatureVoice,
    AppStrings.proFeatureCloud,
    AppStrings.proFeatureWidget,
    AppStrings.proFeatureHealth,
    AppStrings.proFeatureBadges,
    AppStrings.proFeatureAnalytics,
    AppStrings.proFeatureAI,
    AppStrings.proFeatureExport,
    AppStrings.proFeatureUnlimited,
  ];

  Future<void> _purchase() async {
    setState(() => _loading = true);
    // TODO: Implementare acquisto reale con in_app_purchase
    // Simulazione per sviluppo:
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acquisto completato! Benvenuto in MindStep PRO 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.label,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withOpacity(0.15)
              : AppColors.navyLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.cyan : Colors.white60,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
