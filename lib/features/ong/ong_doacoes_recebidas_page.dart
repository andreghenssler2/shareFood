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
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
        title: const Text('Doações Recebidas'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔽 Filtro
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: pedidosRef
                  .where('idOng', isEqualTo: user?.uid)
                  // .orderBy('dataPedido', descending: false)
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

                var pedidos = snapshot.data!.docs.where((doc) {
                  final status = doc['status'] ?? 'Pendente';
                  if (filtroStatus == 'Todos') return true;
                  return status == filtroStatus;
                }).toList();

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
                    final dataPrevistaEntrega = data['dataEntrega'];

                    // 📅 Formatação das datas
                    String dataFormatada = 'Data não disponível';
                    if (dataPedido is Timestamp) {
                      dataFormatada = DateFormat('dd/MM/yyyy HH:mm')
                          .format(dataPedido.toDate());
                    }

                    String dataEntregaStr = 'Sem data';
                    if (dataPrevistaEntrega is Timestamp) {
                      dataEntregaStr = DateFormat('dd/MM/yyyy')
                          .format(dataPrevistaEntrega.toDate());
                    }

                    // 🎨 Ícone e cor conforme status
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

                    return FutureBuilder<Map<String, dynamic>>(
                      future: _buscarDadosParceiroEProduto(
                        itens.first['idParceiro'],
                        itens.first['idProduto'],
                      ),
                      builder: (context, asyncSnap) {
                        if (!asyncSnap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final titulo = asyncSnap.data!['titulo'];
                        final empresa = asyncSnap.data!['empresa'];
                        final validade = asyncSnap.data!['validade'];

                        return Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Icon(icone, color: cor, size: 32),
                            title: Text(
                              titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color.fromRGBO(158, 13, 0, 1),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Empresa: $empresa',
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Entrega: $dataEntregaStr',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Validade: $validade',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Status: $status',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: cor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
}
