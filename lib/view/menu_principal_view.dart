import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projeto_eletiva/controller/builds_controller.dart';

class MenuPrincipalView extends StatefulWidget {
  const MenuPrincipalView({super.key});

  @override
  State<MenuPrincipalView> createState() => _MenuPrincipalViewState();
}

class _MenuPrincipalViewState extends State<MenuPrincipalView> {
  final BuildsController _controller = BuildsController();
  final Set<String> _deletingBuildIds = {};
  final Set<String> _deletingComponentIds = {};
  bool _creating = false;
  bool _creatingComponent = false;
  String? _buildsStreamUid;
  String? _componentsStreamUid;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _buildsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _componentsStream;

  Stream<QuerySnapshot<Map<String, dynamic>>> _observarBuilds(String uid) {
    if (_buildsStreamUid != uid || _buildsStream == null) {
      _buildsStreamUid = uid;
      _buildsStream = _controller.observarBuilds(uid);
    }
    return _buildsStream!;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _observarComponentes(String uid) {
    if (_componentsStreamUid != uid || _componentsStream == null) {
      _componentsStreamUid = uid;
      _componentsStream = _controller.observarComponentes(uid);
    }
    return _componentsStream!;
  }

  void _recarregarBuilds(String uid) {
    setState(() {
      _buildsStreamUid = uid;
      _buildsStream = _controller.observarBuilds(uid);
    });
  }

  void _recarregarComponentes(String uid) {
    setState(() {
      _componentsStreamUid = uid;
      _componentsStream = _controller.observarComponentes(uid);
    });
  }

  // Mostra a lista de builds
  Widget _conteudoBuilds(User? usuario) {
    if (usuario == null) {
      return Center(child: Text('Entre na sua conta para ver suas builds.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _observarBuilds(usuario.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErroCarregamento(
            mensagem: _mensagemErro(snapshot.error),
            onTentar: () => _recarregarBuilds(usuario.uid),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final documentos =
            snapshot.data?.docs.toList() ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (documentos.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.desktop_windows_outlined, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma build salva',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }
        documentos.sort(
          (a, b) => _dataCriacao(b.data()).compareTo(_dataCriacao(a.data())),
        );

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: documentos.length,
          separatorBuilder: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Divider(height: 1),
          ),
          itemBuilder: (context, index) {
            final dados = documentos[index].data();
            final nome = dados['nome'] as String? ?? 'Build sem nome';
            final criadaEm = dados['criadoEm'];
            final buildId = documentos[index].id;
            final excluindo = _deletingBuildIds.contains(buildId);
            return _BuildListItem(
              nome: nome,
              data: _formatarData(criadaEm),
              excluindo: excluindo,
              excluirBuild: excluindo
                  ? null
                  : () => _excluirBuild(buildId: buildId, nome: nome),
            );
          },
        );
      },
    );
  }

  Widget _conteudoComponentes(User? usuario) {
    if (usuario == null) {
      return Center(
        child: Text('Entre na sua conta para ver seus componentes.'),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _observarComponentes(usuario.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErroCarregamento(
            mensagem: _mensagemErro(snapshot.error),
            onTentar: () => _recarregarComponentes(usuario.uid),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final documentos =
            snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (documentos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.memory_outlined, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum componente cadastrado',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: documentos.length,
          separatorBuilder: (_, _) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Divider(height: 1),
          ),
          itemBuilder: (context, index) {
            final dados = documentos[index].data();
            final nome = dados['nome'] as String? ?? 'Componente sem nome';
            final componenteId = documentos[index].id;
            final excluindo = _deletingComponentIds.contains(componenteId);
            final preco = dados['preco'];
            final precoFormatado = preco is num
                ? 'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}'
                : 'Preço não informado';
            return ListTile(
              leading: const Icon(Icons.memory_outlined),
              title: Text(nome),
              subtitle: Text(
                '${dados['categoria'] as String? ?? 'Sem categoria'} · '
                '${dados['marca'] as String? ?? 'Sem marca'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(precoFormatado),
                  IconButton(
                    tooltip: 'Excluir componente',
                    onPressed: excluindo
                        ? null
                        : () => _excluirComponente(
                            componenteId: componenteId,
                            nome: nome,
                          ),
                    icon: excluindo
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _mensagemErro(Object? erro) {
    if (erro is FirebaseException) {
      return switch (erro.code) {
        'permission-denied' => 'Sem permissão para ler seus dados. Verifique as regras do Firestore.',
        'unavailable' => 'Sem conexão. Verifique sua internet.',
        _ => 'Não foi possível carregar os dados (${erro.code}).',
      };
    }
    return 'Não foi possível carregar os dados.';
  }

  // Mostra a data de criação da build
  String _formatarData(Object? valor) {
    if (valor is! Timestamp) return 'Criada agora';
    final data = valor.toDate().toLocal();
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return 'Criada em $dia/$mes/${data.year}';
  }

  // Ordena as builds da mais recente para a mais antiga
  DateTime _dataCriacao(Map<String, dynamic> dados) {
    final valor = dados['criadoEm'];
    return valor is Timestamp
        ? valor.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  // Bloco com texto Menu Principal e botão para entrar no perfil
  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.blue],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Menu Principal',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(width: 1),
                          ),
                          child: IconButton.filledTonal(
                            onPressed: () =>
                                Navigator.pushNamed(context, 'perfil'),
                            tooltip: 'Abrir perfil',
                            icon: const Icon(Icons.person_outline),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              fixedSize: const Size.square(48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Seus dados',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade50,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(text: 'Builds'),
                                Tab(text: 'Componentes'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _conteudoBuilds(usuario),
                                  _conteudoComponentes(usuario),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: ElevatedButton.icon(
                            onPressed: _creating ? null : _criarBuild,
                            icon: _creating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: Text(
                              _creating ? 'Salvando...' : 'Nova build',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 2,
                              shadowColor: Colors.blue.shade100,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: OutlinedButton.icon(
                            onPressed: _creatingComponent
                                ? null
                                : _criarComponente,
                            icon: _creatingComponent
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.memory_outlined),
                            label: Text(
                              _creatingComponent
                                  ? 'Salvando...'
                                  : 'Novo componente',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //
  // Ações para criar e excluir builds
  //

  // Criar nova build
  Future<void> _criarBuild() async {
    final dados = await showDialog<NovaBuildDados>(
      context: context,
      builder: (_) => const _NovaBuildDialog(),
    );

    if (dados == null || !mounted) return;

    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      _mostrarMensagem('Entre na sua conta para salvar uma build.');
      return;
    }

    setState(() => _creating = true);
    try {
      await _controller.criarBuild(
        uid: usuario.uid,
        nome: dados.nome,
        descricao: dados.descricao,
        finalidade: dados.finalidade,
        orcamento: dados.orcamento,
        observacoes: dados.observacoes,
      );
      _mostrarMensagem(
        'Build criada com sucesso.',
        backgroundColor: Colors.green,
      );
    } on FirebaseException catch (error) {
      debugPrint('Erro Firestore ${error.code}: ${error.message}');
      final mensagem = switch (error.code) {
        'permission-denied' =>
          'Acesso negado. Publique as regras do Firestore.',
        'failed-precondition' ||
        'not-found' => 'Ative o banco Cloud Firestore no projeto Firebase.',
        'unavailable' => 'Sem conexão com o Firestore. Verifique sua internet.',
        _ =>
          'Erro Firestore (${error.code}): ${error.message ?? 'Tente novamente.'}',
      };
      _mostrarMensagem(mensagem, backgroundColor: Colors.red);
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('Plugin Firestore não carregado: $error\n$stackTrace');
      _mostrarMensagem(
        'O plugin Firestore não foi carregado. Feche e reinicie o app.',
        backgroundColor: Colors.red,
      );
    } catch (error, stackTrace) {
      debugPrint('Erro inesperado ao criar build: $error\n$stackTrace');
      _mostrarMensagem(
        'Falha ao criar build: ${error.runtimeType}. Consulte o console.',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _criarComponente() async {
    final dados = await showDialog<NovoComponenteDados>(
      context: context,
      builder: (_) => const _NovoComponenteDialog(),
    );

    if (dados == null || !mounted) return;

    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      _mostrarMensagem(
        'Entre na sua conta para salvar um componente.',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _creatingComponent = true);
    try {
      await _controller.criarComponente(
        uid: usuario.uid,
        nome: dados.nome,
        categoria: dados.categoria,
        marca: dados.marca,
        preco: dados.preco,
      );
      _mostrarMensagem(
        'Componente criado com sucesso.',
        backgroundColor: Colors.green,
      );
    } on FirebaseException catch (error) {
      debugPrint('Erro Firestore ${error.code}: ${error.message}');
      _mostrarMensagem(_mensagemErro(error), backgroundColor: Colors.red);
    } catch (error, stackTrace) {
      debugPrint('Erro inesperado ao criar componente: $error\n$stackTrace');
      _mostrarMensagem(
        'Falha ao criar componente: ${error.runtimeType}. Consulte o console.',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _creatingComponent = false);
    }
  }

  // Excluir build
  Future<void> _excluirBuild({
    required String buildId,
    required String nome,
  }) async {
    final confirmou =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Excluir build?'),
            content: Text('A build "$nome" será excluída permanentemente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmou || !mounted) return;
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      _mostrarMensagem('Entre na sua conta para excluir uma build.');
      return;
    }

    setState(() => _deletingBuildIds.add(buildId));
    try {
      await _controller.excluirBuild(uid: usuario.uid, buildId: buildId);
      _mostrarMensagem('Build excluída.', backgroundColor: Colors.green);
    } on FirebaseException catch (error) {
      debugPrint('Erro ao excluir build ${error.code}: ${error.message}');
      _mostrarMensagem(
        error.code == 'permission-denied'
            ? 'Acesso negado. Verifique as regras do Firestore.'
            : 'Não foi possível excluir a build. Tente novamente.',
        backgroundColor: Colors.red,
      );
    } catch (error, stackTrace) {
      debugPrint('Erro inesperado ao excluir build: $error\n$stackTrace');
      _mostrarMensagem(
        'Falha ao excluir build: ${error.runtimeType}. Consulte o console.',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _deletingBuildIds.remove(buildId));
    }
  }

  Future<void> _excluirComponente({
    required String componenteId,
    required String nome,
  }) async {
    final confirmou =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Excluir componente?'),
            content: Text(
              'O componente "$nome" será excluído permanentemente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmou || !mounted) return;
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      _mostrarMensagem(
        'Entre na sua conta para excluir um componente.',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _deletingComponentIds.add(componenteId));
    try {
      await _controller.excluirComponente(
        uid: usuario.uid,
        componenteId: componenteId,
      );
      _mostrarMensagem('Componente excluído.', backgroundColor: Colors.green);
    } on FirebaseException catch (error) {
      debugPrint('Erro ao excluir componente ${error.code}: ${error.message}');
      _mostrarMensagem(
        error.code == 'permission-denied'
            ? 'Acesso negado. Verifique as regras do Firestore.'
            : 'Não foi possível excluir o componente. Tente novamente.',
        backgroundColor: Colors.red,
      );
    } catch (error, stackTrace) {
      debugPrint('Erro inesperado ao excluir componente: $error\n$stackTrace');
      _mostrarMensagem(
        'Falha ao excluir componente: ${error.runtimeType}. Consulte o console.',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _deletingComponentIds.remove(componenteId));
    }
  }

  void _mostrarMensagem(String mensagem, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: backgroundColor),
    );
  }
}

class NovaBuildDados {
  const NovaBuildDados({
    required this.nome,
    required this.descricao,
    required this.finalidade,
    required this.orcamento,
    required this.observacoes,
  });

  final String nome;
  final String descricao;
  final String finalidade;
  final double orcamento;
  final String observacoes;
}

class NovoComponenteDados {
  const NovoComponenteDados({
    required this.nome,
    required this.categoria,
    required this.marca,
    required this.preco,
  });

  final String nome;
  final String categoria;
  final String marca;
  final double preco;
}

class _NovaBuildDialog extends StatefulWidget {
  const _NovaBuildDialog();

  @override
  State<_NovaBuildDialog> createState() => _NovaBuildDialogState();
}

// Build na lista com ação para exclusão
class _BuildListItem extends StatelessWidget {
  const _BuildListItem({
    required this.nome,
    required this.data,
    required this.excluindo,
    required this.excluirBuild,
  });

  final String nome;
  final String data;
  final bool excluindo;
  final VoidCallback? excluirBuild;

  // Build na lista com ação para exclusão
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.computer_outlined),
        ),
        title: Text(
          nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(data),
        trailing: IconButton(
          tooltip: 'Excluir build',
          onPressed: excluirBuild,
          icon: excluindo
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          color: Colors.red.shade700,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

class _NovaBuildDialogState extends State<_NovaBuildDialog> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _finalidadeController = TextEditingController();
  final TextEditingController _orcamentoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova build'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(
                  controller: _nomeController,
                  label: 'Nome',
                  validator: _obrigatorio('Informe o nome da build.'),
                ),
                _campo(
                  controller: _descricaoController,
                  label: 'Descrição',
                  maxLines: 2,
                ),
                _campo(
                  controller: _finalidadeController,
                  label: 'Finalidade',
                  hint: 'Ex.: jogos, trabalho ou edição',
                  validator: _obrigatorio('Informe a finalidade da build.'),
                ),
                _campo(
                  controller: _orcamentoController,
                  label: 'Orçamento (R\$)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validarValor,
                ),
                _campo(
                  controller: _observacoesController,
                  label: 'Observações',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _confirmar, child: const Text('Criar')),
      ],
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        autofocus: controller == _nomeController,
        maxLength: controller == _nomeController ? 60 : null,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator,
      ),
    );
  }

  String? Function(String?) _obrigatorio(String mensagem) {
    return (valor) => valor == null || valor.trim().isEmpty ? mensagem : null;
  }

  String? _validarValor(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe o orçamento.';
    }
    final orcamento = double.tryParse(valor.trim().replaceAll(',', '.'));
    if (orcamento == null || !orcamento.isFinite || orcamento <= 0) {
      return 'Informe um valor maior que zero.';
    }
    return null;
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;

    final orcamento = double.parse(
      _orcamentoController.text.trim().replaceAll(',', '.'),
    );
    Navigator.pop(
      context,
      NovaBuildDados(
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim(),
        finalidade: _finalidadeController.text.trim(),
        orcamento: orcamento,
        observacoes: _observacoesController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _finalidadeController.dispose();
    _orcamentoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}

class _NovoComponenteDialog extends StatefulWidget {
  const _NovoComponenteDialog();

  @override
  State<_NovoComponenteDialog> createState() => _NovoComponenteDialogState();
}

class _NovoComponenteDialogState extends State<_NovoComponenteDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo componente'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(_nomeController, 'Nome', obrigatorio: true),
                _campo(_categoriaController, 'Categoria', obrigatorio: true),
                _campo(_marcaController, 'Marca'),
                _campo(
                  _precoController,
                  'Preço (R\$)',
                  obrigatorio: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validarPreco: true,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _confirmar, child: const Text('Salvar')),
      ],
    );
  }

  Widget _campo(
    TextEditingController controller,
    String label, {
    bool obrigatorio = false,
    bool validarPreco = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        autofocus: controller == _nomeController,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: (valor) {
          if (obrigatorio && (valor == null || valor.trim().isEmpty)) {
            return 'Preencha este campo.';
          }
          if (validarPreco) {
            final preco = double.tryParse(valor!.trim().replaceAll(',', '.'));
            if (preco == null || !preco.isFinite || preco <= 0) {
              return 'Informe um preço maior que zero.';
            }
          }
          return null;
        },
      ),
    );
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final preco = double.parse(
      _precoController.text.trim().replaceAll(',', '.'),
    );
    Navigator.pop(
      context,
      NovoComponenteDados(
        nome: _nomeController.text.trim(),
        categoria: _categoriaController.text.trim(),
        marca: _marcaController.text.trim(),
        preco: preco,
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    _marcaController.dispose();
    _precoController.dispose();
    super.dispose();
  }
}

class _ErroCarregamento extends StatelessWidget {
  const _ErroCarregamento({required this.mensagem, required this.onTentar});

  final String mensagem;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onTentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
