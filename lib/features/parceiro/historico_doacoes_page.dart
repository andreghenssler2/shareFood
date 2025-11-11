import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoricoDoacoesPage extends StatefulWidget {
  const HistoricoDoacoesPage({super.key});

  @override
  State<HistoricoDoacoesPage> createState() => _HistoricoDoacoesPageState();
}

class _HistoricoDoacoesPageState extends State<HistoricoDoacoesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool carregando = true;
  List<Map<String, dynamic>> pedidosComOng = [];

  @override
  void initState() {
    super.initState();
    carregarPedidos();
  }

  Future<void> carregarPedidos() async {
    try {
      final snapshot = await _firestore
          .collection('pedidos')
          .orderBy('dataCriacao', descending: true)
          .get();

      List<Map<String, dynamic>> lista = [];

      for (var doc in snapshot.docs) {
        final pedido = doc.data();
        final ongId = pedido['ongId'];
 
        // Busca nome da ONG
        String nomeOng = 'ONG desconhecida';
        if (ongId != null) {
          final ongDoc = await _firestore.collection('ongs').doc(ongId).get();
          if (ongDoc.exists) {
            nomeOng = ongDoc['nome'] ?? nomeOng;
          }
        }

        lista.add({
          'pedidoId': pedido['pedidoId'],
          'nomeOng': nomeOng,
          'status': pedido['status'] ?? 'Em aberto',
          'dataCriacao': pedido['dataCriacao'],
          'itens': pedido['itens'] ?? [],
        });
      }

      setState(() {
        pedidosComOng = lista;
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar pedidos: $e');
      setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Doações'),
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
        iconTheme: const IconThemeData(
          color: Colors.white, // muda a cor da seta para branca
        ),
        centerTitle: true,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : pedidosComOng.isEmpty
              ? const Center(child: Text('Nenhum pedido encontrado.'))
              : ListView.builder(
                  itemCount: pedidosComOng.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidosComOng[index];
                    final data = pedido['dataCriacao'] != null
                        ? DateFormat('dd/MM/yyyy HH:mm')
                            .format(pedido['dataCriacao'].toDate())
                        : 'Sem data';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      elevation: 2,
                      child: ExpansionTile(
                        title: Text(
                          pedido['nomeOng'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(158, 13, 0, 1),
                          ),
                        ),
                        subtitle: Text('Status: ${pedido['status']}'),
                        trailing: Text(
                          data,
                          style: const TextStyle(fontSize: 12),
                        ),
                        children: (pedido['itens'] as List)
                            .map((item) => ListTile(
                                  dense: true,
                                  title: Text(item['titulo'] ?? 'Sem nome'),
                                  subtitle: Text(
                                      'Qtd: ${item['quantidade']}  |  Entrega: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['dataEntrega']))}'),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
