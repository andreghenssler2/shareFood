import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OngDoacoesPage extends StatefulWidget {
  const OngDoacoesPage({super.key});

  @override
  State<OngDoacoesPage> createState() => _OngDoacoesPageState();
}

class _OngDoacoesPageState extends State<OngDoacoesPage> {
  String filtroNome = '';
  String filtroCidade = '';
  String filtroEstado = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doações Recebidas',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
      ),
      body: Column(
        children: [
          // 🔹 Campos de Filtro
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Campo de busca pelo nome
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Pesquisar doação pelo nome',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (v) => setState(() => filtroNome = v),
                ),
                const SizedBox(height: 8),

                // 🔹 Linha com UF e Cidade
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: filtroEstado.isEmpty ? null : filtroEstado,
                        decoration: InputDecoration(
                          labelText: 'UF',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'RS', child: Text('RS')),
                          DropdownMenuItem(value: 'SC', child: Text('SC')),
                          DropdownMenuItem(value: 'PR', child: Text('PR')),
                          DropdownMenuItem(value: 'SP', child: Text('SP')),
                          DropdownMenuItem(value: 'RJ', child: Text('RJ')),
                          DropdownMenuItem(value: 'MG', child: Text('MG')),
                        ],
                        onChanged: (v) => setState(() => filtroEstado = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Cidade',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (v) => setState(() => filtroCidade = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          // 🔹 Lista de Doações
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doacoes')
                  .where('ativo', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhuma doação encontrada.'));
                }

                final doacoes = snapshot.data!.docs;

                final filtradas = doacoes.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome = (data['titulo'] ?? '').toString().toLowerCase();
                  return filtroNome.isEmpty || nome.contains(filtroNome.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filtradas.length,
                  itemBuilder: (context, index) {
                    final doc = filtradas[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final titulo = data['titulo'] ?? '';
                    final validade = data['validade'] ?? '';
                    final quantidade = data['quantidade']?.toString() ?? '';
                    final parceiroId = data['parceiroId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('parceiros')
                          .doc(parceiroId)
                          .get(),
                      builder: (context, parceiroSnap) {
                        if (parceiroSnap.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }

                        if (!parceiroSnap.hasData || !parceiroSnap.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final parceiro = parceiroSnap.data!.data() as Map<String, dynamic>? ?? {};
                        final empresa = parceiro['empresa'] ?? '';
                        final endereco = parceiro['endereco'] ?? {};
                        final cidade = endereco['cidade'] ?? '';
                        final estado = endereco['uf'] ?? '';

                        if (filtroCidade.isNotEmpty &&
                            !cidade.toString().toLowerCase().contains(filtroCidade.toLowerCase())) {
                          return const SizedBox.shrink();
                        }
                        if (filtroEstado.isNotEmpty &&
                            !estado.toString().toLowerCase().contains(filtroEstado.toLowerCase())) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          color: const Color(0xFFB2F0DC),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              '$titulo (${empresa})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Qtd: $quantidade • Validade: $validade\n$cidade - $estado',
                            ),
                            onTap: () => _mostrarDetalhes(context, data, parceiro, doc.id),
                          ),
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

  // 🔹 Mostra detalhes do produto
  void _mostrarDetalhes(BuildContext context, Map<String, dynamic> doacao,
      Map<String, dynamic> parceiro, String doacaoId) {
    final endereco = parceiro['endereco'] ?? {};

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  doacao['titulo'] ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(doacao['descricao'] ?? ''),
                const Divider(),
                Text('Marca: ${doacao['marca'] ?? ''}'),
                Text('Quantidade: ${doacao['quantidade']} ${doacao['unidade']}'),
                Text('Validade: ${doacao['validade']}'),
                const SizedBox(height: 15),
                const Text('Parceiro:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(parceiro['empresa'] ?? ''),
                Text('Contato: ${parceiro['email']}'),
                Text('Telefone: ${parceiro['telefone']}'),
                Text(
                    'Endereço: ${endereco['rua']}, ${endereco['numero']} - ${endereco['cidade']}/${endereco['uf']}'),
                const SizedBox(height: 20),

                // 🔹 Botão Adicionar ao Carrinho
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _perguntarQuantidade(context, {
                      ...doacao,
                      'id': doacaoId,
                      'parceiroId': parceiro['id'] ?? parceiro['uid'],
                    });
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Adicionar ao carrinho'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 Pergunta quantidade e adiciona ao carrinho
  void _perguntarQuantidade(BuildContext context, Map<String, dynamic> doacao) {
    final TextEditingController qtdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quantidade desejada'),
          content: TextField(
            controller: qtdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Digite a quantidade que deseja',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final qtd = int.tryParse(qtdController.text.trim()) ?? 0;

                if (qtd <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe uma quantidade válida.')),
                  );
                  return;
                }

                Navigator.pop(context);

                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuário não autenticado.')),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('carrinho').add({
                  'ongId': user.uid,
                  'doacaoId': doacao['id'],
                  'titulo': doacao['titulo'],
                  'quantidade': qtd,
                  'unidade': doacao['unidade'],
                  'parceiroId': doacao['parceiroId'],
                  'dataAdicao': Timestamp.now(),
                  'validade': doacao['validade'],
                });

                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/ong_carrinho_page');
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
