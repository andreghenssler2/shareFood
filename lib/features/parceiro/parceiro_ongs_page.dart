import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'parceiro_ong_detalhes_page.dart';

class OngListPage extends StatefulWidget {
  final String parceiroCidade;
  final String parceiroUF;

  const OngListPage({
    required this.parceiroCidade,
    required this.parceiroUF,
    super.key,
  });

  @override
  State<OngListPage> createState() => _OngListPageState();
}

class _OngListPageState extends State<OngListPage> {
  String searchQuery = '';
  String? selectedUF;
  String? selectedCidade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ONGs Cadastradas'),
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
      ),
      body: Column(
        children: [
          // 🔍 Pesquisa e filtros
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Pesquisar ONG pelo nome',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUF,
                        hint: const Text('Filtrar por UF'),
                        items: ['RS', 'SC', 'PR']
                            .map((uf) => DropdownMenuItem(
                                  value: uf,
                                  child: Text(uf),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => selectedUF = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() => selectedCidade = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📋 Lista de ONGs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ongs').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome = (data['nome'] ?? '').toString().toLowerCase();
                  final endereco = data['endereco'] ?? {};
                  final cidade = (endereco['cidade'] ?? '').toString().toLowerCase();
                  final uf = (endereco['uf'] ?? '').toString();

                  final matchesSearch =
                      searchQuery.isEmpty || nome.contains(searchQuery.toLowerCase());
                  final matchesUF = selectedUF == null || uf == selectedUF;
                  final matchesCidade = selectedCidade == null ||
                      cidade.contains(selectedCidade!.toLowerCase());

                  return matchesSearch && matchesUF && matchesCidade;
                }).toList();

                filtered.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final endA = dataA['endereco'] ?? {};
                  final endB = dataB['endereco'] ?? {};
                  final cidadeA = (endA['cidade'] ?? '').toString();
                  final cidadeB = (endB['cidade'] ?? '').toString();
                  if (cidadeA == widget.parceiroCidade &&
                      cidadeB != widget.parceiroCidade) return -1;
                  if (cidadeB == widget.parceiroCidade &&
                      cidadeA != widget.parceiroCidade) return 1;
                  return cidadeA.compareTo(cidadeB);
                });

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma ONG encontrada.'),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index].data() as Map<String, dynamic>;
                    final endereco = data['endereco'] ?? {};

                    final nome = data['nome'] ?? 'ONG sem nome';
                    final cidade = endereco['cidade'] ?? '';
                    final uf = endereco['uf'] ?? '';
                    final email = data['email'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(
                          nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('$cidade - $uf\n$email'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OngDetalhesPage(
                                ongData: data,
                              ),
                            ),
                          );
                        },
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
