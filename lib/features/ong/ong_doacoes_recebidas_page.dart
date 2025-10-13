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
          // 🔽 Filtro de status
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
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar doações: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma doação recebida ainda.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                // 🔎 Aplica filtro
                var pedidos = snapshot.data!.docs.where((doc) {
                  final status = doc['status'] ?? 'Pendente';
                  if (filtroStatus == 'Todos') return true;
                  return status == filtroStatus;
                }).toList();

                if (pedidos.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma doação com status "$filtroStatus".',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                // 🔄 Ordena por data
                pedidos.sort((a, b) {
                  final aData = a['dataPedido'];
                  final bData = b['dataPedido'];

                  DateTime? aDate;
                  DateTime? bDate;

                  try {
                    if (aData is Timestamp) aDate = aData.toDate();
                    if (bData is Timestamp) bDate = bData.toDate();
                  } catch (_) {}

                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return bDate.compareTo(aDate);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final data = pedido.data() as Map<String, dynamic>;

                    final nomeParceiro =
                        data['nomeParceiro'] ?? 'Parceiro não informado';
                    final itens = List<Map<String, dynamic>>.from(
                        data['itens'] ?? []);
                    final status = data['status'] ?? 'Pendente';
                    final validade = data['validade'];
                    final dataPedido = data['dataPedido'];

                    // 🕒 Formatando data
                    String dataFormatada = 'Data não disponível';
                    if (dataPedido is Timestamp) {
                      dataFormatada = DateFormat('dd/MM/yyyy HH:mm')
                          .format(dataPedido.toDate());
                    }

                    // 🧾 Verifica validade
                    String validadeStr = 'Sem validade';
                    bool expirando = false;
                    if (validade is Timestamp) {
                      final v = validade.toDate();
                      validadeStr = DateFormat('dd/MM/yyyy').format(v);
                      expirando = v.isBefore(DateTime.now().add(const Duration(days: 7)));
                    }

                    // 🟢 Ícone de status
                    IconData icone;
                    Color cor;
                    switch (status) {
                      case 'Concluido':
                        icone = Icons.check_circle;
                        cor = Colors.green;
                        break;
                      case 'Recusado':
                        icone = Icons.local_shipping;
                        cor = Colors.blue;
                        break;
                      default:
                        icone = Icons.access_time;
                        cor = Colors.orange;
                    }

                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        leading: Icon(icone, color: cor),
                        title: Text(
                          nomeParceiro,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(158, 13, 0, 1),
                          ),
                        ),
                        subtitle: Text('Recebido em $dataFormatada'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text(
                                  'Status: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(status, style: TextStyle(color: cor)),
                                const Spacer(),
                                Text(
                                  'Validade: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  validadeStr,
                                  style: TextStyle(
                                    color:
                                        expirando ? Colors.red : Colors.black,
                                    fontWeight: expirando
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...itens.map((item) {
                            final nome = item['nome'] ?? 'Item';
                            final qtd = item['quantidade'] ?? '0';
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.fastfood),
                              title: Text(nome),
                              trailing: Text('x$qtd'),
                            );
                          }),
                        ],
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
}
