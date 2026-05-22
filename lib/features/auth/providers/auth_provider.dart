// lib/features/auth/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';

/// Estado de autenticação.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? userName;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.userName,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? userName,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      userName: userName ?? this.userName,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final userName = await _loadUserName(user);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          userName: userName,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  /// Login com email e senha.
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;
      if (user != null) {
        await FirestoreService.ensureUserDoc(
          user.uid,
          user.email ?? email.trim(),
          nome: user.displayName,
        );
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        userName: user == null ? null : await _loadUserName(user),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg;

      // Firebase Auth moderno pode retornar 'invalid-credential' tanto para
      // email inexistente quanto para senha errada. Diferenciamos verificando
      // se o email possui algum método de sign-in cadastrado.
      if (e.code == 'invalid-credential' ||
          e.code == 'INVALID_LOGIN_CREDENTIALS') {
        errorMsg = await _resolveLoginError(email.trim());
      } else {
        errorMsg = _mapFirebaseError(e.code);
      }

      state = AuthState(
        status: AuthStatus.error,
        errorMessage: errorMsg,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Erro inesperado: ${e.toString()}',
      );
    }
  }

  /// Verifica se o email existe para diferenciar "email não encontrado"
  /// de "senha incorreta" quando o Firebase retorna um erro genérico.
  /// Usa sendPasswordResetEmail como sonda: se o email não existir,
  /// o Firebase lança 'user-not-found'.
  Future<String> _resolveLoginError(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      // Se chegou aqui, o email existe → a senha está errada
      return 'Senha incorreta. Tente novamente.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Email não encontrado. Verifique ou crie uma conta.';
      }
      // Qualquer outro erro → mensagem genérica
      return 'Email ou senha incorretos. Tente novamente.';
    } catch (_) {
      return 'Email ou senha incorretos. Tente novamente.';
    }
  }

  /// Cadastro com email e senha.
  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final trimmedName = name.trim();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(trimmedName);
        await FirestoreService.ensureUserDoc(
          user.uid,
          user.email ?? email.trim(),
          nome: trimmedName,
        );
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        userName: trimmedName,
      );
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.code),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Erro inesperado: ${e.toString()}',
      );
    }
  }

  /// Logout.
  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Obtém o token Firebase do usuário atual (para enviar ao backend).
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  Future<String?> _loadUserName(User user) async {
    final firestoreName = await FirestoreService.getUserName(user.uid);
    final displayName = user.displayName?.trim();
    if (firestoreName != null) return firestoreName;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return null;
  }

  /// Mapeia códigos de erro do Firebase para mensagens amigáveis.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email não encontrado. Verifique ou crie uma conta.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email ou senha incorretos. Tente novamente.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado por outra conta.';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Email inválido. Verifique e tente novamente.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde e tente novamente.';
      case 'user-disabled':
        return 'Esta conta foi desativada. Entre em contato com o suporte.';
      case 'operation-not-allowed':
        return 'Login com email/senha não está habilitado.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      case 'channel-error':
        return 'Preencha todos os campos antes de continuar.';
      default:
        return 'Erro de autenticação ($code).';
    }
  }
}

/// Provider global de autenticação.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
