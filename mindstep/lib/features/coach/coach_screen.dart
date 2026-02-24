import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/coaching_service.dart';

/// Schermata di coaching conversazionale con il Coach di Chiarezza IA.
/// Accessibile solo con piano PRO.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  List<CoachMessage> _messages = [];

  CoachingService get _coaching => context.read<AppServices>().coaching;

  @override
  void initState() {
    super.initState();
    _coaching.startSession();
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _inputCtrl.clear();
    setState(() {
      _isSending = true;
      _messages = List.from(_coaching.history);
    });

    await _coaching.sendMessage(text);

    if (mounted) {
      setState(() {
        _isSending = false;
        _messages = List.from(_coaching.history);
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Termina sessione'),
        content: const Text(
            'Vuoi terminare la sessione con il coach?\nLa conversazione non verrà salvata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continua'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Termina',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _endSession,
          icon: PhosphorIcon(PhosphorIcons.arrowLeft(), color: Colors.white70),
        ),
        title: Row(
          children: [
            PhosphorIcon(
              PhosphorIcons.chatCircleDots(PhosphorIconsStyle.fill),
              color: AppColors.cyan,
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.coachTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  AppStrings.coachSubtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _endSession,
            child: Text(
              AppStrings.coachEnd,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Divider
          Container(height: 1, color: Colors.white.withOpacity(0.07)),

          // Messaggi
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _messages.length && _isSending) {
                        return const _TypingIndicator();
                      }
                      final msg = _messages[i];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),

          // Input area
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIcons.chatCircleDots(),
            size: 52,
            color: Colors.white12,
          ),
          const SizedBox(height: 20),
          const Text(
            'Inizia a scrivere.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Cosa ti sta occupando la mente in questo momento?',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: AppColors.cyan,
              decoration: InputDecoration(
                hintText: AppStrings.coachInputHint,
                hintStyle:
                    const TextStyle(color: Colors.white24, fontSize: 14),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.cyan.withOpacity(0.4)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending
                    ? AppColors.cyan.withOpacity(0.3)
                    : AppColors.cyan,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : PhosphorIcon(
                        PhosphorIcons.paperPlaneTilt(
                            PhosphorIconsStyle.fill),
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Avatar coach
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.chatCircleDots(PhosphorIconsStyle.fill),
                  color: AppColors.cyan,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.cyan.withOpacity(0.15)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.cyan.withOpacity(0.25)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.white.withOpacity(0.88),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // Avatar utente
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.user(PhosphorIconsStyle.fill),
                  color: AppColors.cyan,
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.chatCircleDots(PhosphorIconsStyle.fill),
                color: AppColors.cyan, size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FadeTransition(
                    opacity: Tween(begin: 0.2, end: 0.9).animate(
                      CurvedAnimation(
                        parent: _ctrl,
                        curve: Interval(i * 0.2, 1.0),
                      ),
                    ),
                    child: Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
