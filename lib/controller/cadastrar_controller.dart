import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CadastrarController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String password,
  }) async {
    final nomeTrim = nome.trim();
    final emailTrim = email.trim();
    final telefoneLimpo = telefone.replaceAll(RegExp(r'\D'), '');
    final passwordTrim = password;

    if (nomeTrim.isEmpty ||
        emailTrim.isEmpty ||
        telefoneLimpo.isEmpty ||
        passwordTrim.trim().isEmpty) {
      throw Exception('Preencha todos os campos.');
    }

    if (telefoneLimpo.length < 10 || telefoneLimpo.length > 11) {
      throw Exception('Informe um telefone válido com DDD.');
    }

    if (passwordTrim.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(passwordTrim) ||
        !RegExp(r'\d').hasMatch(passwordTrim)) {
      throw Exception(
        'A senha deve ter pelo menos 8 caracteres, com letras e números.',
      );
    }

    UserCredential? credencial;
    try {
      notifyListeners();
      credencial = await _auth.createUserWithEmailAndPassword(
        email: emailTrim,
        password: passwordTrim,
      );

      final user = credencial.user;
      if (user == null) {
        throw StateError('O Firebase não retornou o usuário criado.');
      }

      await user.updateDisplayName(nomeTrim);
      await _firestore.collection('usuarios').doc(user.uid).set({
        'nome': nomeTrim,
        'email': emailTrim,
        'telefone': telefoneLimpo,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      return credencial;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } on FirebaseException catch (e) {
      try {
        await credencial?.user?.delete();
      } on FirebaseAuthException catch (rollbackError) {
        throw Exception(
          'Não foi possível salvar o perfil (${e.code}) nem remover a conta '
          'criada (${rollbackError.code}).',
        );
      }
      throw Exception('Não foi possível salvar seu perfil (${e.code}).');
    } catch (e) {
      if (credencial != null) {
        await credencial.user?.delete();
      }
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'A senha está muito fraca.';
      default:
        return 'Não foi possível cadastrar o usuário.';
    }
  }
}
