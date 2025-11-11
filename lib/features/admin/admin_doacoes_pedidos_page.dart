import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDoacoesPedidosPage extends StatefulWidget {
  const AdminDoacoesPedidosPage({super.key});

  @override
  State<AdminDoacoesPedidosPage> createState() =>
      _AdminDoacoesPedidosPageState();
}

class _AdminDoacoesPedidosPageState extends State<AdminDoacoesPedidosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;
  List<int> _availableYears = [];

  final firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailableYears();
  }

  Future<void> _loadAvailableYears() async {
    final doacoesSnap = await firestore.collection('doacoes').get();
    final pedidosSnap = await firestore.collection('pedidos').get();

    final allDates = [
      ...doacoesSnap.docs.map((d) {
        final data = d.data();
        return data.containsKey('criadoEm')
            ? (data['criadoEm'] as Timestamp?)?.toDate()
            : null;
      }),
      ...pedidosSnap.docs.map((p) {
        final data = p.data();
        return data.containsKey('dataPedido')
            ? (data['dataPedido'] as Timestamp?)?.toDate()
            : null;
      }),
    ].whereType<DateTime>();

    final years = allDates.map((d) => d.year).toSet().toList()..sort();

    if (mounted) {
      setState(() => _availableYears = years);
    }
  }

  bool _filterByDate(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return false;
    final date = timestamp.toDate();
    if (date.year != _selectedYear) return false;
    if (_selectedMonth != null && date.month != _selectedMonth) return false;
    return true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Diálogo de confirmação
  Future<bool> _confirmAction(
    BuildContext context,
    String title,
    String message, {
    bool danger = false,
  }) async {
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doações e Pedidos'),
        // backgroundColor: Colors.blue.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Doações'),
            Tab(text: 'Pedidos'),
          ],
        ),
        actions: [
          if (_availableYears.isNotEmpty)
            DropdownButton<int>(
              value: _selectedYear,
              underline: const SizedBox(),
              dropdownColor: Colors.white,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedYear = value);
                }
              },
              items: _availableYears
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text('$y',
                            style: const TextStyle(color: Colors.black)),
                      ))
                  .toList(),
            ),
          DropdownButton<int?>(
            value: _selectedMonth,
            hint: const Text('Mês', style: TextStyle(color: Colors.white)),
            underline: const SizedBox(),
            dropdownColor: Colors.white,
            onChanged: (value) => setState(() => _selectedMonth = value),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...List.generate(12, (i) {
                final mes = i + 1;
                final nomeMes =
                    DateFormat.MMMM('pt_BR').format(DateTime(0, mes));
                return DropdownMenuItem(value: mes, child: Text(nomeMes));
              }),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDoacoesTab(),
          _buildPedidosTab(),
        ],
      ),
    );
  }

  // Aba de Doações com ações do admin
  Widget _buildDoacoesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('doacoes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final doacoes = snapshot.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data.containsKey('criadoEm') && _filterByDate(data['criadoEm']);
        }).toList();

        if (doacoes.isEmpty) {
          return const Center(child: Text('Nenhuma doação encontrada.'));
        }

        return ListView.builder(
          itemCount: doacoes.length,
          itemBuilder: (context, index) {
            final doc = doacoes[index];
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;

            final titulo = data['titulo'] ?? 'Sem título';
            final descricao = data['descricao'] ?? '';
            final quantidade = data['quantidade'] ?? 0;
            final unidade = data['unidade'] ?? '';
            final ativo = data['ativo'] == true;

            final dataCriado = data['criadoEm'] != null
                ? DateFormat('dd/MM/yyyy')
                    .format((data['criadoEm'] as Timestamp).toDate())
                : 'N/A';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ListTile(
                leading: Icon(
                  Icons.volunteer_activism,
                  color: ativo ? Colors.green : Colors.grey,
                ),
                title: Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Quantidade: $quantidade $unidade\nCriado em: $dataCriado',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'toggle') {
                      final confirm = await _confirmAction(
                        context,
                        ativo ? 'Desativar doação' : 'Ativar doação',
                        'Tem certeza que deseja ${ativo ? 'desativar' : 'ativar'} esta doação?',
                      );
                      if (confirm) {
                        await firestore
                            .collection('doacoes')
                            .doc(id)
                            .update({'ativo': !ativo});
                        _showSnack(
                            'Doação ${ativo ? 'desativada' : 'ativada'} com sucesso.');
                      }
                    } else if (value == 'delete') {
                      final confirm = await _confirmAction(
                        context,
                        'Excluir doação',
                        'Esta ação é permanente. Deseja realmente excluir esta doação?',
                        danger: true,
                      );
                      if (confirm) {
                        await firestore.collection('doacoes').doc(id).delete();
                        _showSnack('Doação excluída.');
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(ativo ? 'Desativar Doação' : 'Ativar Doação'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Excluir Doação')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Aba de Pedidos com ações do admin
  Widget _buildPedidosTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('pedidos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final pedidos = snapshot.data!.docs.where((p) {
          final data = p.data() as Map<String, dynamic>;
          return data.containsKey('dataPedido') &&
              _filterByDate(data['dataPedido']);
        }).toList();

        if (pedidos.isEmpty) {
          return const Center(child: Text('Nenhum pedido encontrado.'));
        }

        return ListView.builder(
          itemCount: pedidos.length,
          itemBuilder: (context, index) {
            final doc = pedidos[index];
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;

            final status = (data['status'] ?? 'Sem status').toString();
            final idOng = data['idOng'] ?? '';

            final dataPedido = data['dataPedido'] != null
                ? DateFormat('dd/MM/yyyy')
                    .format((data['dataPedido'] as Timestamp).toDate())
                : 'N/A';

            String dataEntrega = '';
            if (data.containsKey('dataEntrega') && data['dataEntrega'] != null) {
              dataEntrega = DateFormat('dd/MM/yyyy')
                  .format((data['dataEntrega'] as Timestamp).toDate());
            }

            String dataRecusa = '';
            if (data.containsKey('dataRecusa') && data['dataRecusa'] != null) {
              dataRecusa = DateFormat('dd/MM/yyyy')
                  .format((data['dataRecusa'] as Timestamp).toDate());
            }

            return FutureBuilder<DocumentSnapshot>(
              future: firestore.collection('ongs').doc(idOng).get(),
              builder: (context, ongSnapshot) {
                String nomeOng = 'ONG Desconhecida';
                if (ongSnapshot.hasData && ongSnapshot.data!.exists) {
                  final ongData = ongSnapshot.data!.data();
                  if (ongData is Map<String, dynamic> &&
                      ongData.containsKey('nome')) {
                    nomeOng = ongData['nome'];
                  }
                }

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.inventory, color: Colors.blue),
                    title: Text(
                      'Pedido - $nomeOng',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Status: $status\nData do pedido: $dataPedido',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirm = await _confirmAction(
                            context,
                            'Excluir pedido',
                            'Deseja realmente excluir este pedido? Esta ação não pode ser desfeita.',
                            danger: true,
                          );
                          if (confirm) {
                            await firestore.collection('pedidos').doc(id).delete();
                            _showSnack('Pedido excluído.');
                          }
                        } else {
                          final confirm = await _confirmAction(
                            context,
                            'Alterar status',
                            'Deseja alterar o status do pedido para "$value"?',
                          );
                          if (confirm) {
                            await firestore
                                .collection('pedidos')
                                .doc(id)
                                .update({'status': value});
                            _showSnack('Status atualizado para "$value".');
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                            value: 'Pendente', child: Text('Pendente')),
                        PopupMenuItem(
                            value: 'Concluído', child: Text('Concluído')),
                        PopupMenuItem(
                            value: 'Recusado', child: Text('Recusado')),
                        PopupMenuDivider(),
                        PopupMenuItem(
                            value: 'delete', child: Text('Excluir Pedido')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
