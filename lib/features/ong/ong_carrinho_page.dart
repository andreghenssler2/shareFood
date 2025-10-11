import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';



class OngCarrinhoPage extends StatefulWidget {
  const OngCarrinhoPage({super.key});

  @override
  State<OngCarrinhoPage> createState() => _OngCarrinhoPageState();
}

class _OngCarrinhoPageState extends State<OngCarrinhoPage> {
  final Map<String, DateTime> datasRecebimento = {};

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseFirestore.instance.collection('usuarios').id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carrinho')
            .where('ongId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final itens = snapshot.data!.docs;

          if (itens.isEmpty) {
            return const Center(child: Text('Seu carrinho está vazio.'));
          }

          // 🔹 Agrupar por parceiro
          final Map<String, List<QueryDocumentSnapshot>> grupos = {};
          for (var doc in itens) {
            final parceiroId = doc['parceiroId'];
            grupos.putIfAbsent(parceiroId, () => []).add(doc);
          }

          return ListView(
            children: grupos.entries.map((entry) {
              final parceiroId = entry.key;
              final produtos = entry.value;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('parceiros').doc(parceiroId).get(),
                builder: (context, snapshotParceiro) {
                  if (!snapshotParceiro.hasData) return const SizedBox.shrink();
                  final parceiro = snapshotParceiro.data!.data() as Map<String, dynamic>? ?? {};
                  final empresa = parceiro['empresa'] ?? 'Parceiro';

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(empresa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const Divider(),

                          // Produtos do parceiro
                          ...produtos.map((item) {
                            final data = item.data() as Map<String, dynamic>;
                            final validade = DateTime.parse(data['validade']);
                            return ListTile(
                              title: Text('${data['titulo']} (${data['quantidade']} ${data['unidade']})'),
                              subtitle: Text('Validade: ${data['validade']}'),
                            );
                          }),

                          const SizedBox(height: 8),

                          // 🔹 Escolher data de recebimento
                          ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(datasRecebimento.containsKey(parceiroId)
                                ? 'Receber em: ${DateFormat('dd/MM/yyyy').format(datasRecebimento[parceiroId]!)}'
                                : 'Escolher data de recebimento'),
                            onPressed: () async {
                              final DateTime? escolhida = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 3)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 180)),
                              );

                              if (escolhida != null) {
                                // 🔹 Verificar validade
                                bool dentroDoPrazo = true;
                                for (var item in produtos) {
                                  final validade = DateTime.parse(item['validade']);
                                  if (escolhida.isAfter(validade.subtract(const Duration(days: 15)))) {
                                    dentroDoPrazo = false;
                                    break;
                                  }
                                }

                                if (!dentroDoPrazo) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Data deve ser pelo menos 15 dias antes do vencimento.')),
                                  );
                                } else {
                                  setState(() => datasRecebimento[parceiroId] = escolhida);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
