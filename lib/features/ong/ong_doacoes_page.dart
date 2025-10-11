import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ong_carrinho_page.dart';

class OngDoacoesPage extends StatefulWidget {
  const OngDoacoesPage({super.key});

  @override
  State<OngDoacoesPage> createState() => _OngDoacoesPageState();
}

class _OngDoacoesPageState extends State<OngDoacoesPage> {
  // Lista local que armazena os itens que a ONG adiciona ao carrinho
  List<Map<String, dynamic>> listaDeItens = [];

  // Adiciona o item à lista local
  void adicionarAoCarrinho(Map<String, dynamic> item) {
    setState(() {
      listaDeItens.add(item);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['titulo']} adicionado ao carrinho!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Abre a página do carrinho e envia a lista de itens selecionados
  void abrirCarrinho() {
    if (listaDeItens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carrinho vazio! Adicione itens antes de continuar.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OngCarrinhoPage(itensCarrinho: listaDeItens),
      ),
    );
  }

  // Função que pergunta a quantidade desejada e valida com o estoque
  Future<void> perguntarQuantidadeEAdicionar(
      Map<String, dynamic> dados, String doacaoId) async {
    final TextEditingController quantidadeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar "${dados['titulo']}" ao carrinho'),
        content: TextField(
          controller: quantidadeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantidade desejada',
            hintText: 'Digite a quantidade',
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Adicionar'),
            onPressed: () {
              final int qtdDesejada = int.tryParse(quantidadeController.text) ?? 0;
              final int qtdDisponivel = dados['quantidade'] ?? 0;

              if (qtdDesejada <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe uma quantidade válida!')),
                );
                return;
              }

              if (qtdDesejada > qtdDisponivel) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Quantidade insuficiente! Disponível: $qtdDisponivel unidades.'),
                  ),
                );
                return;
              }

              adicionarAoCarrinho({
                'titulo': dados['titulo'] ?? 'Sem título',
                'quantidade': qtdDesejada,
                'dataEntrega': dados['dataValidade'] ??
                    DateTime.now()
                        .add(const Duration(days: 30))
                        .toIso8601String(),
                'parceiroId': dados['parceiroId'] ?? 'Desconhecido',
                'doacaoId': doacaoId,
              });

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doações Disponíveis',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: abrirCarrinho,
              ),
              if (listaDeItens.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${listaDeItens.length}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doacoes')
            .where('ativo', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhuma doação disponível no momento.'),
            );
          }

          final doacoes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: doacoes.length,
            itemBuilder: (context, index) {
              final doc = doacoes[index];
              final dados = doc.data() as Map<String, dynamic>? ?? {};

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                child: ListTile(
                  leading: const Icon(Icons.food_bank, color: Colors.redAccent),
                  title: Text(
                    dados['titulo'] ?? 'Sem título',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantidade disponível: ${dados['quantidade'] ?? '0'}'),
                      Text(
                        'Validade: ${dados['dataValidade'] ?? '---'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                    onPressed: () => perguntarQuantidadeEAdicionar(dados, doc.id),
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
