// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_config.dart';

/// Serviço de leitura/escrita do Firestore.
/// Gerencia o campo `perguntas_disponiveis` por usuário.
class FirestoreService {
  static final _firestore = FirebaseFirestore.instance;

  /// Referência ao documento do usuário na coleção "usuarios".
  static DocumentReference _userDoc(String uid) =>
      _firestore.collection('usuarios').doc(uid);

  /// Garante que o documento do usuário exista.
  /// Se for a primeira vez, cria com [initialFreeQuestions] perguntas.
  static Future<void> ensureUserDoc(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) {
      await _userDoc(uid).set({
        'perguntas_disponiveis': AppConfig.initialFreeQuestions,
        'criado_em': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Retorna o número atual de perguntas disponíveis.
  static Future<int> getPerguntasDisponiveis(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) {
      await ensureUserDoc(uid);
      return AppConfig.initialFreeQuestions;
    }
    final data = doc.data() as Map<String, dynamic>?;
    return (data?['perguntas_disponiveis'] as int?) ??
        AppConfig.initialFreeQuestions;
  }

  /// Adiciona perguntas após o usuário assistir um vídeo de anúncio.
  static Future<void> addPerguntasAdWatch(String uid) async {
    await _userDoc(uid).update({
      'perguntas_disponiveis':
          FieldValue.increment(AppConfig.questionsPerAdWatch),
    });
  }

  /// Decrementa 1 pergunta após o usuário enviar uma pergunta à IA.
  static Future<void> consumirPergunta(String uid) async {
    await _userDoc(uid).update({
      'perguntas_disponiveis': FieldValue.increment(-1),
    });
  }

  /// Escuta mudanças em tempo real no documento do usuário.
  static Stream<int> perguntasStream(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return AppConfig.initialFreeQuestions;
      final data = snap.data() as Map<String, dynamic>?;
      return (data?['perguntas_disponiveis'] as int?) ??
          AppConfig.initialFreeQuestions;
    });
  }
}
