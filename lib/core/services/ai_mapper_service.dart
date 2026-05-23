import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../constants/app_config.dart';

class AiMapperService {
  static Future<Map<String, String>> suggestColumnMapping(
    List<String> rawHeaders,
    List<List<String>> sampleRows,
  ) async {
    final ai = FirebaseAI.vertexAI();
    final model = ai.generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system(
        'Você é um especialista em análise de dados. '
        'Seu objetivo é mapear as colunas de uma planilha genérica de e-commerce (como Nuvemshop, Shopify, Tray, ou outras) '
        'para as colunas padrão do nosso sistema Fluxia. '
        'Nosso sistema espera as seguintes colunas obrigatórias:\n'
        '${AppConfig.requiredSpreadsheetColumns.join(', ')}\n\n'
        'Regras:\n'
        '1. Analise os cabeçalhos originais e os exemplos de dados.\n'
        '2. Tente encontrar a melhor correspondência lógica para cada coluna obrigatória.\n'
        '3. Retorne um JSON estrito onde as chaves são os cabeçalhos ORIGINAIS da planilha genérica e os valores são o nome exato da coluna esperada pelo Fluxia.\n'
        '4. Caso uma coluna original não sirva para nada do sistema, simplesmente não inclua ela no JSON.\n'
        '5. Múltiplos cabeçalhos não podem mapear para o mesmo valor. Cada coluna obrigatória deve aparecer apenas no máximo uma vez nos valores.\n'
        '6. Se alguma coluna obrigatória do sistema não puder ser inferida de forma alguma, tente inferir uma fórmula ou constante se o cabeçalho não existir, mas o ideal é mapear 1 para 1. (Se não tiver mapeamento direto e não puder derivar, não crie chave fantasma, mapeie as colunas existentes para os valores que se encaixam).'
      ),
    );

    final buffer = StringBuffer();
    buffer.writeln('CABEÇALHOS ORIGINAIS:');
    buffer.writeln(rawHeaders.join(' | '));
    buffer.writeln('\nEXEMPLOS DE DADOS:');
    for (var row in sampleRows) {
      buffer.writeln(row.join(' | '));
    }

    try {
      final response = await model.generateContent([Content.text(buffer.toString())]);
      final text = response.text;
      if (text == null || text.isEmpty) return {};

      final Map<String, dynamic> parsed = jsonDecode(text);
      final result = <String, String>{};
      for (final entry in parsed.entries) {
        result[entry.key] = entry.value.toString();
      }
      return result;
    } catch (e) {
      print('Erro ao mapear com IA: \$e');
      return {};
    }
  }
}
