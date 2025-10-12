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

    setState(() {
      _salvando = true;
    });

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

      // 🔹 Verificar estoque antes de confirmar o pedido
      for (var item in widget.itensCarrinho) {
        final doacaoRef = firestore.collection('doacoes').doc(item['doacaoId']);
        final doc = await doacaoRef.get();

        if (!doc.exists) {
          throw Exception('Produto "${item['titulo']}" não encontrado.');
        }

        final dados = doc.data()!;
        final int quantidadeDisponivel = dados['quantidade'] ?? 0;
        final int quantidadeSolicitada = item['quantidade'] ?? 0;

        if (quantidadeSolicitada > quantidadeDisponivel) {
          throw Exception(
              'Quantidade insuficiente de "${item['titulo']}". Disponível: $quantidadeDisponivel.');
        }
      }

      // 🔹 Criar pedido
      final novoPedido = await pedidosRef.add({
        'idOng': user.uid,
        'status': 'Pendente',
        'dataPedido': DateTime.now(),
        'itens': widget.itensCarrinho.map((item) {
          return {
            'idProduto': item['doacaoId'] ?? '',
            'idParceiro': item['parceiroId'] ?? '',
            'quantidade': item['quantidade'] ?? 0,
          };
        }).toList(),
      });

      // 🔹 Atualizar estoques no Firestore
      final batch = firestore.batch();

      for (var item in widget.itensCarrinho) {
        final doacaoRef = firestore.collection('doacoes').doc(item['doacaoId']);
        final doc = await doacaoRef.get();

        if (doc.exists) {
          final dados = doc.data()!;
          final int quantidadeAtual = (dados['quantidade'] ?? 0).toInt();
          final int novaQuantidade = quantidadeAtual - ((item['quantidade'] ?? 0) as num).toInt();

          batch.update(doacaoRef, {
            'quantidade': novaQuantidade < 0 ? 0 : novaQuantidade,
          });
        }
      }

      await batch.commit();

      setState(() {
        widget.itensCarrinho.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido ${novoPedido.id} confirmado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao confirmar pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
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
                            Text('Validade: ${item['dataEntrega'] ?? '---'}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
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
                    label: const Text('Confirmar Pedido',style: TextStyle(color: Colors.white)),
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
