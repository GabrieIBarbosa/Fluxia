// lib/core/constants/app_config.dart

class AppConfig {
  AppConfig._();

  static const String backendBaseUrl = 'http://10.0.2.2:8000';

  static const int maxFileSizeBytes = 8 * 1024 * 1024;
  static const int questionsPerAdWatch = 3;
  static const int initialFreeQuestions = 3;

  static const String adMobAndroidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String adMobIosRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  static const List<String> requiredSpreadsheetColumns = [
    'Loja',
    'Marketplace',
    'ID Pedido',
    'ID Envio',
    'Data Venda',
    'Status',
    'SKU',
    'Produto',
    'Produtos Individuais',
    'Quantidade',
    'Preco Unit.',
    'Venda Total',
    'Tipo Anuncio',
    'Tipo Entrega',
    'Custo Produto',
    'Comissao MKT',
    'Ads Facil',
    'Custo Frete',
    'Imposto',
    'Embalagem',
    'Custo Total',
    'Lucro R\$',
    'Lucro %',
  ];
}
