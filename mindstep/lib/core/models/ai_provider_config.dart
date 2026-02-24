import 'package:equatable/equatable.dart';

/// Provider AI supportati con integrazione API reale
enum AiProvider {
  none,       // Nessun AI (solo link browser)
  gemini,     // Google Gemini API (gratuito con quota)
  openai,     // OpenAI ChatGPT API
  claude,     // Anthropic Claude API
  azureOpenai // Azure OpenAI / Copilot
}

class AiProviderConfig extends Equatable {
  const AiProviderConfig({
    required this.provider,
    this.apiKey = '',
    this.azureEndpoint = '',
    this.azureDeployment = '',
    this.isEnabled = false,
    this.lastTestedAt,
    this.isApiKeyValid = false,
  });

  final AiProvider provider;
  final String apiKey;                // Salvato in flutter_secure_storage
  final String azureEndpoint;         // Solo per Azure OpenAI
  final String azureDeployment;       // Solo per Azure OpenAI (es. gpt-4o-mini)
  final bool isEnabled;
  final DateTime? lastTestedAt;
  final bool isApiKeyValid;

  bool get hasValidKey =>
      isEnabled && apiKey.isNotEmpty && isApiKeyValid;

  bool get isConfigured =>
      provider != AiProvider.none && isEnabled;

  String get providerName {
    switch (provider) {
      case AiProvider.none:       return 'Nessuno';
      case AiProvider.gemini:     return 'Google Gemini';
      case AiProvider.openai:     return 'ChatGPT (OpenAI)';
      case AiProvider.claude:     return 'Claude (Anthropic)';
      case AiProvider.azureOpenai: return 'Copilot (Azure)';
    }
  }

  String get providerEmoji {
    switch (provider) {
      case AiProvider.none:       return '❌';
      case AiProvider.gemini:     return '🔵';
      case AiProvider.openai:     return '🟢';
      case AiProvider.claude:     return '🟠';
      case AiProvider.azureOpenai: return '🟣';
    }
  }

  // Color dot for provider (used in place of emoji)
  int get providerColorValue {
    switch (provider) {
      case AiProvider.none:       return 0xFF9E9E9E; // grey
      case AiProvider.gemini:     return 0xFF2196F3; // blue
      case AiProvider.openai:     return 0xFF4CAF50; // green
      case AiProvider.claude:     return 0xFFFF9800; // orange
      case AiProvider.azureOpenai: return 0xFF9C27B0; // purple
    }
  }

  String get apiKeyHint {
    switch (provider) {
      case AiProvider.gemini:
        return 'AIza... (Google AI Studio)';
      case AiProvider.openai:
        return 'sk-... (platform.openai.com)';
      case AiProvider.claude:
        return 'sk-ant-... (console.anthropic.com)';
      case AiProvider.azureOpenai:
        return 'Chiave API Azure';
      default:
        return 'API Key';
    }
  }

  String get keyInstructions {
    switch (provider) {
      case AiProvider.gemini:
        return 'Ottieni gratuitamente su aistudio.google.com → "Get API Key"';
      case AiProvider.openai:
        return 'Ottieni su platform.openai.com → API Keys';
      case AiProvider.claude:
        return 'Ottieni su console.anthropic.com → API Keys';
      case AiProvider.azureOpenai:
        return 'Configura il deployment Azure OpenAI nel portale Azure';
      default:
        return '';
    }
  }

  AiProviderConfig copyWith({
    AiProvider? provider,
    String? apiKey,
    String? azureEndpoint,
    String? azureDeployment,
    bool? isEnabled,
    DateTime? lastTestedAt,
    bool? isApiKeyValid,
  }) {
    return AiProviderConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      azureEndpoint: azureEndpoint ?? this.azureEndpoint,
      azureDeployment: azureDeployment ?? this.azureDeployment,
      isEnabled: isEnabled ?? this.isEnabled,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      isApiKeyValid: isApiKeyValid ?? this.isApiKeyValid,
    );
  }

  /// Serializzazione SENZA apiKey (la chiave è in secure storage)
  Map<String, dynamic> toJson() => {
    'provider': provider.index,
    'azureEndpoint': azureEndpoint,
    'azureDeployment': azureDeployment,
    'isEnabled': isEnabled,
    'lastTestedAt': lastTestedAt?.toIso8601String(),
    'isApiKeyValid': isApiKeyValid,
  };

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) =>
      AiProviderConfig(
        provider: AiProvider.values[json['provider'] as int? ?? 0],
        azureEndpoint: json['azureEndpoint'] as String? ?? '',
        azureDeployment: json['azureDeployment'] as String? ?? '',
        isEnabled: json['isEnabled'] as bool? ?? false,
        lastTestedAt: json['lastTestedAt'] != null
            ? DateTime.parse(json['lastTestedAt'] as String)
            : null,
        isApiKeyValid: json['isApiKeyValid'] as bool? ?? false,
      );

  static const AiProviderConfig none = AiProviderConfig(
    provider: AiProvider.none,
    isEnabled: false,
  );

  @override
  List<Object?> get props =>
      [provider, azureEndpoint, azureDeployment, isEnabled, isApiKeyValid];
}
