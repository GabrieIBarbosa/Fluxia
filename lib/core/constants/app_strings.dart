// lib/core/constants/app_strings.dart

/// Textos estáticos usados na interface do aplicativo.
class AppStrings {
  AppStrings._();

  // ── App ──
  static const String appName = 'Dashboard E-commerce';

  // ── Auth ──
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

  // ── Empty State ──
  static const String emptyStateTitle = 'Você ainda não analisou\nnenhuma venda hoje';
  static const String emptyStateSubtitle =
      'Importe sua planilha CSV de vendas\ne veja seus resultados em segundos.';
  static const String importButton = 'Importar Planilha';

  // ── Loading ──
  static const List<String> loadingMessages = [
    'Lendo arquivo...',
    'Cruzando dados...',
    'Preparando seu dashboard...',
  ];

  // ── Dashboard ──
  static const String dashboardTitle = 'Seu Dashboard';
  static const String heroMetricLabel = 'Faturamento do Período';
  static const String salesTrendLabel = 'Vendas por Dia';
  static const String topProductsLabel = 'Top 5 Produtos Mais Vendidos';
  static const String totalOrdersLabel = 'Total de Pedidos';
  static const String avgTicketLabel = 'Ticket Médio';
  static const String newImportButton = 'Nova Importação';

  // ── Chat ──
  static const String chatTitle = 'Consultor IA';
  static const String chatHint = 'Faça uma pergunta sobre seus dados...';
  static const String chatWelcome =
      'Olá! Eu sou seu consultor de vendas com IA. '
      'Faça perguntas sobre os dados do seu CSV e eu vou te ajudar.';
  static const String unlockChat = '✨ Desbloquear Chat';
  static const String watchAdButton = 'Assistir vídeo para ganhar 3 perguntas';
  static const String noQuestionsLeft =
      'Você não tem perguntas disponíveis.\nAssista a um vídeo para ganhar mais 3.';
  static const String questionsAvailable = 'perguntas disponíveis';

  // ── Erros ──
  static const String errorGeneric = 'Algo deu errado. Tente novamente.';
  static const String errorInvalidCsv =
      'O arquivo CSV não possui as colunas esperadas.';
  static const String errorFileTooLarge =
      'Arquivo muito grande. O limite é 2 MB.';
  static const String errorNoFile = 'Nenhum arquivo selecionado.';
  static const String errorAi = 'Erro ao consultar a IA. Tente novamente.';
}
