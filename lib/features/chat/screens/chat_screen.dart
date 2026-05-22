// lib/features/chat/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/providers/spreadsheet_data_provider.dart';
import '../providers/chat_provider.dart';

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
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    return SafeArea(
      top: false,
      child: Column(
        children: [
          _buildHeader(theme, chatState),
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildWelcomeState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount:
                        chatState.messages.length + (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length &&
                          chatState.isLoading) {
                        return _buildTypingIndicator();
                      }

                      return _buildMessageBubble(
                        chatState.messages[index],
                        theme,
                      );
                    },
                  ),
          ),
          if (chatState.perguntasDisponiveis <= 0) _buildAdBanner(theme),
          _buildInputBar(chatState),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ChatState chatState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: AppColors.chartGradient),
            ),
            child: const Icon(
              Icons.layers_rounded,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistente Fluxia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Online • ${chatState.perguntasDisponiveis} perguntas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${chatState.perguntasDisponiveis}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState(ThemeData theme) {
    final spreadsheetState = ref.read(spreadsheetDataProvider);
    final data = spreadsheetState.activeData;
    final activeSheet = spreadsheetState.spreadsheets.cast<ImportedSpreadsheet?>().firstWhere(
          (sheet) => sheet?.selected == true,
          orElse: () => null,
        );

    final hasData = data != null;

    final suggestions = <String>[
      if (hasData) ...[
        'Qual é o faturamento total da planilha ativa?',
        'Qual é o lucro total e a margem de lucro?',
        'Quantos pedidos completed existem?',
        'Quantas devoluções existem nessa planilha?',
        'Quais são os top 10 produtos mais vendidos?',
        'Quais são os top 10 anúncios mais vendidos?',
        'Me dê um resumo executivo da operação',
      ] else ...[
        'O que você consegue analisar?',
        'Como importar uma planilha XLSX?',
        'Quais KPIs você calcula?',
      ],
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.chartGradient),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 34,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasData
                  ? 'Planilha ativa: ${activeSheet?.name ?? 'Selecionada'}'
                  : AppStrings.chatWelcome,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            const Text(
              'Sugestões de perguntas',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((question) {
                return InkWell(
                  onTap: () {
                    _textController.text = question;
                    _sendMessage();
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      question,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

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
          gradient: isUser
              ? const LinearGradient(colors: AppColors.chartGradient)
              : null,
          color: isUser ? null : AppColors.quaternaria,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          border: isUser ? null : Border.all(color: AppColors.divider),
        ),
        child: Text(
          msg.content,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.quaternaria,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
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
              color: AppColors.ciano,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        children: [
          Text(
            'Você esgotou suas perguntas disponíveis.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(chatProvider.notifier).watchAdForQuestions();
            },
            icon: const Icon(Icons.ondemand_video_rounded, size: 20),
            label: const Text('Assistir vídeo e ganhar perguntas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amarelo,
              foregroundColor: AppColors.principal,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatState chatState) {
    final canSend = !chatState.isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
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
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: canSend
                    ? AppStrings.chatHint
                    : 'Aguarde a resposta da IA...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: canSend
                  ? const LinearGradient(colors: AppColors.chartGradient)
                  : null,
              color: canSend ? null : AppColors.divider,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: canSend ? _sendMessage : null,
              icon: const Icon(Icons.send_rounded),
              color: AppColors.white,
              tooltip: 'Enviar',
            ),
          ),
        ],
      ),
    );
  }
}