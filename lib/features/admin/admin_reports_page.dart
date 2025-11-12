import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:async/async.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final firestore = FirebaseFirestore.instance;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Stream combinada de várias coleções
  Stream<Map<String, dynamic>> _reportStream() async* {
    final doacoesStream = firestore.collection('doacoes').snapshots();
    final pedidosStream = firestore.collection('pedidos').snapshots();
    final usersStream = firestore.collection('users').snapshots();
    final ongsStream = firestore.collection('ongs').snapshots();
    final parceirosStream = firestore.collection('parceiros').snapshots();

    await for (final _ in StreamZip([
      doacoesStream,
      pedidosStream,
      usersStream,
      ongsStream,
      parceirosStream,
    ])) {
      final data = await _loadReportData();
      yield data;
    }
  }

  // Função que calcula todos os dados do relatório
  Future<Map<String, dynamic>> _loadReportData() async {
    final start = DateTime(selectedYear, selectedMonth, 1);
    final end = DateTime(selectedYear, selectedMonth + 1, 1)
        .subtract(const Duration(seconds: 1));

    final usersSnap = await firestore.collection('users').get();
    final ongsSnap = await firestore.collection('ongs').get();
    final parceirosSnap = await firestore.collection('parceiros').get();

    final doacoesSnap = await firestore.collection('doacoes').get();
    final pedidosSnap = await firestore.collection('pedidos').get();

    final doacoesDocs = doacoesSnap.docs.where((doc) {
      final dataCampo = doc.data()['dataDoacao'] ?? doc.data()['criadoEm'];
      if (dataCampo is! Timestamp) return false;
      final data = dataCampo.toDate();
      return data.isAfter(start) && data.isBefore(end);
    }).toList();

    final pedidosDocs = pedidosSnap.docs.where((doc) {
      final dataCampo = doc.data()['dataPedido'];
      if (dataCampo is! Timestamp) return false;
      final data = dataCampo.toDate();
      return data.isAfter(start) && data.isBefore(end);
    }).toList();

    // Doações por dia
    final Map<String, int> doacoesPorDia = {};
    for (var doc in doacoesDocs) {
      final dataCampo = doc.data()['dataDoacao'] ?? doc.data()['criadoEm'];
      final data = (dataCampo as Timestamp).toDate();
      final dia = DateFormat('dd/MM').format(data);
      doacoesPorDia[dia] = (doacoesPorDia[dia] ?? 0) + 1;
    }

    // Pedidos por dia
    final Map<String, int> pedidosPorDia = {};
    for (var doc in pedidosDocs) {
      final dataCampo = doc.data()['dataPedido'];
      final data = (dataCampo as Timestamp).toDate();
      final dia = DateFormat('dd/MM').format(data);
      pedidosPorDia[dia] = (pedidosPorDia[dia] ?? 0) + 1;
    }

    // Pedidos por ONG
    final Map<String, int> pedidosPorOng = {};
    final Map<String, String> nomeCache = {};
    final Map<String, Color> corCache = {};

    for (var doc in pedidosDocs) {
      final idOng = doc['idOng'];
      if (idOng == null) continue;

      if (!nomeCache.containsKey(idOng)) {
        final ongDoc = await firestore.collection('ongs').doc(idOng).get();
        if (ongDoc.exists) {
          nomeCache[idOng] = ongDoc['nome'] ?? 'Sem nome';
          final corOng = ongDoc.data()?['corOng'];
          if (corOng != null) {
            try {
              corCache[idOng] = _parseColor(corOng);
            } catch (_) {
              corCache[idOng] = Colors.orange;
            }
          } else {
            corCache[idOng] = Colors.orange;
          }
        } else {
          nomeCache[idOng] = 'Desconhecida';
          corCache[idOng] = Colors.orange;
        }
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
      'pedidosPorDia': pedidosPorDia,
      'pedidosPorOng': pedidosPorOng,
      'coresOng': corCache,
      'nomesOng': nomeCache,
    };
  }

  // Filtro de Mês/Ano
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
                  const Text('Filtrar por Mês e Ano',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(12, (i) {
                          final mes =
                              DateFormat.MMMM('pt_BR').format(DateTime(0, i + 1));
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
                      setState(() {});
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
        title: const Text('Relatórios e Estatísticas',style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 0, 42, 156),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded),
            tooltip: 'Filtrar por mês/ano',
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _reportStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final pedidosPorDia = data['pedidosPorDia'] as Map<String, int>;
          final doacoesPorDia = data['doacoesPorDia'] as Map<String, int>;
          final pedidosPorOng = data['pedidosPorOng'] as Map<String, int>;
          final coresOng = data['coresOng'] as Map<String, Color>;

          final pedidosDiaData = pedidosPorDia.entries
              .map((e) => _ChartData(e.key, e.value))
              .toList();
          final doacoesDiaData = doacoesPorDia.entries
              .map((e) => _ChartData(e.key, e.value))
              .toList();
          final pedidosOngData = pedidosPorOng.entries
              .map((e) => _ChartData(e.key, e.value))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 Estatísticas de $mesNome / $selectedYear',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildSummaryRow(data),
                const SizedBox(height: 24),

                const Text('🛒 Pedidos por Dia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                pedidosDiaData.isEmpty
                    ? const Center(child: Text('Nenhum pedido neste período.'))
                    : SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        series: <CartesianSeries>[
                          ColumnSeries<_ChartData, String>(
                            dataSource: pedidosDiaData,
                            xValueMapper: (d, _) => d.label,
                            yValueMapper: (d, _) => d.value,
                            color: Colors.teal,
                            dataLabelSettings:
                                const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),

                const Text('📦 Doações por Dia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                doacoesDiaData.isEmpty
                    ? const Center(child: Text('Nenhuma doação neste período.'))
                    : SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        series: <CartesianSeries>[
                          ColumnSeries<_ChartData, String>(
                            dataSource: doacoesDiaData,
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
                pedidosOngData.isEmpty
                    ? const Center(child: Text('Nenhum pedido neste período.'))
                    : SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        series: <CartesianSeries>[
                          BarSeries<_ChartData, String>(
                            dataSource: pedidosOngData,
                            xValueMapper: (d, _) => d.label,
                            yValueMapper: (d, _) => d.value,
                            pointColorMapper: (d, _) {
                              return coresOng.values.elementAt(
                                  pedidosOngData.indexOf(d) %
                                      coresOng.length);
                            },
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
          Text(value.toString(),
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Conversor de cores
  Color _parseColor(dynamic value) {
    if (value is int) return Color(value);
    if (value is String) {
      String hex = value.toUpperCase().replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    }
    return Colors.orange;
  }
}

class _ChartData {
  final String label;
  final int value;
  _ChartData(this.label, this.value);
}
