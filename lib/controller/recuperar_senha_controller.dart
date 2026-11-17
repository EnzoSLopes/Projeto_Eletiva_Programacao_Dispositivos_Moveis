import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecuperarSenhaController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> enviarLinkRecuperacao({required String email}) async {
    final emailTrim = email.trim();

    if (emailTrim.isEmpty) {
      throw Exception('Informe o e-mail para recuperar a senha.');
    }

    try {
      notifyListeners();
      await _auth.sendPasswordResetEmail(email: emailTrim);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      throw Exception('Não foi possível enviar o e-mail de recuperação.');
    } finally {
      notifyListeners();
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este e-mail.';
      default:
        return 'Não foi possível recuperar a senha. Tente novamente.';
    }
  }
}
