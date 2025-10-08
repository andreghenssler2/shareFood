import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoacoesParceiroPage extends StatelessWidget {
  const DoacoesParceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Doações'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doacoes')
            .where('parceiroId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doacoes = snapshot.data?.docs ?? [];

          if (doacoes.isEmpty) {
            return const Center(child: Text('Nenhuma doação encontrada.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: doacoes.length,
            itemBuilder: (context, index) {
              final data = doacoes[index].data() as Map<String, dynamic>;

              final nome = data['nome'] ?? '';
              final quantidade = data['quantidade'] ?? '';
              final unidade = data['unidade'] ?? '';
              final validade = data['validade'] ?? '';
              final parceiroNome = data['parceiroNome'] ?? '';
              final imagemUrl = data['imagem'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFFF0),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imagemUrl.isNotEmpty
                        ? Image.network(
                            imagemUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported),
                          ),
                  ),
                  title: Text(
                    nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'Quantidade ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('$quantidade $unidade'),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Validade ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(validade),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Parceiro ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            parceiroNome,
                            style: const TextStyle(fontSize: 12),
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
      ),
    );
  }
}
