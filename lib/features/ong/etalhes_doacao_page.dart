import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetalhesDoacaoPage extends StatefulWidget {
  final Map<String, dynamic> doacao;
  final String parceiroId;

  const DetalhesDoacaoPage({
    super.key,
    required this.doacao,
    required this.parceiroId,
  });

  @override
  State<DetalhesDoacaoPage> createState() => _DetalhesDoacaoPageState();
}

class _DetalhesDoacaoPageState extends State<DetalhesDoacaoPage> {
  Map<String, dynamic>? parceiroData;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    buscarParceiro();
  }

  Future<void> buscarParceiro() async {
    try {
      DocumentSnapshot parceiroSnapshot = await FirebaseFirestore.instance
          .collection('parceiros')
          .doc(widget.parceiroId)
          .get();

      setState(() {
        parceiroData = parceiroSnapshot.data() as Map<String, dynamic>?;
        carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar parceiro: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doacao = widget.doacao;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Doação'),
        backgroundColor: Colors.green,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Text(
                    doacao['produto'] ?? 'Produto sem nome',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Quantidade: ${doacao['quantidade'] ?? '0'}'),
                  Text('Validade: ${doacao['validade'] ?? 'Sem validade'}'),
                  const Divider(height: 24),

                  Text(
                    'Informações do Parceiro',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  parceiroData != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nome: ${parceiroData?['nome'] ?? 'Sem nome'}'),
                            Text('Email: ${parceiroData?['email'] ?? '-'}'),
                            Text('Telefone: ${parceiroData?['telefone'] ?? '-'}'),
                            Text('Endereço: ${parceiroData?['endereco'] ?? '-'}'),
                          ],
                        )
                      : const Text('Informações do parceiro não encontradas.'),

                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    onPressed: () {
                      // ação de adicionar ao carrinho (pode ser implementada depois)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Produto adicionado ao carrinho!')),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Adicionar ao carrinho'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
