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

  Future<String> _getParceiroNome(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('nome')) {
        return doc['nome'];
      }
      return 'Parceiro';
    } catch (e) {
      return 'Parceiro';
    }
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
        backgroundColor: Color.fromRGBO(185, 55, 43, 100),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                final doacoes = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: doacoes.length,
                  itemBuilder: (context, index) {
                    final data = doacoes[index].data() as Map<String, dynamic>;

                    final titulo = data['titulo'] ?? '';
                    final quantidade = data['quantidade']?.toString() ?? '';
                    final unidade = data['unidade'] ?? '';
                    final validadeStr = data['validade'] ?? '';
                    final parceiroId = data['parceiroId'] ?? '';
                    final imagemUrl = data['imagem'] ?? '';

                    // Converter validade
                    DateTime? validade;
                    try {
                      validade = DateFormat("dd/MM/yyyy").parse(validadeStr);
                    } catch (_) {}

                    // Verificar alertas
                    bool alertaAmarelo = false;
                    bool alertaVermelho = false;
                    if (validade != null) {
                      alertaAmarelo = _isNearExpiration(validade, 15);
                      alertaVermelho = _isNearExpiration(validade, 7);
                    }

                    return FutureBuilder<String>(
                      future: _getParceiroNome(parceiroId),
                      builder: (context, parceiroSnapshot) {
                        final parceiroNome =
                            parceiroSnapshot.data ?? 'Parceiro';

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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 🔹 Quantidade e Validade na mesma linha
                                      Row(
                                        children: [
                                          const Text(
                                            "Quantidade: ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text("$quantidade $unidade"),
                                          const SizedBox(width: 16),
                                          const Text(
                                            "Validade: ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(validadeStr),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // 🔹 Nome do parceiro
                                      Row(
                                        children: [
                                          const Text(
                                            "Parceiro: ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(parceiroNome),
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
                                child: Icon(Icons.error,
                                    color: Colors.red, size: 28),
                              ),
                          ],
                        );
                      },
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
