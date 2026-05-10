// lib/features/chat/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/admob_service.dart';
import '../providers/chat_provider.dart';

/// Tela do Chat com a IA — estilo minimalista, balões de conversa.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final theme = Theme.of(context);

    // Scroll quando novas mensagens chegam
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.chatTitle,
            style: theme.appBarTheme.titleTextStyle),
        actions: [
          // Contador de perguntas
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${chatState.perguntasDisponiveis}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Lista de mensagens ──
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildWelcomeState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: chatState.messages.length +
                        (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Indicador de "digitando..."
                      if (index == chatState.messages.length &&
                          chatState.isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(
                          chatState.messages[index], theme);
                    },
                  ),
          ),

          // ── Banner de perguntas esgotadas + botão AdMob ──
          if (chatState.perguntasDisponiveis <= 0)
            _buildAdBanner(theme),

          // ── Campo de input ──
          _buildInputBar(chatState, theme),
        ],
      ),
    );
  }

  // ── Welcome / Empty Chat ──
  Widget _buildWelcomeState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.chatWelcome,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Balão de mensagem ──
  Widget _buildMessageBubble(ChatMessage msg, ThemeData theme) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          msg.content,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isUser ? AppColors.white : AppColors.textPrimary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ── Indicador de "digitando..." ──
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.3 + (0.7 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.textHint,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // ── Banner de "assista vídeo para ganhar perguntas" ──
  Widget _buildAdBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.primaryLight,
      child: Column(
        children: [
          Text(
            AppStrings.noQuestionsLeft,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: AdMobService.isAdReady
                ? () => ref.read(chatProvider.notifier).watchAdForQuestions()
                : null,
            icon: const Icon(Icons.play_circle_outline, size: 20),
            label: const Text(AppStrings.watchAdButton),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barra de input inferior ──
  Widget _buildInputBar(ChatState chatState, ThemeData theme) {
    final canSend = chatState.perguntasDisponiveis > 0 && !chatState.isLoading;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: canSend,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => canSend ? _sendMessage() : null,
              maxLines: null,
              decoration: InputDecoration(
                hintText: canSend
                    ? AppStrings.chatHint
                    : 'Assista um vídeo para desbloquear...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: canSend ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: canSend ? _sendMessage : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Icon(
                  Icons.send_rounded,
                  color: canSend ? AppColors.white : AppColors.textHint,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
