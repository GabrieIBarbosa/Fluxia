// lib/features/auth/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';

/// Estado de autenticação.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
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
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
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
        await FirestoreService.ensureUserDoc(user.uid);
      }
      state = AuthState(status: AuthStatus.authenticated, user: user);
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

  /// Cadastro com email e senha.
  Future<void> signUp(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;
      if (user != null) {
        await FirestoreService.ensureUserDoc(user.uid);
      }
      state = AuthState(status: AuthStatus.authenticated, user: user);
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

  /// Mapeia códigos de erro do Firebase para mensagens amigáveis.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com esse email.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado por outra conta.';
      case 'weak-password':
        return 'A senha precisa ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Email inválido. Verifique e tente novamente.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde e tente novamente.';
      default:
        return 'Erro de autenticação ($code).';
    }
  }
}

/// Provider global de autenticação.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
