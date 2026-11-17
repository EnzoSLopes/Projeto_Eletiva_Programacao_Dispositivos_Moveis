import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final emailTrim = email.trim();
    final passwordTrim = password.trim();

    if (emailTrim.isEmpty || passwordTrim.isEmpty) {
      throw Exception('Informe o e-mail e a senha para continuar.');
    }

    try {
      notifyListeners();
      return await _auth.signInWithEmailAndPassword(
        email: emailTrim,
        password: passwordTrim,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      throw Exception('Erro ao fazer login. Tente novamente.');
    } finally {
      notifyListeners();
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Este usuário foi desativado.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      default:
        return 'Não foi possível fazer login. Verifique os dados.';
    }
  }
}
