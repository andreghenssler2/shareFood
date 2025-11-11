import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OngDoacaoDetalhePage extends StatelessWidget {
  final String doacaoId;
  final Map<String, dynamic> dados;

  const OngDoacaoDetalhePage({
    super.key,
    required this.doacaoId,
    required this.dados,
  });

  Future<Map<String, dynamic>?> getParceiroInfo(String parceiroId) async {
    final doc = await FirebaseFirestore.instance
        .collection('parceiros')
        .doc(parceiroId)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dados['produto'] ?? 'Detalhes da Doação',style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        
        iconTheme: const IconThemeData(
          color: Colors.white, // muda a cor da seta para branca
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getParceiroInfo(dados['parceiroId']),
        builder: (context, snapshot) {
          final parceiro = snapshot.data;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  dados['produto'] ?? '-',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Quantidade: ${dados['quantidade'] ?? '-'}'),
                Text('Validade: ${dados['validade'] ?? '-'}'),
                Text('Descrição: ${dados['descricao'] ?? 'Sem descrição'}'),
                Text('Cidade: ${dados['cidade'] ?? '-'} / ${dados['estado'] ?? '-'}'),
                const Divider(height: 30),
                const Text(
                  'Informações do Parceiro:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                if (parceiro == null)
                  const Text('Carregando informações...')
                else ...[
                  Text('Nome: ${parceiro['nome'] ?? '-'}'),
                  Text('Email: ${parceiro['email'] ?? '-'}'),
                  Text('Telefone: ${parceiro['telefone'] ?? '-'}'),
                  Text('Endereço: ${parceiro['endereco'] ?? '-'}'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
