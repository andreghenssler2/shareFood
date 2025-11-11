import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoricoPedidosPage extends StatefulWidget {
  const HistoricoPedidosPage({super.key});

  @override
  State<HistoricoPedidosPage> createState() => _HistoricoPedidosPageState();
}

class _HistoricoPedidosPageState extends State<HistoricoPedidosPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  ///  Buscar pedidos do parceiro logado
  Stream<List<Map<String, dynamic>>> _carregarPedidos() async* {
    if (user == null) {
      yield [];
      return;
    }

    yield* firestore
        .collection('pedidos')
        .orderBy('dataPedido', descending: true)
        .snapshots()
        .map((snapshot) {
      final pedidos = <Map<String, dynamic>>[];

      for (var pedidoDoc in snapshot.docs) {
        final pedidoData = pedidoDoc.data();

        if (pedidoData['itens'] is List) {
          final List itens = pedidoData['itens'];
          final itensParceiro =
              itens.where((i) => i['idParceiro'] == user!.uid).toList();

          if (itensParceiro.isNotEmpty) {
            pedidos.add({
              'pedidoId': pedidoDoc.id,
              'dataPedido': pedidoData['dataPedido'],
              'status': pedidoData['status'] ?? 'Pendente',
              'itens': itensParceiro,
              'idOng': pedidoData['idOng'] ?? '',
            });
          }
        }
      }

      return pedidos;
    });
  }

  ///  Buscar nome da ONG
  Future<String> _buscarNomeOng(String idOng) async {
    if (idOng.isEmpty) return 'ONG não informada';
    try {
      final doc = await firestore.collection('ongs').doc(idOng).get();
      if (doc.exists) {
        return doc.data()?['nome'] ?? 'ONG sem nome';
      } else {
        return 'ONG não encontrada';
      }
    } catch (e) {
      return 'Erro ao buscar ONG';
    }
  }

  ///  Confirmar entrega com data escolhida
  Future<void> _confirmarEntrega(
      String pedidoId, List<dynamic> itens, DateTime dataEntrega) async {
    try {
      final batch = firestore.batch();
      final pedidoRef = firestore.collection('pedidos').doc(pedidoId);

      batch.update(pedidoRef, {
        'status': 'Concluído',
        'dataEntrega': Timestamp.fromDate(dataEntrega),
      });

      for (var item in itens) {
        final idProduto = item['idProduto'];
        final quantidadePedido = item['quantidade'];

        if (idProduto != null) {
          final docProduto =
              await firestore.collection('doacoes').doc(idProduto).get();

          if (docProduto.exists) {
            final dados = docProduto.data()!;
            final quantidadeAtual = (dados['quantidade'] ?? 0) as int;
            final novaQuantidade = (quantidadeAtual - quantidadePedido).clamp(0, quantidadeAtual);

            batch.update(docProduto.reference, {'quantidade': novaQuantidade});
          }
        }
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrega confirmada e estoque atualizado!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao confirmar entrega: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ///  Recusar doação (soma no estoque)
  Future<void> _recusarDoacao(String pedidoId, List<dynamic> itens) async {
    try {
      final batch = firestore.batch();
      final pedidoRef = firestore.collection('pedidos').doc(pedidoId);

      batch.update(pedidoRef, {
        'status': 'Recusado',
        'dataRecusa': Timestamp.now(),
      });

      for (var item in itens) {
        final idProduto = item['idProduto'];
        final quantidadePedido = item['quantidade'];

        if (idProduto != null) {
          final docProduto =
              await firestore.collection('doacoes').doc(idProduto).get();

          if (docProduto.exists) {
            final dados = docProduto.data()!;
            final quantidadeAtual = (dados['quantidade'] ?? 0) as int;
            final novaQuantidade = quantidadeAtual + quantidadePedido;

            batch.update(docProduto.reference, {'quantidade': novaQuantidade});
          }
        }
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doação recusada e estoque restaurado!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao recusar doação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ///  Buscar nome do produto
  Future<String> _buscarNomeProduto(Map<String, dynamic> item) async {
    if (item.containsKey('nomeProduto') && item['nomeProduto'] != null) {
      return item['nomeProduto'];
    }

    final idProduto = item['idProduto'];
    if (idProduto == null) return 'Produto sem nome';

    try {
      final doc = await firestore.collection('doacoes').doc(idProduto).get();
      if (doc.exists) {
        return doc.data()?['titulo'] ?? 'Produto sem nome';
      }
      return 'Produto não encontrado';
    } catch (e) {
      return 'Erro ao buscar produto';
    }
  }

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return 'Sem data';
    final data = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Pedidos',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, //  muda a cor da seta para branca
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _carregarPedidos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum pedido encontrado.'));
          }

          final pedidos = snapshot.data!;

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              final dataPedido = pedido['dataPedido'] as Timestamp?;
              final itens = pedido['itens'] as List;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    'Pedido #${pedido['pedidoId']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  subtitle: FutureBuilder<String>(
                    future: _buscarNomeOng(pedido['idOng']),
                    builder: (context, snapshotOng) {
                      final nomeOng = snapshotOng.data ?? 'Buscando ONG...';
                      return Text(
                        'Data: ${_formatarData(dataPedido)}\nONG: $nomeOng',
                        style: const TextStyle(fontSize: 13),
                      );
                    },
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pedido['status'] == 'Concluído'
                          ? Colors.green[600]
                          : pedido['status'] == 'Recusado'
                              ? Colors.red[600]
                              : Colors.orange[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pedido['status'],
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  children: [
                    ...itens.map((item) {
                      return FutureBuilder<String>(
                        future: _buscarNomeProduto(item),
                        builder: (context, snapshotProduto) {
                          final nomeProduto =
                              snapshotProduto.data ?? 'Buscando produto...';
                          return ListTile(
                            title: Text(nomeProduto),
                            subtitle: Text(
                              'Quantidade: ${item['quantidade']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      );
                    }).toList(),

                    // Botões de ação quando o pedido está pendente
                    if (pedido['status'] == 'Pendente') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final dataSelecionada = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                    locale: const Locale('pt', 'BR'),
                                    helpText:
                                        'Selecione a data prevista para entrega',
                                    cancelText: 'Cancelar',
                                    confirmText: 'Confirmar',
                                  );

                                  if (dataSelecionada != null) {
                                    await _confirmarEntrega(
                                        pedido['pedidoId'],
                                        itens,
                                        dataSelecionada);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 0, 49, 139),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.check_circle_outline,
                                    color: Colors.white),
                                label: const Text(
                                  'Confirmar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _recusarDoacao(
                                    pedido['pedidoId'], itens),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.cancel_outlined,
                                    color: Colors.white),
                                label: const Text(
                                  'Recusar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
