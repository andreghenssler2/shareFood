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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filtrar por tipo de usuário',
            onSelected: (v) => setState(() => filtroTipo = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'todos', child: Text('Todos')),
              PopupMenuItem(value: 'usuario', child: Text('Usuários')),
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

                    // 🔍 Buscar o nome correto (empresa / ONG)
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
                            onTap: () => _mostrarDetalhes(context, data),
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
                                PopupMenuItem(
                                    value: 'usuario',
                                    child: Text('Tornar Usuário')),
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

  // 🔍 Nome de exibição — usa uid correto e nome das coleções relacionadas
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
      }
    } catch (e) {
      debugPrint('Erro ao buscar nome relacionado: $e');
    }
    return userData['nome'] ?? 'Sem nome';
  }

  // 🔍 Detalhes do usuário
  void _mostrarDetalhes(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data['nome'] ?? 'Detalhes do Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 E-mail: ${data['email'] ?? 'N/A'}'),
            Text('👤 Tipo: ${data['tipo'] ?? 'Usuário'}'),
            Text('📱 Telefone: ${data['telefone'] ?? 'N/A'}'),
            Text('🏙️ Cidade: ${data['cidade'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text(
              '📅 Criado em: ${(data['criadoEm'] as Timestamp?) != null ? (data['criadoEm'] as Timestamp).toDate().toString().split(" ").first : "N/A"}',
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Fechar'),
            onPressed: () => Navigator.pop(ctx),
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
