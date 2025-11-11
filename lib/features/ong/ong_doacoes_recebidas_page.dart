import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OngDoacoesRecebidasPage extends StatefulWidget {
  const OngDoacoesRecebidasPage({super.key});

  @override
  State<OngDoacoesRecebidasPage> createState() =>
      _OngDoacoesRecebidasPageState();
}

class _OngDoacoesRecebidasPageState extends State<OngDoacoesRecebidasPage> {
  final user = FirebaseAuth.instance.currentUser;
  String filtroStatus = 'Todos';
  final List<String> statusList = ['Todos', 'Pendente', 'Concluído', 'Recusado'];

  Future<Map<String, dynamic>> _buscarDadosParceiroEProduto(
      String parceiroId, String produtoId) async {
    final parceiroSnap = await FirebaseFirestore.instance
        .collection('parceiros')
        .doc(parceiroId)
        .get();

    final doacaoSnap = await FirebaseFirestore.instance
        .collection('doacoes')
        .doc(produtoId)
        .get();

    final empresa = parceiroSnap.data()?['empresa'] ?? 'Empresa não informada';
    final titulo = doacaoSnap.data()?['titulo'] ?? 'Produto';
    final validade = doacaoSnap.data()?['validade'] ?? 'Sem validade';

    return {
      'empresa': empresa,
      'titulo': titulo,
      'validade': validade,
    };
  }

  @override
  Widget build(BuildContext context) {
    final pedidosRef = FirebaseFirestore.instance.collection('pedidos');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Doações Recebidas',
          style: TextStyle(color: Colors.white),
        ),
        
        iconTheme: const IconThemeData(
          color: Colors.white, //  muda a cor da seta para branca
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filtro de status
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: filtroStatus,
              decoration: InputDecoration(
                labelText: 'Filtrar por status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: statusList
                  .map((status) =>
                      DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (valor) {
                setState(() {
                  filtroStatus = valor!;
                });
              },
            ),
          ),

          //  Lista de pedidos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              //   Ordenação local (funciona sem índice)
              stream: pedidosRef
                  .where('idOng', isEqualTo: user?.uid)
                  .snapshots(),



              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma doação recebida ainda.'),
                  );
                }

                //  Filtra e ordena localmente
                var pedidos = snapshot.data!.docs.where((doc) {
                  final status = doc['status'] ?? 'Pendente';
                  if (filtroStatus == 'Todos') return true;
                  return status == filtroStatus;
                }).toList();

                //  Ordena por dataPedido (mais recentes primeiro)
                pedidos.sort((a, b) {
                  final dataA = a['dataPedido'];
                  final dataB = b['dataPedido'];
                  if (dataA is Timestamp && dataB is Timestamp) {
                    return dataB.compareTo(dataA);
                  }
                  return 0;
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final data = pedido.data() as Map<String, dynamic>;
                    final itens =
                        List<Map<String, dynamic>>.from(data['itens'] ?? []);
                    final status = data['status'] ?? 'Pendente';
                    final dataPedido = data['dataPedido'];
                    final dataEntrega = data['dataEntrega'];

                    // Formatação das datas
                    String dataPedidoStr = 'Data não disponível';
                    if (dataPedido is Timestamp) {
                      dataPedidoStr = DateFormat('dd/MM/yyyy HH:mm')
                          .format(dataPedido.toDate());
                    }

                    String dataEntregaStr = '';
                    if (status != 'Recusado' && dataEntrega is Timestamp) {
                      dataEntregaStr = DateFormat('dd/MM/yyyy')
                          .format(dataEntrega.toDate());
                    }

                    // Ícone e cor conforme status
                    IconData icone;
                    Color cor;
                    switch (status) {
                      case 'Concluído':
                        icone = Icons.check_circle;
                        cor = Colors.green;
                        break;
                      case 'Recusado':
                        icone = Icons.cancel;
                        cor = Colors.red;
                        break;
                      default:
                        icone = Icons.access_time;
                        cor = Colors.orange;
                    }

                    //  Exibir todos os itens do pedido em um único card
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: Future.wait(itens.map((item) async {
                        final dados = await _buscarDadosParceiroEProduto(
                          item['idParceiro'],
                          item['idProduto'],
                        );
                        return {
                          ...dados,
                          'quantidade': item['quantidade'],
                        };
                      })),
                      builder: (context, snapshotItens) {
                        if (!snapshotItens.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final listaItens = snapshotItens.data!;

                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(icone, color: cor, size: 32),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Status: $status',
                                      style: TextStyle(
                                        color: cor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Data do Pedido: $dataPedidoStr'),
                                if (dataEntregaStr.isNotEmpty)
                                  Text('Entrega: $dataEntregaStr'),
                                const Divider(),
                                ...listaItens.map((item) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['titulo'] ?? 'Produto',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color:
                                                Color.fromRGBO(158, 13, 0, 1),
                                          ),
                                        ),
                                        Text('Empresa: ${item['empresa']}'),
                                        Text('Validade: ${item['validade']}'),
                                        Text(
                                            'Quantidade: ${item['quantidade']}'),
                                        const SizedBox(height: 6),
                                      ],
                                    )),
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
}
