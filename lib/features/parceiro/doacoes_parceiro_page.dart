import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DoacoesParceiroPage extends StatelessWidget {
  const DoacoesParceiroPage({super.key});

  bool _isNearExpiration(DateTime validade, int days) {
    final hoje = DateTime.now();
    return validade.isBefore(hoje.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Doações',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
      ),
      body: Column(
        children: [
          // 🔹 Botão "Cadastrar Produto"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/criarDoacao');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Cadastrar Produto',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 🔹 Lista de doações
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doacoes')
                  .where('parceiroId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Você ainda não fez nenhuma doação.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                // 🔸 Converter e ordenar por validade
                final doacoes = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  DateTime? validade;
                  try {
                    validade = DateFormat("dd/MM/yyyy")
                        .parse(data['validade'] ?? '');
                  } catch (_) {}
                  return {
                    'id': doc.id,
                    ...data,
                    'validadeDate': validade,
                  };
                }).toList();

                doacoes.sort((a, b) {
                  final va = a['validadeDate'];
                  final vb = b['validadeDate'];
                  if (va == null && vb == null) return 0;
                  if (va == null) return 1;
                  if (vb == null) return -1;
                  return va.compareTo(vb);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: doacoes.length,
                  itemBuilder: (context, index) {
                    final data = doacoes[index];
                    final titulo = data['titulo'] ?? '';
                    final quantidade = data['quantidade']?.toString() ?? '';
                    final unidade = data['unidade'] ?? '';
                    final validadeStr = data['validade'] ?? '';
                    final imagemUrl = data['imagem'] ?? '';
                    final validade = data['validadeDate'];

                    // Verificar alertas
                    bool alertaAmarelo = false;
                    bool alertaVermelho = false;
                    if (validade != null) {
                      alertaAmarelo = _isNearExpiration(validade, 15);
                      alertaVermelho = _isNearExpiration(validade, 7);
                    }

                    return Stack(
                      children: [
                        Card(
                          color: const Color(0xFFB2F0DC),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: imagemUrl.isNotEmpty
                                  ? Image.network(
                                      imagemUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image,
                                          color: Colors.grey),
                                    ),
                            ),
                            title: Text(
                              titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text(
                                          "Quantidade: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text("$quantidade $unidade"),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        "Validade: ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(validadeStr),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 🔶 Alerta amarelo (≤15 dias)
                        if (alertaAmarelo && !alertaVermelho)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(Icons.warning_amber_rounded,
                                color: Colors.amber[700], size: 28),
                          ),

                        // 🔴 Alerta vermelho (≤7 dias)
                        if (alertaVermelho)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child:
                                Icon(Icons.error, color: Colors.red, size: 28),
                          ),
                      ],
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
