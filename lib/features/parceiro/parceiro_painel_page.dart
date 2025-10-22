import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParceiroPainelPage extends StatelessWidget {
  const ParceiroPainelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
        title: const Text(
          'Painel do Parceiro',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(
              child: Text('Usuário não autenticado.'),
            )
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Doações próximas do vencimento:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('doacoes')
                        .where('parceiroId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhuma doação próxima do vencimento.',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      final doacoes = snapshot.data!.docs;
                      final proximasDoacoes = <Map<String, dynamic>>[];

                      for (var doc in doacoes) {
                        final data = doc.data() as Map<String, dynamic>;
                        final titulo = data['titulo'] ?? 'Sem nome';
                        final validadeStr = data['validade'] ?? '';

                        try {
                          final validade =
                              DateFormat("dd/MM/yyyy").parse(validadeStr);
                          final hoje = DateTime.now();
                          final diffDays = validade.difference(hoje).inDays;

                          if (diffDays <= 15) {
                            proximasDoacoes.add({
                              'titulo': titulo,
                              'validade': validadeStr,
                              'dias': diffDays,
                            });
                          }
                        } catch (_) {
                          // ignora datas inválidas
                        }
                      }

                      if (proximasDoacoes.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhuma doação próxima do vencimento.',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      // Ordenar por dias restantes (do menor para o maior)
                      proximasDoacoes
                          .sort((a, b) => a['dias'].compareTo(b['dias']));

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: proximasDoacoes.length,
                        itemBuilder: (context, index) {
                          final item = proximasDoacoes[index];
                          final titulo = item['titulo'];
                          final validade = item['validade'];
                          final dias = item['dias'];

                          IconData icon;
                          Color iconColor;

                          if (dias <= 7) {
                            icon = Icons.error_outline;
                            iconColor = Colors.red;
                          } else {
                            icon = Icons.warning_amber_rounded;
                            iconColor = Colors.orange;
                          }

                          return Card(
                            color: const Color(0xFFF8F8F8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Icon(icon, color: iconColor, size: 30),
                              title: Text(
                                titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Validade: $validade\nRestam: ${dias < 0 ? 0 : dias} dias',
                              ),
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
