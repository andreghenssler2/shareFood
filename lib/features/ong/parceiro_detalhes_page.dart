import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ParceiroDetalhesPage extends StatelessWidget {
  final String parceiroId;

  const ParceiroDetalhesPage({super.key, required this.parceiroId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes do Parceiro',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔹 muda a cor da seta para branca
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('parceiros')
            .doc(parceiroId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Parceiro não encontrado.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final endereco = data['endereco'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(Icons.store_mall_directory,
                          size: 80, color: Color.fromRGBO(158, 13, 0, 1)),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        data['empresa'] ?? 'Sem nome',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Responsável:', data['nome']),
                    _infoRow('CNPJ:', data['cnpj']),
                    _infoRow('E-mail:', data['email']),
                    _infoRow('Telefone:', data['telefone']),
                    const Divider(height: 30),
                    const Text(
                      'Endereço',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${endereco['rua'] ?? ''}, ${endereco['numero'] ?? ''}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${endereco['cidade'] ?? ''} - ${endereco['uf'] ?? ''}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    _infoRow('Status:', data['status']),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(158, 13, 0, 1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        label: const Text(
                          'Voltar',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value != null && value.toString().isNotEmpty
                  ? value.toString()
                  : '-',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
