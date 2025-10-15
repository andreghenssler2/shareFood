import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final firestore = FirebaseFirestore.instance;
  Future<Map<String, dynamic>>? reportDataFuture;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    reportDataFuture = _loadReportData();
  }

  Future<Map<String, dynamic>> _loadReportData() async {
    final start = DateTime(selectedYear, selectedMonth, 1);
    final end = DateTime(selectedYear, selectedMonth + 1, 1)
        .subtract(const Duration(seconds: 1));

    final usersSnap = await firestore.collection('users').get();
    final ongsSnap = await firestore.collection('ongs').get();
    final parceirosSnap = await firestore.collection('parceiros').get();

    // 🔹 Doações — busca todos e filtra localmente, aceitando 'dataDoacao' OU 'criadoEm'
    final doacoesSnap = await firestore.collection('doacoes').get();
    final doacoesDocs = doacoesSnap.docs.where((doc) {
      final dataCampo = doc.data()['dataDoacao'] ?? doc.data()['criadoEm'];
      if (dataCampo is! Timestamp) return false;
      final data = dataCampo.toDate();
      return data.isAfter(start) && data.isBefore(end);
    }).toList();

    // 🔹 Pedidos — busca por 'dataPedido' (campo certo) e filtra no intervalo
    final pedidosSnap = await firestore.collection('pedidos').get();
    final pedidosDocs = pedidosSnap.docs.where((doc) {
      final dataCampo = doc.data()['dataPedido'];
      if (dataCampo is! Timestamp) return false;
      final data = dataCampo.toDate();
      return data.isAfter(start) && data.isBefore(end);
    }).toList();

    // 🔸 Doações por dia
    final Map<String, int> doacoesPorDia = {};
    for (var doc in doacoesDocs) {
      final dataCampo = doc.data()['dataDoacao'] ?? doc.data()['criadoEm'];
      final data = (dataCampo as Timestamp).toDate();
      final dia = DateFormat('dd/MM').format(data);
      doacoesPorDia[dia] = (doacoesPorDia[dia] ?? 0) + 1;
    }

    // 🔸 Pedidos por ONG (resolve nome)
    final Map<String, int> pedidosPorOng = {};
    final Map<String, String> nomeCache = {};

    for (var doc in pedidosDocs) {
      final idOng = doc['idOng'];
      if (idOng == null) continue;

      if (!nomeCache.containsKey(idOng)) {
        final ongDoc = await firestore.collection('ongs').doc(idOng).get();
        nomeCache[idOng] = ongDoc.exists
            ? (ongDoc['nome'] ?? 'Sem nome')
            : 'Desconhecida';
      }

      final nomeOng = nomeCache[idOng]!;
      pedidosPorOng[nomeOng] = (pedidosPorOng[nomeOng] ?? 0) + 1;
    }

    return {
      'users': usersSnap.size,
      'ongs': ongsSnap.size,
      'parceiros': parceirosSnap.size,
      'doacoes': doacoesDocs.length,
      'pedidos': pedidosDocs.length,
      'doacoesPorDia': doacoesPorDia,
      'pedidosPorOng': pedidosPorOng,
    };
  }

  Future<void> _showFilterBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filtrar por Mês e Ano',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(12, (i) {
                          final mes = DateFormat.MMMM('pt_BR')
                              .format(DateTime(0, i + 1));
                          return DropdownMenuItem(
                            value: i + 1,
                            child: Text(mes.toUpperCase()),
                          );
                        }),
                        onChanged: (value) =>
                            setSheetState(() => selectedMonth = value!),
                      ),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: List.generate(5, (i) {
                          final ano = DateTime.now().year - i;
                          return DropdownMenuItem(
                            value: ano,
                            child: Text(ano.toString()),
                          );
                        }),
                        onChanged: (value) =>
                            setSheetState(() => selectedYear = value!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt),
                    label: const Text("Aplicar Filtro"),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        reportDataFuture = _loadReportData();
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mesNome = DateFormat.MMMM('pt_BR').format(DateTime(0, selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios e Estatísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded),
            tooltip: 'Filtrar por mês/ano',
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: reportDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum dado encontrado.'));
          }

          final data = snapshot.data!;
          final doacoesPorDia = data['doacoesPorDia'] as Map<String, int>;
          final pedidosPorOng = data['pedidosPorOng'] as Map<String, int>;

          final doacoesData = doacoesPorDia.entries
              .map((e) => _ChartData(e.key, e.value))
              .toList();
          final pedidosData = pedidosPorOng.entries
              .map((e) => _ChartData(e.key, e.value))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📅 Estatísticas de $mesNome / $selectedYear',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(data),
                const SizedBox(height: 24),

                const Text('📦 Doações por Dia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                doacoesData.isEmpty
                    ? const Center(child: Text('Nenhuma doação neste período.'))
                    : SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        series: <CartesianSeries>[
                          ColumnSeries<_ChartData, String>(
                            dataSource: doacoesData,
                            xValueMapper: (d, _) => d.label,
                            yValueMapper: (d, _) => d.value,
                            color: Colors.purple,
                            dataLabelSettings:
                                const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),

                const SizedBox(height: 24),
                const Text('🏢 Pedidos por ONG',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                pedidosData.isEmpty
                    ? const Center(child: Text('Nenhum pedido neste período.'))
                    : SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        series: <CartesianSeries>[
                          BarSeries<_ChartData, String>(
                            dataSource: pedidosData,
                            xValueMapper: (d, _) => d.label,
                            yValueMapper: (d, _) => d.value,
                            color: Colors.orange,
                            dataLabelSettings:
                                const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(Map<String, dynamic> data) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryCard(Icons.people, 'Usuários', data['users'], Colors.blue),
        _summaryCard(Icons.handshake, 'ONGs', data['ongs'], Colors.orange),
        _summaryCard(Icons.store, 'Parceiros', data['parceiros'], Colors.green),
        _summaryCard(Icons.volunteer_activism, 'Doações', data['doacoes'], Colors.purple),
        _summaryCard(Icons.receipt_long, 'Pedidos', data['pedidos'], Colors.teal),
      ],
    );
  }

  Widget _summaryCard(IconData icon, String label, int value, Color color) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final int value;
  _ChartData(this.label, this.value);
}
