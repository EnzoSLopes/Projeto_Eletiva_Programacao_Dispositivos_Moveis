import 'package:cloud_firestore/cloud_firestore.dart';

class BuildsController {
  BuildsController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _colecaoDoUsuario(
    String uid,
    String colecao,
  ) {
    return _firestore.collection('usuarios').doc(uid).collection(colecao);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> observarBuilds(String uid) {
    return _colecaoDoUsuario(uid, 'builds').snapshots();
  }

  Future<void> criarBuild({
    required String uid,
    required String nome,
    required String descricao,
    required String finalidade,
    required double orcamento,
    required String observacoes,
  }) async {
    final nomeNormalizado = nome.trim();
    if (nomeNormalizado.isEmpty) {
      throw ArgumentError('Informe um nome para a build.');
    }

    if (finalidade.trim().isEmpty) {
      throw ArgumentError('Informe a finalidade da build.');
    }

    if (!orcamento.isFinite || orcamento <= 0) {
      throw ArgumentError('Informe um orçamento maior que zero.');
    }

    await _colecaoDoUsuario(uid, 'builds').add({
      'nome': nomeNormalizado,
      'descricao': descricao.trim(),
      'finalidade': finalidade.trim(),
      'orcamento': orcamento,
      'observacoes': observacoes.trim(),
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluirBuild({required String uid, required String buildId}) {
    return _colecaoDoUsuario(uid, 'builds').doc(buildId).delete();
  }

  Future<void> excluirComponente({
    required String uid,
    required String componenteId,
  }) {
    return _colecaoDoUsuario(
      uid,
      'componentes',
    ).doc(componenteId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> observarComponentes(String uid) {
    return _colecaoDoUsuario(uid, 'componentes').snapshots();
  }

  Future<void> criarComponente({
    required String uid,
    required String nome,
    required String categoria,
    required String marca,
    required double preco,
  }) async {
    final nomeNormalizado = nome.trim();
    if (nomeNormalizado.isEmpty) {
      throw ArgumentError('Informe um nome para o componente.');
    }
    if (categoria.trim().isEmpty) {
      throw ArgumentError('Informe a categoria do componente.');
    }
    if (!preco.isFinite || preco <= 0) {
      throw ArgumentError('Informe um preço maior que zero.');
    }

    await _colecaoDoUsuario(uid, 'componentes').add({
      'nome': nomeNormalizado,
      'categoria': categoria.trim(),
      'marca': marca.trim(),
      'preco': preco,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }
}
