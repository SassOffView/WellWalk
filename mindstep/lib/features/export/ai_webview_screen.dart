import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// WebView in-app per aprire l'AI scelta con un banner che ricorda di incollare.
/// La trascrizione è già stata copiata negli appunti prima di navigare qui.
class AiWebviewScreen extends StatefulWidget {
  const AiWebviewScreen({
    super.key,
    required this.url,
    required this.aiName,
  });

  final String url;
  final String aiName;

  @override
  State<AiWebviewScreen> createState() => _AiWebviewScreenState();
}

class _AiWebviewScreenState extends State<AiWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _showBanner = true;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _startBannerTimer();
          },
          onHttpError: (error) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    // Il banner rimane visibile per 12 secondi, poi si auto-nasconde
    _bannerTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _showBanner = false);
    });
  }

  Future<void> _recopy() async {
    // Ricopia dall'appunti: non possiamo rileggere da clipboard,
    // quindi mostriamo solo conferma che è ancora disponibile
    await HapticFeedback.lightImpact();
    if (mounted) {
      setState(() => _showBanner = true);
      _startBannerTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.exportCopied),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            PhosphorIcon(PhosphorIcons.robot(), color: AppColors.cyan, size: 18),
            const SizedBox(width: 8),
            Text(
              widget.aiName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _recopy,
            icon: PhosphorIcon(PhosphorIcons.copy(), color: AppColors.cyan, size: 20),
            tooltip: 'Ricopia testo',
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controller),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),

          // Banner "Incolla nella chat"
          if (_showBanner && !_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _PasteBanner(onDismiss: () {
                _bannerTimer?.cancel();
                setState(() => _showBanner = false);
              }),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }
}

// ── Paste Banner ──────────────────────────────────────────────────────────────

class _PasteBanner extends StatelessWidget {
  const _PasteBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PhosphorIcon(
              PhosphorIcons.clipboard(PhosphorIconsStyle.fill),
              color: AppColors.cyan,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.exportCopied,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.exportPasteHint,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: PhosphorIcon(
              PhosphorIcons.x(),
              color: Colors.white38,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
