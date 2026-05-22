// lib/features/chat/providers/chat_provider.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/spreadsheet_data_provider.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final int perguntasDisponiveis;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.perguntasDisponiveis = 0,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    int? perguntasDisponiveis,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      perguntasDisponiveis: perguntasDisponiveis ?? this.perguntasDisponiveis,
      errorMessage: errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  StreamSubscription? _chatSubscription;
  StreamSubscription? _perguntasSubscription;

  ChatNotifier(this._ref) : super(const ChatState()) {
    _init();

    _ref.listen(authProvider, (previous, next) {
      if (previous?.user?.uid != next.user?.uid) {
        _chatSubscription?.cancel();
        _perguntasSubscription?.cancel();
        state = const ChatState();
        if (next.user != null) {
          _init();
        }
      }
    });
  }

  void _init() {
    final uid = _ref.read(authProvider).user?.uid;
    if (uid == null) return;

    _chatSubscription =
        FirestoreService.getChatMessagesStream(uid).listen((event) {
      final messages = event.map((e) {
        return ChatMessage(
          content: e['conteudo'] ?? '',
          isUser: e['role'] == 'user',
          timestamp: (e['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      state = state.copyWith(messages: messages);
    });

    _perguntasSubscription =
        FirestoreService.perguntasStream(uid).listen((qtd) {
      state = state.copyWith(perguntasDisponiveis: qtd);
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _perguntasSubscription?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(String pergunta) async {
    if (pergunta.trim().isEmpty) return;

    final uid = _ref.read(authProvider).user?.uid;

    if (uid != null) {
      await FirestoreService.saveChatMessage(uid, 'user', pergunta);
      state = state.copyWith(isLoading: true, errorMessage: null);
    } else {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(content: pergunta, isUser: true),
        ],
        isLoading: true,
        errorMessage: null,
      );
    }

    try {
      final spreadsheetState = _ref.read(spreadsheetDataProvider);
      final activeData = spreadsheetState.activeData;
      final selectedSheets = spreadsheetState.spreadsheets
          .where((sheet) => sheet.selected)
          .map((sheet) => sheet.name)
          .toList();
      final activeSheet = spreadsheetState.spreadsheets
          .cast<ImportedSpreadsheet?>()
          .firstWhere((sheet) => sheet?.selected == true, orElse: () => null);

      final resumoJson = activeData != null
          ? {
              ...activeData.toResumoJson(),
              'planilhas_selecionadas': selectedSheets,
              'total_planilhas_importadas':
                  spreadsheetState.spreadsheets.length,
              'total_planilhas_selecionadas': selectedSheets.length,
              'planilha_ativa_id': spreadsheetState.activeSpreadsheetId,
              'planilha_ativa_nome': activeSheet?.name,
              'ha_planilha_ativa': true,
            }
          : {
              'planilhas_selecionadas': selectedSheets,
              'total_planilhas_importadas':
                  spreadsheetState.spreadsheets.length,
              'total_planilhas_selecionadas': selectedSheets.length,
              'planilha_ativa_id': null,
              'planilha_ativa_nome': null,
              'ha_planilha_ativa': false,
            };

      final List<Content> chatHistory = [];
      for (final m in state.messages.take(12)) {
        if (m.isUser) {
          chatHistory.add(Content.text(m.content));
        } else {
          chatHistory.add(Content.model([TextPart(m.content)]));
        }
      }

      final ai = FirebaseAI.vertexAI();
      final model = ai.generativeModel(
        model: 'gemini-2.5-flash',
        systemInstruction: Content.system(
          'Você é um consultor de e-commerce do app Fluxia. '
          'Responda usando apenas os dados da planilha ativa do usuário. '
          'Se não houver planilha ativa, oriente o usuário a importar e selecionar uma planilha XLSX. '
          'Considere os seguintes KPIs pré-processados: pedidos completed, pedidos de devolução, faturamento total, lucro total, lucro percentual, ticket médio, top 10 produtos e top 10 anúncios. '
          'Dados disponíveis agora: $resumoJson',
        ),
      );

      final chat = model.startChat(history: chatHistory);
      final response = await chat.sendMessage(Content.text(pergunta));
      final resposta = response.text ?? 'Não consegui gerar uma resposta.';

      if (uid != null) {
        await FirestoreService.saveChatMessage(uid, 'ia', resposta);
        if (state.perguntasDisponiveis > 0) {
          await FirestoreService.consumirPergunta(uid);
        }
        state = state.copyWith(isLoading: false, errorMessage: null);
      } else {
        state = state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage(content: resposta, isUser: false),
          ],
          isLoading: false,
          perguntasDisponiveis: state.perguntasDisponiveis > 0
              ? state.perguntasDisponiveis - 1
              : 0,
          errorMessage: null,
        );
      }
    } catch (e) {
      final errorMsg =
          'Desculpe, ocorreu um erro na IA: ${e.toString().replaceFirst('Exception: ', '')}';

      if (uid != null) {
        await FirestoreService.saveChatMessage(uid, 'ia', errorMsg);
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
    }
  }

  Future<void> watchAdForQuestions() async {
    final uid = _ref.read(authProvider).user?.uid;
    if (uid == null) return;

    await AdMobService.showRewardedAd(
      onReward: () async {
        await FirestoreService.addPerguntasAdWatch(uid);
      },
    );
  }

  Future<void> refreshPerguntas() async {}
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
