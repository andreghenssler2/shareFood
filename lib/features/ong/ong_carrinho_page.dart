import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OngCarrinhoPage extends StatefulWidget {
  final List<Map<String, dynamic>> itensCarrinho;

  const OngCarrinhoPage({super.key, required this.itensCarrinho});

  @override
  State<OngCarrinhoPage> createState() => _OngCarrinhoPageState();
}

class _OngCarrinhoPageState extends State<OngCarrinhoPage> {
  bool _salvando = false;

  Future<void> confirmarPedido() async {
    if (widget.itensCarrinho.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carrinho vazio!')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado!')),
        );
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final pedidosRef = firestore.collection('pedidos');

      // 🔹 Verificar estoque antes de confirmar
      for (var item in widget.itensCarrinho) {
        final doc =
            await firestore.collection('doacoes').doc(item['doacaoId']).get();
        if (!doc.exists) {
          throw Exception('Produto "${item['titulo']}" não encontrado.');
        }

        final dados = doc.data()!;
        final int disponivel = ((dados['quantidade'] ?? 0) as num).toInt();
        final int solicitada = ((item['quantidade'] ?? 0) as num).toInt();

        if (solicitada > disponivel) {
          throw Exception(
              'Quantidade insuficiente de "${item['titulo']}". (Disponível: $disponivel)');
        }
      }

      // 🔹 Agrupar pedidos por parceiro
      final Map<String, List<Map<String, dynamic>>> pedidosPorParceiro = {};
      for (var item in widget.itensCarrinho) {
        final parceiroId = item['parceiroId'] ?? 'sem_parceiro';
        pedidosPorParceiro.putIfAbsent(parceiroId, () => []);
        pedidosPorParceiro[parceiroId]!.add(item);
      }

      final batch = firestore.batch();
      List<String> idsPedidos = [];

      // 🔹 Criar 1 pedido por parceiro
      for (var entry in pedidosPorParceiro.entries) {
        final parceiroId = entry.key;
        final itens = entry.value;

        final novoPedido = pedidosRef.doc();
        idsPedidos.add(novoPedido.id);

        batch.set(novoPedido, {
          'idOng': user.uid,
          'status': 'Pendente',
          'dataEntrega': DateTime.now().add(const Duration(days: 7)),
          'dataPedido': DateTime.now(),
          'itens': itens
              .map((i) => {
                    'idParceiro': parceiroId,
                    'idProduto': i['doacaoId'],
                    'titulo': i['titulo'],
                    // 🔧 Garantir que a quantidade seja salva como int
                    'quantidade': ((i['quantidade'] ?? 0) as num).toInt(),
                  })
              .toList(),
        });

        // 🔹 Atualiza estoque (quantidade disponível nas doações)
        for (var item in itens) {
          final ref = firestore.collection('doacoes').doc(item['doacaoId']);
          final doc = await ref.get();
          if (doc.exists) {
            final int atual = ((doc['quantidade'] ?? 0) as num).toInt();
            final int diminuir = ((item['quantidade'] ?? 0) as num).toInt();
            final int novaQtd = atual - diminuir;
            batch.update(ref, {'quantidade': novaQtd < 0 ? 0 : novaQtd});
          }
        }
      }

      await batch.commit();

      setState(() => widget.itensCarrinho.clear());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedidos confirmados: ${idsPedidos.join(', ')}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao confirmar pedido: $e')),
      );
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: widget.itensCarrinho.isEmpty
          ? const Center(child: Text('Carrinho vazio'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.itensCarrinho.length,
                    itemBuilder: (context, index) {
                      final item = widget.itensCarrinho[index];
                      return ListTile(
                        leading: const Icon(Icons.food_bank,
                            color: Colors.redAccent),
                        title: Text(item['titulo'] ?? 'Sem título'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantidade: ${item['quantidade']}'),
                            Text(
                              'Data de Entrega: ${DateTime.now().add(const Duration(days: 7)).toString().substring(0, 10)}',
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              widget.itensCarrinho.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: _salvando
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Icon(Icons.check),
                    label: const Text(
                      'Confirmar Pedido',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _salvando ? null : confirmarPedido,
                  ),
                ),
              ],
            ),
    );
  }
}
