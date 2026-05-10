# Instruções para Rodar o Projeto

## Pré-requisitos
- **Flutter SDK** >= 3.2.0 (https://docs.flutter.dev/get-started/install)
- Contas e CLI do **Firebase** configuradas

---

## 1. Configurar o Projeto no Firebase

1. Acesse o [Firebase Console](https://console.firebase.google.com/) e crie um novo projeto.
2. Na aba lateral do console:
   - Ative o **Authentication** apenas com provedor **Email/Senha**.
   - Ative o **Cloud Firestore** em modo Teste.
   - Busque a sessão do **Vertex AI in Firebase** sob o menu 'Build' (ou Criação). Ative o **AI Logic** (Isso poderá exigir o upgrade para o plano Blaze, configurando faturamento - O crédito é gratuito dentro da cota).
3. Habilite pela conta do Google Developer a chave de API Agent e verifique.

---

## 2. Inicializar as Configurações no App (FlutterFire)

No terminal do seu projeto já aberto no VS Code rode os comandos (Garanta ter o NodeJS instalado se não tiver):
```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```
A CLI pedirá qual projeto você quer e montará os arquivos `.json` e `firebase_options.dart` para Android e MacOS/iOS automaticamente.

---

## 3. Rodar e Testar!

1. Na raiz abra um terminal: `flutter pub get`
2. Certifique que o seu emulador ou dispositivo físico está rodando (`flutter devices`)
3. Execute o código de play principal usando `flutter run` ou clique em **F5** no editor. 
   *(PS: Para uso na Web, atente-se se a CLI importou corretamente, com `flutter run -d chrome`).*

---

## Estrutura do App

O projeto foi migrado de "Client-Server" para uma arquitetura "Serverless" em Nuvem do Google:

- `lib/core/services/firestore_service.dart`: Sistema gestor que cuida (sem SQL complexo) dos saldos e perguntas do aplicativo. Salvar em `/usuarios/{uid}`.
- `lib/core/services/csv_parser_service.dart`: Robô veloz de parse do texto extraindo métricas que alimenta as telas usando isolates antes de enviarmos resumos JSON compactos à IA.
- `lib/features/chat/providers/chat_provider.dart`: Instanciação super segura no lado da borda consumindo e provendo a Inteligência baseada nos resultados matemáticos do provider de Dashboard.