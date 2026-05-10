# GUIA COMPLETO — E-commerce Dashboard Inteligente (Serverless/Vertex AI) 

## ETAPA 1: O Que Temos Aqui?

Este um projeto puramente Flutter. Você não usará mais Python, VMs (Virtual Machines), Uvicorn e nada de lidar com CORS em FastApi local. Com o pacote **Firebase Vertex AI**, seu aplicativo conversa diretamente com a rede do Google da forma mais rápida, segura e escalável (sendo cobrado — ou saindo grátis na cota livre — 100% pelo Console do Firebase em um só painel).

## ETAPA 2: Instalações que não podem faltar (Máquina do Desenvolvedor)

### 2.1 — O Flutter SDK 
Precisa estar pelo menos no `3.2.0` hoje. Use o **`flutter --version`** e faça seu `flutter doctor`.

### 2.2 — NodeJS e SDK do Firebase
Nós usamos o CLI do Firebase Global. Se não o fez ainda:
1. Instale [NodeJS](https://nodejs.org).
2. Abra o CMD / Terminal do VsCode e digite: `npm install -g firebase-tools`.
3. Verifique com `firebase --version`.

---

## ETAPA 3: Banco de Dados Pessoal, Autenticação e Habilitando "O Cérebro"

Vá no site [console.firebase.google.com](https://console.firebase.google.com).
Logo após criar um nome (como meu-ecommerce-faculdade) você deve abrir no painel na esquerda:

**A.** `Build > Authentication > Setup`: Habilitar de provedores somente Email e Senha.<br>
**B.** `Build > Cloud Firestore Database > Criar Banco`: Pode pular as regras complexas e deixar "Modo Teste" nos primeiros 30 dias.<br>
**C.** `Build > Vertex AI for Firebase (AI Logic)`: Ative por este botão. Eles obrigarão mudar do "Projeto Spark (0$)" pro lado do "Blaze (PAYG)". Apesar do cartão pedido na hora da migração entre planos por políticas do google em algumas regiões de anti-fraude, se limitará a não ser cobrado graças a sua cota vitalicia.

### Rodou e diz que não foi habilitado à Plataforma Agent?
Se surgir um erro na cor vermelha nas chamadas sobre "Developer Console" avisando não achou Agent Plataform API ativada, use sua conta para entrar em [Google Cloud APIs Billing](https://console.developers.google.com/) conforme o link retornado pela string e o ative manualmente no seletor de seu projeto.

---

## ETAPA 4: Amarrando TUDO no Flutter via Flutterfire (Linha de Comando)

Para não ter dores de cabeças com versões nativas ou JSONs no Android, nós deixamos um App puro. 
Com o terminal do editor VS Code rodando dentro da raiz do projeto (`cd ecommerce_app`), faça o procedimento milagroso do CLI listado do passo a passo abaixo:
```
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```
Aperte Enter na pergunta das plataformas ou navegue usando Seta Cima/Baixo marcando Android, IOS ou Web via BARRA DE ESPAÇO.

---

## ETAPA 5: Os Toques Finais dos Sistemas

### Anúncios Google (Rewarded / Monetização)
Caso pretenda colocar o App pra valer no ar, vá nos Constants em \`lib/core/constants/app_config.dart\` e deixe de usar as Ca-app-pub de testes do Admob para usar a do seu espaço particular. (No `AndroidManifest.xml` também).

### Planilha Exemplo
Temos um arquivo na pasta de projeto de excel chamado \`exemplo_vendas.csv\`. Ao compilar para teste o aplicativo pedirá que se alimente a base vazia com esse arquivo. 

---

## PROBLEMAS FREQUENTES (Troubleshooting)

- \`O Emulador não achava banco\` vs \`Agora como achar o Vertex?\`<br>
**R:** Agora ele está no google, use só as requisições normais no terminal: `flutter run`, seu tráfego usará sua rede de Casa/Faculdade acessando a nuvem 100% hospedada. Nada de "localhost:8000" como era configurado antes.
- \`The name FirebaseAI isn't defined\`<br>
**R:** Houve uma atualização dos pacotes e imports? Execute um `flutter clean` seguido de um `flutter pub get` limpo. O firebase options tem todas as credenciais no final.