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
    if (state.perguntasDisponiveis <= 0) {
      state = state.copyWith(
        errorMessage: 'Assista a um video para liberar novas perguntas.',
      );
      return;
    }

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

      final planilhasJson = spreadsheetState.spreadsheets.map((sheet) {
        final summary = sheet.summary;
        return {
          'id': sheet.id,
          'nome': sheet.name,
          'selecionada': sheet.selected,
          'mes_referencia': summary.mesReferencia,
          'mes_label': summary.mesReferenciaLabel,
          'data_inicio': summary.dataInicio?.toIso8601String().split('T').first,
          'data_fim': summary.dataFim?.toIso8601String().split('T').first,
          ...summary.toResumoJson(),
        };
      }).toList();

      final resumoJson = {
        'total_planilhas_importadas': spreadsheetState.spreadsheets.length,
        'planilhas_importadas': planilhasJson,
        'consolidado_selecionado': activeData != null
            ? {
                'data_inicio': activeData.dataInicio?.toIso8601String().split('T').first,
                'data_fim': activeData.dataFim?.toIso8601String().split('T').first,
                ...activeData.toResumoJson(),
              }
            : null,
      };

      final ai = FirebaseAI.vertexAI();
      final model = ai.generativeModel(
        model: 'gemini-2.5-flash',
        systemInstruction: Content.system(
          'Você é o Assistente Fluxia, um consultor de e-commerce inteligente integrado ao aplicativo Fluxia. '
          'Seu objetivo é ajudar o usuário a analisar a performance de vendas de sua loja virtual. '
          'Você deve seguir RIGOROSAMENTE as seguintes diretrizes:\n\n'
          '1. IDIOMA E FORMATAÇÃO DE SAÍDA:\n'
          '   - Responda SEMPRE em português brasileiro natural, direto, amigável e profissional.\n'
          '   - Use formatação Markdown (negrito para destacar números, listas se necessário) para tornar a leitura fluida.\n'
          '   - IMPORTANTE: NUNCA responda em formato JSON, bloco de código de programação ou qualquer estrutura puramente técnica (como chaves ou propriedades de objeto). O usuário final deve ler apenas um texto corrido e bem estruturado.\n\n'
          '2. CONTEXTO DE DADOS (JSON DE ENTRADA):\n'
          '   - Você tem acesso aos dados estruturados da loja através do JSON disponibilizado: $resumoJson\n'
          '   - O JSON contém a lista de planilhas importadas ("planilhas_importadas") com seus respectivos nomes, meses, faturamento, lucro e KPIs, e um consolidado dos itens atualmente selecionados pelo usuário ("consolidado_selecionado").\n\n'
          '3. AUTONOMIA PARA CÁLCULOS E INTENÇÃO DO USUÁRIO:\n'
          '   - Se o usuário perguntar pelo faturamento total ou lucro total consolidado, você deve somar os valores de faturamento_total ou lucro_total de todas as planilhas disponíveis em "planilhas_importadas" (ou das que ele mencionar).\n'
          '   - Se o usuário perguntar sobre o faturamento/lucro de uma planilha específica (ex: "faturamento da planilha X"), busque os dados apenas daquela planilha na lista.\n'
          '   - Se perguntado sobre um período, mês ou status de vendas específico, filtre os dados no JSON usando os campos "mes_label", "mes_referencia" ou as estatísticas contidas nos resumos das planilhas.\n'
          '   - Você tem total autonomia para realizar operações matemáticas simples como somar faturamentos, calcular porcentagem de lucro (Lucro Total / Faturamento Total * 100), ou taxa de devoluções (Pedidos Devolvidos / Pedidos Concluídos * 100).\n\n'
          '4. TRATAMENTO DE DADOS FALTANTES:\n'
          '   - Se o usuário fizer uma pergunta complexa para a qual faltem dados (ex: previsão de vendas sem dados de histórico suficientes, ou ticket médio de produtos devolvidos sem valores financeiros específicos de devolução), NUNCA dê uma desculpa genérica ou diga apenas "não consigo responder".\n'
          '   - Explique exatamente quais dados você tem disponíveis e qual dado específico está faltando para realizar aquele cálculo (ex: "Consigo ver que você teve 44 devoluções, mas como não temos o valor financeiro dessas devoluções cadastrado na planilha, não consigo calcular o ticket médio dos produtos devolvidos").'
        ),
      );

      final chat = model.startChat(history: []);
      final response = await chat.sendMessage(Content.text(pergunta));
      final resposta = response.text ?? 'Nao consegui gerar uma resposta.';

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
