import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final firestore = FirebaseFirestore.instance;
  String searchTerm = '';
  String filtroTipo = 'todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        backgroundColor: Colors.green,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filtrar por tipo de usuário',
            onSelected: (v) => setState(() => filtroTipo = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'todos', child: Text('Todos')),
              // PopupMenuItem(value: 'usuario', child: Text('Usuários')),
              PopupMenuItem(value: 'ong', child: Text('ONGs')),
              PopupMenuItem(value: 'parceiro', child: Text('Parceiros')),
              PopupMenuItem(value: 'admin', child: Text('Administradores')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nome, empresa ou e-mail...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => searchTerm = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('Nenhum usuário encontrado.'));
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome = (data['nome'] ?? '').toLowerCase();
                  final email = (data['email'] ?? '').toLowerCase();
                  final tipo = (data['tipo'] ?? 'usuario').toLowerCase();

                  final matchSearch =
                      nome.contains(searchTerm) || email.contains(searchTerm);
                  final matchTipo =
                      filtroTipo == 'todos' || tipo == filtroTipo;

                  return matchSearch && matchTipo;
                }).toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text('Nenhum usuário encontrado com esse filtro.'),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final data = userDoc.data() as Map<String, dynamic>;
                    final id = userDoc.id;
                    final tipo = (data['tipo'] ?? 'usuario').toLowerCase();
                    final email = data['email'] ?? 'Sem e-mail';

                    return FutureBuilder<String>(
                      future: _getDisplayName(tipo, id, data),
                      builder: (context, snapshot) {
                        final nome = snapshot.data ?? data['nome'] ?? 'Sem nome';

                        Color corTipo;
                        IconData iconeTipo;
                        switch (tipo) {
                          case 'admin':
                            corTipo = Colors.deepPurple;
                            iconeTipo = Icons.verified_user;
                            break;
                          case 'ong':
                            corTipo = Colors.orange;
                            iconeTipo = Icons.volunteer_activism;
                            break;
                          case 'parceiro':
                            corTipo = Colors.green;
                            iconeTipo = Icons.store;
                            break;
                          default:
                            corTipo = Colors.blueAccent;
                            iconeTipo = Icons.person;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: corTipo.withOpacity(0.15),
                              child: Icon(iconeTipo, color: corTipo),
                            ),
                            title: Text(
                              nome,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text('$email\nTipo: ${tipo.toUpperCase()}'),
                            isThreeLine: true,
                            onTap: () => _mostrarDetalhes(userDoc, tipo),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  final confirm = await _confirmAction(
                                    context,
                                    'Excluir usuário',
                                    'Deseja realmente excluir "$nome"? Esta ação é permanente.',
                                    danger: true,
                                  );
                                  if (confirm) {
                                    await firestore
                                        .collection('users')
                                        .doc(id)
                                        .delete();
                                    _showSnack('Usuário "$nome" excluído.');
                                  }
                                } else {
                                  final confirm = await _confirmAction(
                                    context,
                                    'Alterar tipo de usuário',
                                    'Deseja alterar "$nome" para o tipo "$value"?',
                                  );
                                  if (confirm) {
                                    await firestore
                                        .collection('users')
                                        .doc(id)
                                        .update({'tipo': value});
                                    _showSnack(
                                        'Tipo de "$nome" atualizado para "$value".');
                                  }
                                }
                              },
                              itemBuilder: (context) => const [
                                // PopupMenuItem(
                                //     value: 'usuario',
                                //     child: Text('Tornar Usuário')),
                                PopupMenuItem(
                                    value: 'ong', child: Text('Tornar ONG')),
                                PopupMenuItem(
                                    value: 'parceiro',
                                    child: Text('Tornar Parceiro')),
                                PopupMenuItem(
                                    value: 'admin', child: Text('Tornar Admin')),
                                PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Excluir Usuário',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 Nome correto (admin, ong, parceiro)
  Future<String> _getDisplayName(
      String tipo, String userId, Map<String, dynamic> userData) async {
    try {
      if (tipo == 'ong') {
        final ongSnap = await firestore
            .collection('ongs')
            .where('uid', isEqualTo: userId)
            .limit(1)
            .get();
        if (ongSnap.docs.isNotEmpty) {
          return ongSnap.docs.first.data()['nome'] ?? 'ONG sem nome';
        }
      } else if (tipo == 'parceiro') {
        final parceiroSnap = await firestore
            .collection('parceiros')
            .where('uid', isEqualTo: userId)
            .limit(1)
            .get();
        if (parceiroSnap.docs.isNotEmpty) {
          return parceiroSnap.docs.first.data()['empresa'] ?? 'Empresa sem nome';
        }
      } else if (tipo == 'admin') {
        final adminSnap = await firestore
            .collection('admin')
            .where('uid', isEqualTo: userId)
            .limit(1)
            .get();
        if (adminSnap.docs.isNotEmpty) {
          return adminSnap.docs.first.data()['nome'] ?? 'Administrador sem nome';
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar nome relacionado: $e');
    }
    return userData['nome'] ?? 'Sem nome';
  }

  // 📄 Detalhes — agora inclui CPF e corAdmin para admin
  Future<void> _mostrarDetalhes(DocumentSnapshot user, String tipo) async {
    final userData = user.data() as Map<String, dynamic>;
    String nome = userData['nome']?.toString() ?? 'Sem nome';
    String email = userData['email']?.toString() ?? 'Sem e-mail';
    String telefone = userData['telefone']?.toString() ?? 'Não informado';
    String cpf = userData['cpf']?.toString() ?? 'Não informado';
    String corAdmin = userData['corAdmin']?.toString() ?? 'Não definida';
    String cnpj = '';
    String empresa = '';
    String responsavel = '';
    String corOng = '';
    String cidade = '';
    String rua = '';
    String numero = '';
    String uf = '';

    if (tipo == 'admin') {
      final snap = await firestore
          .collection('admin')
          .where('uid', isEqualTo: user.id)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        nome = d['nome']?.toString() ?? nome;
        cpf = d['cpf']?.toString() ?? cpf;
        telefone = d['telefone']?.toString() ?? telefone;
        corAdmin = d['corAdmin']?.toString() ?? corAdmin;
      }
    } else if (tipo == 'ong') {
      final snap = await firestore
          .collection('ongs')
          .where('uid', isEqualTo: user.id)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        nome = d['nome']?.toString() ?? nome;
        cnpj = d['cnpj']?.toString() ?? '';
        responsavel = d['responsavel']?.toString() ?? '';
        corOng = d['corOng']?.toString() ?? '';
        telefone = d['telefone']?.toString() ?? telefone;
        final endereco = d['endereco'] ?? {};
        cidade = endereco['cidade']?.toString() ?? '';
        rua = endereco['rua']?.toString() ?? '';
        numero = endereco['numero']?.toString() ?? '';
        uf = endereco['uf']?.toString() ?? '';
      }
    } else if (tipo == 'parceiro') {
      final snap = await firestore
          .collection('parceiros')
          .where('uid', isEqualTo: user.id)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final d = snap.docs.first.data();
        nome = d['nome']?.toString() ?? nome;
        cnpj = d['cnpj']?.toString() ?? 'CNPJ não informado';
        empresa = d['empresa']?.toString() ?? 'Sem nome da Empresa';
        telefone = d['telefone']?.toString() ?? telefone;
        final endereco = d['endereco'] ?? {};
        cidade = endereco['cidade']?.toString() ?? '';
        rua = endereco['rua']?.toString() ?? '';
        numero = endereco['numero']?.toString() ?? '';
        uf = endereco['uf']?.toString() ?? '';
      }
    }

    // === diálogo dinâmico por tipo ===
    List<Widget> detalhes = [
      Text('Tipo: $tipo'),
      const SizedBox(height: 6),
      Text('E-mail: $email'),
      const SizedBox(height: 6),
      Text('Telefone: $telefone'),
    ];

    if (tipo == 'admin') {
      detalhes.addAll([
        const SizedBox(height: 6),
        Text('CPF: $cpf'),
        const SizedBox(height: 6),
        Text('Cor Admin: $corAdmin'),
      ]);
    } else if (tipo == 'ong') {
      detalhes.addAll([
        const SizedBox(height: 6),
        Text('CNPJ: $cnpj'),
        const SizedBox(height: 6),
        Text('Responsável: $responsavel'),
        const SizedBox(height: 6),
        Text('Cor ONG: $corOng'),
        const SizedBox(height: 6),
        Text('Endereço: $rua, $numero - $cidade/$uf'),
      ]);
    } else if (tipo == 'parceiro') {
      detalhes.addAll([
        const SizedBox(height: 6),
        Text('Empresa: $empresa'),
        const SizedBox(height: 6),
        Text('CNPJ: $cnpj'),
        const SizedBox(height: 6),
        Text('Endereço: $rua, $numero - $cidade/$uf'),
      ]);
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detalhes de $nome'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: detalhes,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // 🔒 Diálogo de confirmação
  Future<bool> _confirmAction(BuildContext context, String title, String message,
      {bool danger = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  danger ? Icons.warning_amber_rounded : Icons.help_outline,
                  color: danger ? Colors.red : Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: danger ? Colors.red : Colors.blue,
                ),
                child: const Text('Confirmar'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ) ??
        false;
  }

  // 💬 Feedback pós-ação
  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}
