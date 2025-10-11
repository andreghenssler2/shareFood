import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DoacoesParceiroPage extends StatefulWidget {
  const DoacoesParceiroPage({super.key});

  @override
  State<DoacoesParceiroPage> createState() => _DoacoesParceiroPageState();
}

class _DoacoesParceiroPageState extends State<DoacoesParceiroPage> {
  String filtro = 'ativos'; // 🔹 controla o filtro ativo

  bool _isNearExpiration(DateTime validade, int days) {
    final hoje = DateTime.now();
    return validade.isBefore(hoje.add(Duration(days: days)));
  }

  void _editarProduto(BuildContext context, String docId, Map<String, dynamic> data) {
    bool ativo = data['ativo'] ?? true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    "Editar Produto",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Produto Ativo:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Switch(
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        value: ativo,
                        onChanged: (value) async {
                          setStateModal(() => ativo = value);
                          await FirebaseFirestore.instance
                              .collection('doacoes')
                              .doc(docId)
                              .update({'ativo': value});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/editarDoacao', arguments: data);
                    },
                    label: const Text(
                      "Editar Informações do Produto",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Excluir produto"),
                          content: const Text("Tem certeza que deseja excluir este produto?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Excluir")),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance.collection('doacoes').doc(docId).delete();
                        Navigator.pop(context);
                      }
                    },
                    label: const Text(
                      "Excluir Produto",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    // 🔹 Define o stream conforme o filtro selecionado
    Query doacoesQuery = FirebaseFirestore.instance
        .collection('doacoes')
        .where('parceiroId', isEqualTo: user.uid);

    if (filtro == 'ativos') {
      doacoesQuery = doacoesQuery.where('ativo', isEqualTo: true);
    } else if (filtro == 'inativos') {
      doacoesQuery = doacoesQuery.where('ativo', isEqualTo: false);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Doações',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔹 Botões de filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _botaoFiltro("Ativos", "ativos", Colors.green),
                _botaoFiltro("Inativos", "inativos", Colors.redAccent),
                _botaoFiltro("Todos", "todos", Colors.blueGrey),
              ],
            ),
          ),

          // 🔹 Botão de cadastro
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/criarDoacao');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Cadastrar Produto', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 🔹 Lista de doações
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: doacoesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma doação encontrada.', style: TextStyle(fontSize: 16)),
                  );
                }

                final doacoes = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  DateTime? validade;
                  try {
                    validade = DateFormat("dd/MM/yyyy").parse(data['validade'] ?? '');
                  } catch (_) {}
                  return {
                    'id': doc.id,
                    ...data,
                    'validadeDate': validade,
                  };
                }).toList();

                doacoes.sort((a, b) {
                  final va = a['validadeDate'];
                  final vb = b['validadeDate'];
                  if (va == null && vb == null) return 0;
                  if (va == null) return 1;
                  if (vb == null) return -1;
                  return va.compareTo(vb);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: doacoes.length,
                  itemBuilder: (context, index) {
                    final data = doacoes[index];
                    final titulo = data['titulo'] ?? '';
                    final quantidade = data['quantidade']?.toString() ?? '';
                    final unidade = data['unidade'] ?? '';
                    final validadeStr = data['validade'] ?? '';
                    final validade = data['validadeDate'];
                    final ativo = data['ativo'] ?? true;

                    bool alertaAmarelo = false;
                    bool alertaVermelho = false;
                    if (validade != null) {
                      alertaAmarelo = _isNearExpiration(validade, 15);
                      alertaVermelho = _isNearExpiration(validade, 7);
                    }

                    return Stack(
                      children: [
                        Card(
                          color: ativo ? const Color(0xFFB2F0DC) : Colors.grey[300],
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: ListTile(
                            onTap: () => _editarProduto(context, data['id'], data),
                            title: Text(
                              titulo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: ativo ? Colors.black : Colors.black54,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text("Qtd: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text("$quantidade $unidade"),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Text("Validade: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(validadeStr),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (alertaAmarelo && !alertaVermelho)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 28),
                          ),
                        if (alertaVermelho)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(Icons.error, color: Colors.red, size: 28),
                          ),
                      ],
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

  // 🔹 Widget auxiliar para criar botões de filtro
  Widget _botaoFiltro(String texto, String valor, Color cor) {
    final bool ativo = filtro == valor;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => setState(() => filtro = valor),
          style: ElevatedButton.styleFrom(
            backgroundColor: ativo ? cor : Colors.grey[300],
            foregroundColor: ativo ? Colors.white : Colors.black87,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(
            texto,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
