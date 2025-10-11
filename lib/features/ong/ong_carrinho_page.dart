import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OngCarrinhoPage extends StatefulWidget {
  const OngCarrinhoPage({super.key});

  @override
  State<OngCarrinhoPage> createState() => _OngCarrinhoPageState();
}

class _OngCarrinhoPageState extends State<OngCarrinhoPage> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Map<String, DateTime> datasEntrega = {}; // parceiroId → data

  Future<void> _selecionarData(BuildContext context, String parceiroId, DateTime validade) async {
    final DateTime hoje = DateTime.now();
    final DateTime limite = validade.subtract(const Duration(days: 15));
    final DateTime primeiraData = hoje.isAfter(limite) ? hoje : limite;

    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: primeiraData,
      firstDate: primeiraData,
      lastDate: validade,
      locale: const Locale('pt', 'BR'),
    );

    if (dataEscolhida != null) {
      setState(() {
        datasEntrega[parceiroId] = dataEscolhida;
      });
    }
  }

  Future<void> _confirmarPedido(List<Map<String, dynamic>> produtos) async {
    final batch = firestore.batch();

    for (var produto in produtos) {
      final parceiroId = produto['parceiroId'];
      final dataEntrega = datasEntrega[parceiroId];
      if (dataEntrega == null) continue;

      // Salva em "doacoes_recebidas" para ONG
      final recebidaRef = firestore.collection('doacoes_recebidas').doc();
      batch.set(recebidaRef, {
        'produtoId': produto['id'],
        'nome': produto['titulo'],
        'quantidade': produto['quantidade'],
        'parceiroId': parceiroId,
        'ongId': user!.uid,
        'status': 'Em aberto',
        'dataEntrega': Timestamp.fromDate(dataEntrega),
        'dataSolicitacao': Timestamp.now(),
      });

      // Envia notificação ao parceiro
      final notificacaoRef = firestore.collection('notificacoes').doc();
      batch.set(notificacaoRef, {
        'parceiroId': parceiroId,
        'mensagem': 'A ONG fez um pedido do produto ${produto['titulo']}',
        'data': Timestamp.now(),
        'lida': false,
      });
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido confirmado com sucesso!')),
    );

    Navigator.pop(context); // volta para a tela anterior
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho'),
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('carrinho')
            .where('ongId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final produtos = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;

            // ⚙️ Proteções contra nulos
            data['titulo'] = (data['titulo'] ?? 'Produto sem título').toString();
            data['quantidade'] = (data['quantidade'] ?? '0').toString();
            data['parceiroId'] = (data['parceiroId'] ?? 'desconhecido').toString();

            // 🔧 Conversão segura de data
            late DateTime validade;
            try {
              final rawVal = data['validade'];
              if (rawVal is Timestamp) {
                validade = rawVal.toDate();
              } else if (rawVal is String && rawVal.isNotEmpty) {
                validade = DateFormat('dd/MM/yyyy').parse(rawVal);
              } else {
                validade = DateTime.now().add(const Duration(days: 30));
              }
            } catch (_) {
              validade = DateTime.now().add(const Duration(days: 30));
            }

            data['validadeDate'] = validade;
            return data;
          }).toList();

          if (produtos.isEmpty) {
            return const Center(child: Text('Seu carrinho está vazio.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: produtos.length,
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    final validade = produto['validadeDate'];
                    final parceiroId = produto['parceiroId'];

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(produto['titulo']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantidade: ${produto['quantidade']}'),
                            Text(
                              'Validade: ${DateFormat('dd/MM/yyyy').format(validade)}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              datasEntrega.containsKey(parceiroId)
                                  ? 'Entrega: ${DateFormat('dd/MM/yyyy').format(datasEntrega[parceiroId]!)}'
                                  : 'Nenhuma data selecionada',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: () => _selecionarData(context, parceiroId, validade),
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Escolher Data de Entrega'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Confirmar Pedido',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () => _confirmarPedido(produtos),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
