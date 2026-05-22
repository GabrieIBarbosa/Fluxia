// lib/core/constants/app_strings.dart

class AppStrings {
  AppStrings._();

  static const String appName = 'Dashboard E-commerce';

  static const String loginTitle = 'Bem-vindo de volta';
  static const String loginSubtitle = 'Faça login para acessar seu dashboard';
  static const String signupTitle = 'Criar conta';
  static const String signupSubtitle = 'Cadastre-se para começar';
  static const String emailHint = 'seu@email.com';
  static const String passwordHint = 'Sua senha';
  static const String loginButton = 'Entrar';
  static const String signupButton = 'Cadastrar';
  static const String switchToSignup = 'Não tem conta? Cadastre-se';
  static const String switchToLogin = 'Já tem conta? Faça login';

  static const String emptyStateTitle =
      'Você ainda não analisou\nnenhuma planilha hoje';
  static const String emptyStateSubtitle =
      'Importe sua planilha XLSX de vendas\ne veja seus resultados em segundos.';
  static const String importButton = 'Importar Planilha';

  static const List<String> loadingMessages = [
    'Lendo arquivo XLSX...',
    'Processando métricas e KPIs...',
    'Salvando resumo no Firebase...',
    'Preparando seu dashboard...',
  ];

  static const String dashboardTitle = 'Seu Dashboard';
  static const String heroMetricLabel = 'Faturamento Total';
  static const String topProductsLabel = 'Top 10 Produtos Mais Vendidos';
  static const String totalOrdersLabel = 'Pedidos Completed';
  static const String avgTicketLabel = 'Ticket Médio';
  static const String newImportButton = 'Nova Importação';

  static const String chatTitle = 'Consultor IA';
  static const String chatHint = 'Faça uma pergunta sobre a planilha ativa...';
  static const String chatWelcome =
      'Olá! Eu sou seu consultor de vendas com IA. '
      'Importe uma planilha XLSX e selecione a planilha ativa para eu analisar seus KPIs.';
  static const String unlockChat = '✨ Desbloquear Chat';
  static const String watchAdButton = 'Assistir vídeo para ganhar 3 perguntas';
  static const String noQuestionsLeft =
      'Você não tem perguntas disponíveis.\nAssista a um vídeo para ganhar mais 3.';
  static const String questionsAvailable = 'perguntas disponíveis';

  static const String errorGeneric = 'Algo deu errado. Tente novamente.';
  static const String errorInvalidSpreadsheet =
      'O arquivo XLSX não possui as colunas esperadas.';
  static const String errorFileTooLarge =
      'Arquivo muito grande. O limite é 8 MB.';
  static const String errorNoFile = 'Nenhum arquivo selecionado.';
  static const String errorAi = 'Erro ao consultar a IA. Tente novamente.';
}