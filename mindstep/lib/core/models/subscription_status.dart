import 'package:equatable/equatable.dart';

enum SubscriptionPlan { free, proMonthly, proAnnual }

class SubscriptionStatus extends Equatable {
  const SubscriptionStatus({
    required this.plan,
    this.expiresAt,
    this.purchasedAt,
    this.isInTrialPeriod = false,
  });

  final SubscriptionPlan plan;
  final DateTime? expiresAt;
  final DateTime? purchasedAt;
  final bool isInTrialPeriod;

  bool get isPro => plan == SubscriptionPlan.proMonthly ||
      plan == SubscriptionPlan.proAnnual;

  bool get isFree => plan == SubscriptionPlan.free;

  bool get isActive {
    if (isFree) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }

  // ── Limiti per tier ─────────────────────────────────────────────────
  int get maxRoutines => isPro ? 999 : 5;
  int get historyDays => isPro ? 999 : 30;
  bool get canUseGPSBackground => isPro;
  bool get canUseVoiceRecording => isPro;
  bool get canUseCloudSync => isPro;
  bool get canUseWidget => isPro;
  bool get canUseHealthConnect => isPro;
  bool get canUseAIIntegration => isPro;
  bool get canExportPDF => isPro;
  bool get canUseMonthlyAnalytics => isPro;
  bool get canUseSmartNotifications => isPro;

  static const SubscriptionStatus freePlan = SubscriptionStatus(
    plan: SubscriptionPlan.free,
  );

  SubscriptionStatus copyWith({
    SubscriptionPlan? plan,
    DateTime? expiresAt,
    DateTime? purchasedAt,
    bool? isInTrialPeriod,
  }) {
    return SubscriptionStatus(
      plan: plan ?? this.plan,
      expiresAt: expiresAt ?? this.expiresAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      isInTrialPeriod: isInTrialPeriod ?? this.isInTrialPeriod,
    );
  }

  Map<String, dynamic> toJson() => {
    'plan': plan.index,
    'expiresAt': expiresAt?.toIso8601String(),
    'purchasedAt': purchasedAt?.toIso8601String(),
    'isInTrialPeriod': isInTrialPeriod,
  };

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      SubscriptionStatus(
        plan: SubscriptionPlan.values[json['plan'] as int],
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        purchasedAt: json['purchasedAt'] != null
            ? DateTime.parse(json['purchasedAt'] as String)
            : null,
        isInTrialPeriod: json['isInTrialPeriod'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [plan, expiresAt, purchasedAt, isInTrialPeriod];
}
