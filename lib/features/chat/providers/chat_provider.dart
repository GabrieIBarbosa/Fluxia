// lib/features/chat/providers/chat_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/csv_data_provider.dart';

/// Mensagem individual no chat.
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

/// Estado do chat.
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
      perguntasDisponiveis:
          perguntasDisponiveis ?? this.perguntasDisponiveis,
      errorMessage: errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;

  ChatNotifier(this._ref) : super(const ChatState()) {
    _loadPerguntas();
  }

  /// Carrega a quantidade de perguntas disponíveis do Firestore.
  Future<void> _loadPerguntas() async {
    final uid = _ref.read(authProvider).user?.uid;
    if (uid == null) return;

    final perguntas = await FirestoreService.getPerguntasDisponiveis(uid);
    state = state.copyWith(perguntasDisponiveis: perguntas);
  }

  /// Envia uma pergunta à IA via backend FastAPI.
  Future<void> sendMessage(String pergunta) async {
    if (pergunta.trim().isEmpty) return;

    final uid = _ref.read(authProvider).user?.uid;
    if (uid == null) return;

    // Verifica se tem perguntas disponíveis
    if (state.perguntasDisponiveis <= 0) {
      state = state.copyWith(
        errorMessage: 'Sem perguntas disponíveis. Assista a um vídeo.',
      );
      return;
    }

    // Adiciona mensagem do usuário
    final userMsg = ChatMessage(content: pergunta, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      errorMessage: null,
    );

    try {
      // Obtém resumo JSON dos dados do CSV
      final csvData = _ref.read(csvDataProvider).data;
      if (csvData == null) {
        throw Exception('Nenhum dado CSV carregado.');
      }
      final resumoJson = csvData.toResumoJson();

      // Monta histórico (últimas mensagens com a pergunta atual incluída ao final ou como histórico)
      final List<Content> chatHistory = [];
      for (final m in state.messages.take(10)) {
        if (m.isUser) {
          chatHistory.add(Content.text(m.content));
        } else {
          chatHistory.add(Content.model([TextPart(m.content)]));
        }
      }

      // Chama o Firebase AI
      final ai = FirebaseAI.vertexAI();
      final model = ai.generativeModel(
        model: 'gemini-2.5-flash',
        systemInstruction: Content.system('Você é um assistente de e-commerce. Use estes dados como contexto: $resumoJson'),
      );
      
      final chat = model.startChat(history: chatHistory);
      final response = await chat.sendMessage(Content.text(pergunta));

      final resposta = response.text ?? 'Não consegui gerar uma resposta.';

      // Decrementa 1 pergunta no Firestore
      await FirestoreService.consumirPergunta(uid);

      // Adiciona resposta da IA
      final aiMsg = ChatMessage(content: resposta, isUser: false);
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
        perguntasDisponiveis: state.perguntasDisponiveis - 1,
      );
    } catch (e) {
      // Adiciona mensagem de erro como resposta da IA
      final errorMsg = ChatMessage(
        content: 'Desculpe, ocorreu um erro: ${e.toString().replaceFirst("Exception: ", "")}',
        isUser: false,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
      );
    }
  }

  /// Assiste ao vídeo premiado e ganha perguntas.
  Future<void> watchAdForQuestions() async {
    final uid = _ref.read(authProvider).user?.uid;
    if (uid == null) return;

    await AdMobService.showRewardedAd(
      onReward: () async {
        await FirestoreService.addPerguntasAdWatch(uid);
        final newCount = await FirestoreService.getPerguntasDisponiveis(uid);
        state = state.copyWith(perguntasDisponiveis: newCount);
      },
    );
  }

  /// Recarrega contagem de perguntas (pull to refresh, etc).
  Future<void> refreshPerguntas() async {
    await _loadPerguntas();
  }
}

/// Provider global do chat.
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
