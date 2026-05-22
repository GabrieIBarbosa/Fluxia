// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_config.dart';
import 'excel_parser_service.dart';

class FirestoreService {
  static final _firestore = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('usuarios').doc(uid);

  static CollectionReference<Map<String, dynamic>> _planilhasCol(String uid) =>
      _userDoc(uid).collection('planilhas');

  static CollectionReference<Map<String, dynamic>> _vendasCol(String uid) =>
      _userDoc(uid).collection('vendas');

  static CollectionReference<Map<String, dynamic>> _chatCol(String uid) =>
      _userDoc(uid).collection('chat_mensagens');

  static Future<void> ensureUserDoc(
    String uid,
    String email, {
    String? nome,
  }) async {
    final trimmedName = nome?.trim();
    final doc = await _userDoc(uid).get();
    if (!doc.exists) {
      await _userDoc(uid).set({
        'email': email,
        if (trimmedName != null && trimmedName.isNotEmpty) 'nome': trimmedName,
        'perguntas_disponiveis': AppConfig.initialFreeQuestions,
        'criado_em': FieldValue.serverTimestamp(),
      });
      return;
    }

    final payload = <String, dynamic>{
      'email': email,
    };
    if (trimmedName != null && trimmedName.isNotEmpty) {
      payload['nome'] = trimmedName;
    }
    await _userDoc(uid).set(payload, SetOptions(merge: true));
  }

  static Future<String?> getUserName(String uid) async {
    final doc = await _userDoc(uid).get();
    final name = doc.data()?['nome']?.toString().trim();
    return name == null || name.isEmpty ? null : name;
  }

  static Future<int> getPerguntasDisponiveis(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return AppConfig.initialFreeQuestions;
    final data = doc.data();
    return (data?['perguntas_disponiveis'] as int?) ??
        AppConfig.initialFreeQuestions;
  }

  static Future<void> addPerguntasAdWatch(String uid) async {
    await _userDoc(uid).update({
      'perguntas_disponiveis':
          FieldValue.increment(AppConfig.questionsPerAdWatch),
    });
  }

  static Future<void> consumirPergunta(String uid) async {
    await _userDoc(uid).update({
      'perguntas_disponiveis': FieldValue.increment(-1),
    });
  }

  static Stream<int> perguntasStream(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return AppConfig.initialFreeQuestions;
      final data = snap.data();
      return (data?['perguntas_disponiveis'] as int?) ??
          AppConfig.initialFreeQuestions;
    });
  }

  static Future<String> saveExcelSummary(
    String uid, {
    required String nome,
    required int tamanho,
    required SpreadsheetAggregatedData summary,
  }) async {
    final payload = {
      'nome': nome,
      'tamanho': tamanho,
      'tipo_arquivo': 'xlsx',
      'processada_em': FieldValue.serverTimestamp(),
      ...summary.toFirestoreMap().map((key, value) {
        if (value is DateTime) {
          return MapEntry(key, Timestamp.fromDate(value));
        }
        return MapEntry(key, value);
      }),
    };

    final doc = await _planilhasCol(uid).add(payload);
    return doc.id;
  }

  static Future<void> updateExcelSummary(
    String uid,
    String planilhaId, {
    required String nome,
    required int tamanho,
    required SpreadsheetAggregatedData summary,
  }) async {
    final payload = {
      'nome': nome,
      'tamanho': tamanho,
      'tipo_arquivo': 'xlsx',
      'processada_em': FieldValue.serverTimestamp(),
      ...summary.toFirestoreMap().map((key, value) {
        if (value is DateTime) {
          return MapEntry(key, Timestamp.fromDate(value));
        }
        return MapEntry(key, value);
      }),
    };

    await _planilhasCol(uid)
        .doc(planilhaId)
        .set(payload, SetOptions(merge: true));
  }

  static Future<void> renamePlanilha(
    String uid,
    String planilhaId,
    String nome,
  ) async {
    await _planilhasCol(uid).doc(planilhaId).set(
      {'nome': nome},
      SetOptions(merge: true),
    );
  }

  static Future<List<Map<String, dynamic>>> getPlanilhas(String uid) async {
    final snapshot = await _planilhasCol(uid)
        .orderBy('processada_em', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static Future<void> deletePlanilha(String uid, String planilhaId) async {
    await _planilhasCol(uid).doc(planilhaId).delete();

    final vendas =
        await _vendasCol(uid).where('planilha_id', isEqualTo: planilhaId).get();

    const chunkSize = 450;
    for (int i = 0; i < vendas.docs.length; i += chunkSize) {
      final batch = _firestore.batch();
      final chunk = vendas.docs.skip(i).take(chunkSize);
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  static Future<void> saveSalesRecords(
    String uid,
    String planilhaId,
    List<SaleRecord> records,
  ) async {
    const chunkSize = 400;
    final mapped = records.map((r) {
      final map = r.toMap();
      return {
        ...map,
        'planilha_id': planilhaId,
        'data_venda':
            r.dataVenda != null ? Timestamp.fromDate(r.dataVenda!) : null,
      };
    }).toList();

    for (int i = 0; i < mapped.length; i += chunkSize) {
      final batch = _firestore.batch();
      final chunk = mapped.sublist(
        i,
        (i + chunkSize > mapped.length) ? mapped.length : i + chunkSize,
      );

      for (final venda in chunk) {
        final ref = _vendasCol(uid).doc();
        batch.set(ref, venda);
      }

      await batch.commit();
    }
  }

  static Future<void> replaceSalesRecords(
    String uid,
    String planilhaId,
    List<SaleRecord> records,
  ) async {
    final old =
        await _vendasCol(uid).where('planilha_id', isEqualTo: planilhaId).get();

    const deleteChunk = 450;
    for (int i = 0; i < old.docs.length; i += deleteChunk) {
      final batch = _firestore.batch();
      final chunk = old.docs.skip(i).take(deleteChunk);
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await saveSalesRecords(uid, planilhaId, records);
  }

  static Future<void> saveChatMessage(
    String uid,
    String role,
    String conteudo,
  ) async {
    await _chatCol(uid).add({
      'role': role,
      'conteudo': conteudo,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> getChatMessagesStream(String uid) {
    return _chatCol(uid)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }
}
