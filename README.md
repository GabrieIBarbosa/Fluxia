# E-commerce Dashboard com IA (Flutter + Firebase Vertex AI)

Bem-vindo ao projeto do Dashboard de Vendas com Inteligência Artificial. Este aplicativo permite que os donos de e-commerce carreguem suas planilhas de vendas (CSV) de forma offline com alta performance, visualizem métricas financeiras essenciais e possam "conversar" com uma IA especialista nos dados via Firebase (Gemini).

## Arquitetura Moderna e Sem Servidor (Serverless)

Anteriormente estruturado dependendo de um backend Python FastAPI para processar a IA, agora a aplicação é **100% Serverless no Flutter**.

1. **Inteligência Artificial (Vertex AI do Firebase):** Usando o pacote oficial `firebase_ai`, a comunicação com a IA é feita de forma segura no Firebase, não necessitando expor nenhuma chave secreta de API da OpenAI no código ou hospedar servidores Python.
2. **Processamento Offline RAM:** O pacote CSV processa a inteligência de faturamento, tickets médios e ranking dos produtos em memória local (RAM). Apenas as somas compactas são enviadas à IA para análise. Nenhuma planilha sua será gravada em computadores de terceiros sem permissão.
3. **Controle com Firebase Firestore:** As "fichas/perguntas" dos chats para cada usuário são debitadas sem servidores customizados. Usando o ambiente NoSQL do Cloud Firestore junto às seguranças default Google.
4. **Monetização e Retenção:** Anúncios nativos (AdMob) recarregam as fichas do chat com a IA. Configuração em um único arquivo de constantes e fácil troca na ida a produção.

Consulte o `INSTRUCOES.md` ou `GUIA_COMPLETO.md` neste repositório para conseguir clonar e rodar o projeto na sua hospedagem em até 5 minutos com facilidade!