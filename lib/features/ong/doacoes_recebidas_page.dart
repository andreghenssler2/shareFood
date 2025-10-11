import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'etalhes_doacao_page.dart';

class DoacoesRecebidasPage extends StatelessWidget {
  const DoacoesRecebidasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doações Recebidas'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doacoes')
            .snapshots(), // todas as doações
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhuma doação recebida ainda.'),
            );
          }

          final doacoes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doacoes.length,
            itemBuilder: (context, index) {
              final data = doacoes[index].data() as Map<String, dynamic>;
              final produto = data['produto'] ?? 'Produto sem nome';
              final quantidade = data['quantidade']?.toString() ?? '0';
              final validade = data['validade'] ?? 'Sem validade';
              final parceiroId = data['parceiroId'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(produto, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Qtd: $quantidade | Validade: $validade'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalhesDoacaoPage(
                          doacao: data,
                          parceiroId: parceiroId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
