import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoacoesParceiroPage extends StatelessWidget {
  const DoacoesParceiroPage({super.key});

  Stream<QuerySnapshot> _streamDoacoes() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return FirebaseFirestore.instance
        .collection('doacoes')
        .where('parceiroId', isEqualTo: uid)
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disponível':
        return Colors.green;
      case 'reservado':
        return Colors.orange;
      case 'entregue':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Minhas Doações'),
        backgroundColor: Colors.orange,
        centerTitle: true,
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
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doacao = docs[index].data() as Map<String, dynamic>;

              final titulo = doacao['titulo'] ?? 'Sem título';
              final descricao = doacao['descricao'] ?? '';
              final quantidade = doacao['quantidade']?.toString() ?? '0';
              final unidade = doacao['unidade'] ?? '';
              final validade = doacao['validade'] ?? '';
              final status = doacao['status'] ?? 'Disponível';
              final marca = doacao['marca'] ?? '';

              final statusColor = _getStatusColor(status);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.fastfood, color: Colors.orange),
                  ),
                  title: Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Descrição: $descricao\n'
                      'Marca: $marca\n'
                      'Quantidade: $quantidade $unidade\n'
                      'Validade: $validade',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 12),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
