import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDoacoesPedidosPage extends StatefulWidget {
  const AdminDoacoesPedidosPage({super.key});

  @override
  State<AdminDoacoesPedidosPage> createState() =>
      _AdminDoacoesPedidosPageState();
}

class _AdminDoacoesPedidosPageState extends State<AdminDoacoesPedidosPage> {
  final firestore = FirebaseFirestore.instance;

  String _selectedMonth = 'Todos';
  String _selectedYear = 'Todos';
  final _months = const [
    'Todos',
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  late List<String> _years = ['Todos'];

  @override
  void initState() {
    super.initState();
    _loadAvailableYears();
  }

  Future<void> _loadAvailableYears() async {
    final doacoesSnap = await firestore.collection('doacoes').get();
    final pedidosSnap = await firestore.collection('pedidos').get();

    final allDates = [
      ...doacoesSnap.docs
          .map((d) => (d['dataPedido'] as Timestamp?)?.toDate()),
      ...pedidosSnap.docs
          .map((p) => (p['dataPedido'] as Timestamp?)?.toDate()),
    ].whereType<DateTime>();

    final years = allDates.map((d) => d.year.toString()).toSet().toList()
      ..sort();
    setState(() => _years = ['Todos', ...years]);
  }

  bool _filterByDate(Timestamp? dataPedido) {
    if (dataPedido == null) return false;
    final date = dataPedido.toDate();
    final monthName = DateFormat('MMMM', 'pt_BR').format(date);
    final year = date.year.toString();

    final matchMonth = _selectedMonth == 'Todos' ||
        monthName.toLowerCase() == _selectedMonth.toLowerCase();
    final matchYear = _selectedYear == 'Todos' || year == _selectedYear;

    return matchMonth && matchYear;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Doações e Pedidos'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar por data',
              onPressed: () => _showFilterDialog(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.card_giftcard), text: 'Doações'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Pedidos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDoacoesTab(),
            _buildPedidosTab(),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Filtrar por Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                decoration: const InputDecoration(labelText: 'Mês'),
                items: _months
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: const InputDecoration(labelText: 'Ano'),
                items: _years
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedYear = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Limpar'),
              onPressed: () {
                setState(() {
                  _selectedMonth = 'Todos';
                  _selectedYear = 'Todos';
                });
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: const Text('Aplicar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------- DOAÇÕES -----------------------------------

  Widget _buildDoacoesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('doacoes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final doacoes = snapshot.data!.docs.where((d) {
          return _filterByDate(d['dataPedido']);
        }).toList();

        if (doacoes.isEmpty) {
          return const Center(child: Text('Nenhuma doação nesse período.'));
        }

        return ListView.builder(
          itemCount: doacoes.length,
          itemBuilder: (context, index) {
            final d = doacoes[index].data() as Map<String, dynamic>;
            final id = doacoes[index].id;

            final ativo = d['ativo'] == true;
            final titulo = d['titulo'] ?? 'Sem título';
            final quantidade = d['quantidade'] ?? 0;
            final unidade = d['unidade'] ?? '';
            final dataPedido = d['dataPedido'] != null
                ? DateFormat('dd/MM/yyyy')
                    .format((d['dataPedido'] as Timestamp).toDate())
                : 'N/A';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.volunteer_activism,
                    color: ativo ? Colors.green : Colors.grey),
                title: Text(titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Quantidade: $quantidade $unidade\nData: $dataPedido'),
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

  // ----------------------------- PEDIDOS -----------------------------------

  Widget _buildPedidosTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('pedidos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pedidos = snapshot.data!.docs.where((p) {
          return _filterByDate(p['dataPedido']);
        }).toList();

        if (pedidos.isEmpty) {
          return const Center(child: Text('Nenhum pedido nesse período.'));
        }

        return ListView.builder(
          itemCount: pedidos.length,
          itemBuilder: (context, index) {
            final p = pedidos[index].data() as Map<String, dynamic>;
            final id = pedidos[index].id;
            final idOng = p['idOng'] ?? '';
            final status = (p['status'] ?? 'N/A').toString();

            return FutureBuilder<DocumentSnapshot>(
              future: firestore.collection('ongs').doc(idOng).get(),
              builder: (context, ongSnapshot) {
                String nomeOng = 'ONG Desconhecida';
                if (ongSnapshot.hasData && ongSnapshot.data!.exists) {
                  nomeOng = ongSnapshot.data!['nome'] ?? nomeOng;
                }

                final dataPedido = p['dataPedido'] != null
                    ? DateFormat('dd/MM/yyyy')
                        .format((p['dataPedido'] as Timestamp).toDate())
                    : 'N/A';

                Color corStatus;
                switch (status.toLowerCase()) {
                  case 'Pendente':
                    corStatus = Colors.orange;
                    break;
                  case 'em andamento':
                    corStatus = Colors.blueAccent;
                    break;
                  case 'Concluído':
                    corStatus = Colors.green;
                    break;
                  default:
                    corStatus = Colors.grey;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.inventory, color: corStatus),
                    title: Text('Pedido - $nomeOng',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle:
                        Text('Status: $status\nData: $dataPedido'),
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
                        PopupMenuItem(value: 'Pendente', child: Text('Pendente')),
                        // PopupMenuItem(value: 'em andamento', child: Text('Em andamento')),
                        PopupMenuItem(value: 'Concluído', child: Text('Concluído')),
                        PopupMenuItem(value: 'Recusado', child: Text('Recusado')),
                        PopupMenuDivider(),
                        PopupMenuItem(value: 'delete', child: Text('Excluir Pedido')),
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

  // ----------------------------- HELPERS -----------------------------------

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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}
