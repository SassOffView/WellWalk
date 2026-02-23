import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/ai_provider_config.dart';
import '../../core/services/ai_insight_service.dart';
import '../../shared/widgets/ms_card.dart';

/// Step onboarding 4: scelta del provider AI e inserimento API key.
/// L'utente può saltare questo step — la chiave può essere aggiunta in seguito.
class SetupAiProviderScreen extends StatefulWidget {
  const SetupAiProviderScreen({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.aiService,
  });

  final ValueChanged<AiProviderConfig?> onNext; // null = salta
  final VoidCallback onBack;
  final AiInsightService aiService;

  @override
  State<SetupAiProviderScreen> createState() => _SetupAiProviderScreenState();
}

class _SetupAiProviderScreenState extends State<SetupAiProviderScreen> {
  AiProvider _selectedProvider = AiProvider.none;
  final _apiKeyCtrl = TextEditingController();
  final _azureEndpointCtrl = TextEditingController();
  final _azureDeploymentCtrl = TextEditingController();
  bool _obscureKey = true;
  bool _testing = false;
  AiTestResult? _testResult;

  bool get _showAzureFields => _selectedProvider == AiProvider.azureOpenai;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          Text(
            'Il tuo AI coach',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Collega un AI per ricevere insight personalizzati, '
            'suggerimenti e prompt di brainstorming basati sui tuoi dati.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Selezione provider ────────────────────────────
                  Text('Scegli il tuo AI',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),

                  ...AiProvider.values
                      .where((p) => p != AiProvider.none)
                      .map((p) => _ProviderCard(
                    provider: p,
                    isSelected: _selectedProvider == p,
                    onTap: () {
                      setState(() {
                        _selectedProvider = p;
                        _testResult = null;
                        _apiKeyCtrl.clear();
                      });
                    },
                  )),

                  const SizedBox(height: 20),

                  // ── API Key input ─────────────────────────────────
                  if (_selectedProvider != AiProvider.none) ...[
                    Text('Inserisci la chiave API',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),

                    // Link istruzioni
                    MsCard(
                      color: AppColors.cyan.withOpacity(0.06),
                      borderColor: AppColors.cyan.withOpacity(0.2),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.cyan, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _providerForSelected.keyInstructions,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.cyan),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // API Key field
                    TextField(
                      controller: _apiKeyCtrl,
                      obscureText: _obscureKey,
                      decoration: InputDecoration(
                        hintText: _providerForSelected.apiKeyHint,
                        prefixIcon: const Icon(Icons.key_outlined),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Toggle visibilità
                            IconButton(
                              icon: Icon(_obscureKey
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscureKey = !_obscureKey),
                            ),
                            // Incolla dagli appunti
                            IconButton(
                              icon: const Icon(Icons.content_paste),
                              tooltip: 'Incolla',
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null) {
                                  _apiKeyCtrl.text = data!.text!.trim();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      onChanged: (_) => setState(() => _testResult = null),
                    ),

                    // Azure-specific fields
                    if (_showAzureFields) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _azureEndpointCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Azure Endpoint',
                          hintText: 'https://mio-endpoint.openai.azure.com',
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _azureDeploymentCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome Deployment',
                          hintText: 'gpt-4o-mini',
                          prefixIcon: Icon(Icons.settings_outlined),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Test connection button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _apiKeyCtrl.text.trim().isEmpty || _testing
                            ? null
                            : _testConnection,
                        icon: _testing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.cyan,
                                ),
                              )
                            : const Icon(Icons.wifi_tethering),
                        label: Text(
                          _testing ? 'Test in corso...' : 'Testa connessione',
                        ),
                      ),
                    ),

                    // Test result
                    if (_testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_testResult!.success
                                  ? AppColors.success
                                  : AppColors.error)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_testResult!.success
                                    ? AppColors.success
                                    : AppColors.error)
                                .withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _testResult!.success
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: _testResult!.success
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _testResult!.message,
                                style: TextStyle(
                                  color: _testResult!.success
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Pulsanti
          Column(
            children: [
              // Continua con AI
              if (_selectedProvider != AiProvider.none)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSave ? _saveAndContinue : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Salva e continua',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Salta
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => widget.onNext(null),
                  child: Text(
                    _selectedProvider == AiProvider.none
                        ? 'Salta — configurerò l\'AI dopo'
                        : 'Salta per ora',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  AiProviderConfig get _providerForSelected => AiProviderConfig(
    provider: _selectedProvider,
    azureEndpoint: _azureEndpointCtrl.text.trim(),
    azureDeployment: _azureDeploymentCtrl.text.trim(),
  );

  bool get _canSave {
    if (_selectedProvider == AiProvider.none) return false;
    if (_apiKeyCtrl.text.trim().isEmpty) return false;
    if (_showAzureFields &&
        (_azureEndpointCtrl.text.isEmpty || _azureDeploymentCtrl.text.isEmpty)) {
      return false;
    }
    // Non richiedere test riuscito — l'utente potrebbe voler configurare offline
    return true;
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final config = AiProviderConfig(
      provider: _selectedProvider,
      apiKey: _apiKeyCtrl.text.trim(),
      azureEndpoint: _azureEndpointCtrl.text.trim(),
      azureDeployment: _azureDeploymentCtrl.text.trim(),
    );

    final result = await widget.aiService.testConnection(
      config,
      _apiKeyCtrl.text.trim(),
    );

    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = result;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    final config = AiProviderConfig(
      provider: _selectedProvider,
      azureEndpoint: _azureEndpointCtrl.text.trim(),
      azureDeployment: _azureDeploymentCtrl.text.trim(),
      isEnabled: true,
      isApiKeyValid: _testResult?.success ?? false,
      lastTestedAt: _testResult != null ? DateTime.now() : null,
    );

    await widget.aiService.saveProviderConfig(
      config,
      apiKey: _apiKeyCtrl.text.trim(),
    );

    widget.onNext(config);
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _azureEndpointCtrl.dispose();
    _azureDeploymentCtrl.dispose();
    super.dispose();
  }
}

// ── Provider Card ─────────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.isSelected,
    required this.onTap,
  });

  final AiProvider provider;
  final bool isSelected;
  final VoidCallback onTap;

  String get _description {
    switch (provider) {
      case AiProvider.gemini:
        return 'Gratuito con quota generosa • Ottimo in italiano';
      case AiProvider.openai:
        return 'GPT-4o-mini • Preciso e veloce';
      case AiProvider.claude:
        return 'Claude Haiku • Riflessivo e naturale';
      case AiProvider.azureOpenai:
        return 'Azure OpenAI • Per aziende e privacy avanzata';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = AiProviderConfig(provider: provider);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withOpacity(0.08)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.lightBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(config.providerEmoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.providerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isSelected ? AppColors.cyan : null,
                    ),
                  ),
                  Text(
                    _description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.cyan, size: 22),
          ],
        ),
      ),
    );
  }
}
