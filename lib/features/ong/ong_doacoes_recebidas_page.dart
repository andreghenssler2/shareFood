import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OngDoacoesRecebidasPage extends StatelessWidget {
  const OngDoacoesRecebidasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doações Recebidas'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('doacoes_recebidas')
            .orderBy('criadoEm', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Nenhuma doação recebida ainda.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doacao = docs[index].data();
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(doacao['produtoNome'] ?? 'Produto'),
                  subtitle: Text(
                    'Status: ${doacao['status']}\nReceber em: ${(doacao['dataRecebimento'] as Timestamp).toDate().toString().split(" ")[0]}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
