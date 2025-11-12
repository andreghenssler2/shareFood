import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminParceirosPage extends StatefulWidget {
  const AdminParceirosPage({super.key});

  @override
  State<AdminParceirosPage> createState() => _AdminParceirosPageState();
}

class _AdminParceirosPageState extends State<AdminParceirosPage> {
  final firestore = FirebaseFirestore.instance;
  String filtroCidade = '';
  String filtroStatus = 'todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Parceiros',style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 0, 42, 156),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            tooltip: 'Filtrar por status',
            onSelected: (v) => setState(() => filtroStatus = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'todos', child: Text('Todos')),
              PopupMenuItem(value: 'ativo', child: Text('Ativos')),
              PopupMenuItem(value: 'inativo', child: Text('Inativos')),
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
              stream: firestore.collection('parceiros').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final parceiros = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final endereco = data['endereco'] as Map<String, dynamic>? ?? {};
                  final cidade = (endereco['cidade'] ?? '').toLowerCase();
                  final status = (data['status'] ?? 'inativo').toLowerCase();

                  final matchCidade =
                      filtroCidade.isEmpty || cidade.contains(filtroCidade);
                  final matchStatus =
                      filtroStatus == 'todos' || status == filtroStatus;

                  return matchCidade && matchStatus;
                }).toList();

                if (parceiros.isEmpty) {
                  return const Center(
                    child: Text('Nenhum parceiro encontrado com esses filtros.'),
                  );
                }

                return ListView.builder(
                  itemCount: parceiros.length,
                  itemBuilder: (context, index) {
                    final data =
                        parceiros[index].data() as Map<String, dynamic>;
                    final id = parceiros[index].id;

                    final empresa = data['empresa'] ?? 'Sem nome';
                    final email = data['email'] ?? 'Sem e-mail';
                    final telefone = data['telefone'] ?? 'Sem telefone';
                    final status = (data['status'] ?? 'inativo').toLowerCase();

                    final endereco =
                        data['endereco'] as Map<String, dynamic>? ?? {};
                    final cidade = endereco['cidade'] ?? 'Desconhecida';

                    final corStatus =
                        status == 'ativo' ? Colors.green : Colors.redAccent;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: corStatus.withOpacity(0.15),
                          child: Icon(Icons.store, color: corStatus),
                        ),
                        title: Text(
                          empresa,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Cidade: $cidade\nE-mail: $email\nTel: $telefone',
                        ),
                        isThreeLine: true,
                        onTap: () => _mostrarDetalhes(context, data),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final confirm = await _confirmAction(
                                context,
                                'Excluir Parceiro',
                                'Deseja realmente excluir "$empresa"? Esta ação é permanente.',
                                danger: true,
                              );
                              if (confirm) {
                                await firestore
                                    .collection('parceiros')
                                    .doc(id)
                                    .delete();
                                _showSnack('Parceiro "$empresa" excluído.');
                              }
                            } else {
                              final confirm = await _confirmAction(
                                context,
                                'Alterar status',
                                'Deseja marcar "$empresa" como "$value"?',
                              );
                              if (confirm) {
                                await firestore
                                    .collection('parceiros')
                                    .doc(id)
                                    .update({'status': value});
                                _showSnack(
                                    'Status de "$empresa" alterado para "$value".');
                              }
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'ativo', child: Text('Ativar')),
                            PopupMenuItem(
                                value: 'inativo', child: Text('Inativar')),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Excluir Parceiro',
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
            ),
          ),
        ],
      ),
    );
  }

  // Detalhes do parceiro
  void _mostrarDetalhes(BuildContext context, Map<String, dynamic> data) {
    final endereco = data['endereco'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data['empresa'] ?? 'Detalhes do Parceiro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏙️ Cidade: ${endereco['cidade'] ?? 'N/A'}'),
            Text('📧 E-mail: ${data['email'] ?? 'N/A'}'),
            Text('📞 Telefone: ${data['telefone'] ?? 'N/A'}'),
            Text('👤 Responsável: ${endereco['nome'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text('📍 Endereço: ${endereco['rua'] ?? ''}, '
                '${endereco['numero'] ?? ''} - ${endereco['uf'] ?? ''}'),
            const SizedBox(height: 10),
            Text(
              '📅 Atualizado em: ${(data['atualizadoEm'] as Timestamp?) != null ? (data['atualizadoEm'] as Timestamp).toDate().toString().split(" ").first : "N/A"}',
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

  // Diálogo de confirmação
  Future<bool> _confirmAction(BuildContext context, String title, String message,
      {bool danger = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                    danger ? Icons.warning_amber_rounded : Icons.help_outline,
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

  //feedback pós-ação
  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}
