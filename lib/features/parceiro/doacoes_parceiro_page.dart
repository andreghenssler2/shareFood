import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoacoesParceiroPage extends StatelessWidget {
  const DoacoesParceiroPage({super.key});

  // Stream das doações do parceiro logado
  Stream<QuerySnapshot> _streamDoacoes() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('doacoes')
        .where('parceiroId', isEqualTo: uid) // filtra pelo parceiro logado
        .orderBy('criadoEm', descending: true) // nome do campo no Firestore
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Doações'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamDoacoes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma doação cadastrada ainda.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doacao = docs[index].data() as Map<String, dynamic>;

              final titulo = doacao['titulo'] ?? 'Sem título';
              final descricao = doacao['descricao'] ?? '';
              final marca = doacao['marca'] ?? '';
              final quantidade = doacao['quantidade']?.toString() ?? '';
              final unidade = doacao['unidade'] ?? '';
              final validade = doacao['validade'] ?? '';
              final criadoEm = (doacao['criadoEm'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.fastfood, color: Colors.orange),
                  title: Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Marca: $marca\n'
                    'Quantidade: $quantidade $unidade\n'
                    'Validade: $validade\n'
                    'Descrição: $descricao\n'
                    '${criadoEm != null ? 'Criado em: ${criadoEm.day}/${criadoEm.month}/${criadoEm.year}' : ''}',
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
