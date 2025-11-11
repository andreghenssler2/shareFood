import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'parceiro_detalhes_page.dart';

class OngParceirosListPage extends StatefulWidget {
  final String ongCidade;
  final String ongUF;

  const OngParceirosListPage({
    super.key,
    required this.ongCidade,
    required this.ongUF,
  });

  @override
  State<OngParceirosListPage> createState() => _OngParceirosListPageState();
}

class _OngParceirosListPageState extends State<OngParceirosListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedUF = '';
  String _cidadeFiltro = '';
  String _nomeFiltro = '';

  @override
  void initState() {
    super.initState();
    _selectedUF = widget.ongUF;
    _cidadeFiltro = widget.ongCidade;
  }

  // Consulta dinâmica com filtros de nome, UF e cidade
  Stream<QuerySnapshot> _buscarParceiros() {
    var query = FirebaseFirestore.instance
        .collection('parceiros')
        .where('endereco.uf', isEqualTo: _selectedUF);

    if (_cidadeFiltro.isNotEmpty) {
      query = query.where('endereco.cidade', isEqualTo: _cidadeFiltro);
    }

    if (_nomeFiltro.isNotEmpty) {
      query = query
          .where('nome', isGreaterThanOrEqualTo: _nomeFiltro)
          .where('nome', isLessThan: '${_nomeFiltro}z');
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Parceiros Disponíveis',style: TextStyle(color: Colors.white)),
        
        iconTheme: const IconThemeData(
          color: Colors.white, // muda a cor da seta para branca
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Campo de busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Pesquisar parceiro pelo nome',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _nomeFiltro = value.trim();
                });
              },
            ),
            const SizedBox(height: 12),

            // Filtros de UF e Cidade
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUF,
                    decoration: const InputDecoration(
                      labelText: 'UF',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'RS', child: Text('RS')),
                      DropdownMenuItem(value: 'SC', child: Text('SC')),
                      DropdownMenuItem(value: 'PR', child: Text('PR')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUF = value ?? widget.ongUF;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: _cidadeFiltro),
                    onChanged: (value) {
                      setState(() {
                        _cidadeFiltro = value.trim();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de parceiros
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buscarParceiros(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum parceiro encontrado.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final parceiro = docs[index].data() as Map<String, dynamic>;
                      final nome = parceiro['empresa'] ?? 'Sem nome';
                      final endereco = parceiro['endereco'] ?? {};
                      final cidade = endereco['cidade'] ?? '';
                      final uf = endereco['uf'] ?? '';

                      return Card(
                        color: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('$cidade - $uf'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            final parceiroId = docs[index].id; //  ID do documento Firestore
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ParceiroDetalhesPage(
                                  parceiroId: parceiroId,
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
      ),
    );
  }
}
