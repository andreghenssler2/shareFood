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
  void initState() {
    super.initState();
    selectedUF = widget.parceiroUF; // mantém a UF padrão
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ONGs Cadastradas',
          style: TextStyle(color: Colors.white),
        ),
        
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔹 muda a cor da seta para branca
        ),
        centerTitle: true,
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
                  onChanged: (value) {
                    setState(() => searchQuery = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'UF',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedUF,
                        items: const [
                          DropdownMenuItem(value: 'RS', child: Text('RS')),
                          DropdownMenuItem(value: 'SC', child: Text('SC')),
                          DropdownMenuItem(value: 'PR', child: Text('PR')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedUF = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() => selectedCidade = value);
                        },
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
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar ONGs'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ongs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final endereco = data['endereco'] ?? {};
                  final nome = (data['nome'] ?? '').toString().toLowerCase();
                  final cidade = (endereco['cidade'] ?? '').toString().toLowerCase();
                  final uf = (endereco['uf'] ?? '').toString().toUpperCase();

                  final matchesSearch = nome.contains(searchQuery);
                  final matchesCidade = selectedCidade == null ||
                      selectedCidade!.isEmpty ||
                      cidade.contains(selectedCidade!.toLowerCase());
                  final matchesUF =
                      selectedUF == null || uf == selectedUF!.toUpperCase();

                  return matchesSearch && matchesCidade && matchesUF;
                }).toList();

                if (ongs.isEmpty) {
                  return const Center(child: Text('Nenhuma ONG encontrada.'));
                }

                return ListView.builder(
                  itemCount: ongs.length,
                  itemBuilder: (context, index) {
                    final document = ongs[index];
                    final data = document.data() as Map<String, dynamic>;
                    final endereco = data['endereco'] ?? {};

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        title: Text(data['nome'] ?? 'Sem nome'),
                        subtitle: Text(
                            '${endereco['cidade'] ?? ''} - ${endereco['uf'] ?? ''}'),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OngDetalhesPage(ongId: document.id),
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
