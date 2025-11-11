import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOngsPage extends StatefulWidget {
  const AdminOngsPage({super.key});

  @override
  State<AdminOngsPage> createState() => _AdminOngsPageState();
}

class _AdminOngsPageState extends State<AdminOngsPage> {
  final firestore = FirebaseFirestore.instance;
  String filtroCidade = '';
  String filtroStatus = 'todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar ONGs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filtrar por status',
            onSelected: (v) => setState(() => filtroStatus = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'todos', child: Text('Todos')),
              PopupMenuItem(value: 'aprovado', child: Text('Aprovadas')),
              PopupMenuItem(value: 'pendente', child: Text('Pendentes')),
              PopupMenuItem(value: 'suspenso', child: Text('Suspensas')),
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
                hintText: 'Filtrar por cidade...',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => filtroCidade = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('ongs').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ongs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Cidade dentro de 'endereco'
                  final cidade = (data['endereco']?['cidade'] ?? '').toLowerCase();
                  final status = (data['status'] ?? 'pendente').toLowerCase();

                  final matchCidade =
                      filtroCidade.isEmpty || cidade.contains(filtroCidade);
                  final matchStatus =
                      filtroStatus == 'todos' || status == filtroStatus;

                  return matchCidade && matchStatus;
                }).toList();

                if (ongs.isEmpty) {
                  return const Center(
                      child: Text('Nenhuma ONG encontrada com esses filtros.'));
                }

                return ListView.builder(
                  itemCount: ongs.length,
                  itemBuilder: (context, index) {
                    final data = ongs[index].data() as Map<String, dynamic>;
                    final id = ongs[index].id;

                    final nome = data['nome'] ?? 'Sem nome';
                    final cidade =
                        data['endereco']?['cidade'] ?? 'Desconhecida';
                    final email = data['email'] ?? '';
                    final telefone = data['telefone'] ?? '';
                    final status = (data['status'] ?? 'pendente').toLowerCase();

                    Color corStatus;
                    switch (status) {
                      case 'aprovado':
                        corStatus = Colors.green;
                        break;
                      case 'pendente':
                        corStatus = Colors.orange;
                        break;
                      case 'suspenso':
                        corStatus = Colors.red;
                        break;
                      default:
                        corStatus = Colors.grey;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: corStatus.withOpacity(0.15),
                          child: Icon(Icons.handshake, color: corStatus),
                        ),
                        title: Text(
                          nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                            'Cidade: $cidade\nE-mail: $email\nTel: $telefone'),
                        isThreeLine: true,
                        onTap: () => _mostrarDetalhes(context, data),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final confirm = await _confirmAction(
                                context,
                                'Excluir ONG',
                                'Deseja realmente excluir "$nome"? Esta ação é permanente.',
                                danger: true,
                              );
                              if (confirm) {
                                await firestore.collection('ongs').doc(id).delete();
                                _showSnack('ONG "$nome" excluída.');
                              }
                            } else {
                              final confirm = await _confirmAction(
                                context,
                                'Alterar status',
                                'Deseja marcar "$nome" como "$value"?',
                              );
                              if (confirm) {
                                await firestore
                                    .collection('ongs')
                                    .doc(id)
                                    .update({'status': value});
                                _showSnack(
                                    'Status de "$nome" alterado para "$value".');
                              }
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: 'aprovado', child: Text('Aprovar ONG')),
                            PopupMenuItem(
                                value: 'pendente', child: Text('Marcar como pendente')),
                            PopupMenuItem(
                                value: 'suspenso', child: Text('Suspender ONG')),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Excluir ONG',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
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

  // mostra detalhes completos da ONG
  void _mostrarDetalhes(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data['nome'] ?? 'Detalhes da ONG'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Cidade: ${data['endereco']?['cidade'] ?? 'N/A'}'),
            Text('📧 E-mail: ${data['email'] ?? 'N/A'}'),
            Text('📞 Telefone: ${data['telefone'] ?? 'N/A'}'),
            Text('👤 Responsável: ${data['responsavel'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text(
              '🧾 Descrição:\n${data['descricao'] ?? 'Sem descrição disponível.'}',
              style: const TextStyle(fontSize: 13),
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

  // confirmação
  Future<bool> _confirmAction(BuildContext context, String title, String message,
      {bool danger = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(danger ? Icons.warning_amber_rounded : Icons.help_outline,
                    color: danger ? Colors.red : Colors.amber),
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
                    backgroundColor: danger ? Colors.red : Colors.blue),
                child: const Text('Confirmar'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ) ??
        false;
  }

  // feedback visual pós-ação
  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}
