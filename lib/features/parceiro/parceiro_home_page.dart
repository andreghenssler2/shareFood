import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'parceiro_criar_doacao_page.dart';
import 'doacoes_parceiro_page.dart';
import 'parceiro_perfil_page.dart';
import 'parceiro_ongs_page.dart';
import 'historico_pedidos_page.dart';

import '../auth/pages/login_page.dart';

class ParceiroHomePage extends StatefulWidget {
  const ParceiroHomePage({super.key});

  @override
  State<ParceiroHomePage> createState() => _ParceiroHomePageState();
}

class _ParceiroHomePageState extends State<ParceiroHomePage> {
  final user = FirebaseAuth.instance.currentUser;
  String nome = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          nome = doc.data()?['nome'] ?? 'Parceiro';
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar nome do parceiro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
        title: const Text(
          'Painel do Parceiro',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ===================== DRAWER =====================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(185, 55, 43, 1),
              ),
              accountName: Text(
                nome.isNotEmpty ? nome : 'Parceiro',
                style: const TextStyle(fontSize: 20),
              ),
              accountEmail: Text(user!.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.store, size: 40, color: Colors.red),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Criar Doação'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ParceiroCriarDoacaoPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Minhas Doações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DoacoesParceiroPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Lista de ONGs'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final uid = user!.uid;
                  final doc = await FirebaseFirestore.instance
                      .collection('parceiros')
                      .doc(uid)
                      .get();

                  if (!doc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro: parceiro não encontrado!')),
                    );
                    return;
                  }

                  final endereco = doc.data()?['endereco'];
                  final parceiroCidade = endereco?['cidade'] ?? '';
                  final parceiroUF = endereco?['uf'] ?? '';

                  if (parceiroCidade.isEmpty || parceiroUF.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cidade ou UF do parceiro não definidos!')),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OngListPage(
                        parceiroCidade: parceiroCidade,
                        parceiroUF: parceiroUF,
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao carregar ONGs: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de Doações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoricoPedidosPage()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Meu Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParceiroPerfilPage(uid: user!.uid),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  
                  MaterialPageRoute(builder: (_) => const LoginPage());
                  // (route) => false, // Remove todas as rotas anteriores// Remove todas as rotas anteriores
                }
              },
            ), 
          ],
        ),
      ),

      // ===================== BODY =====================
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('doacoes')
              .where('parceiroId', isEqualTo: user!.uid)
              .where('ativo', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Nenhuma doação próxima do vencimento.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            final List<Map<String, dynamic>> proximasDoacoes = [];

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final titulo = data['titulo'] ?? 'Sem nome';
              final validadeStr = data['validade'] ?? '';

              try {
                final validade = DateFormat("dd/MM/yyyy").parse(validadeStr);
                final hoje = DateTime.now();
                final diffDays = validade.difference(hoje).inDays;

                if (diffDays <= 15) {
                  proximasDoacoes.add({
                    'titulo': titulo,
                    'validade': validadeStr,
                    'dias': diffDays,
                  });
                }
              } catch (_) {}
            }
            

            if (proximasDoacoes.isEmpty) {
              return const Center(
                child: Text(
                  'Nenhuma doação próxima do vencimento.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            proximasDoacoes.sort((a, b) => a['dias'].compareTo(b['dias']));

            return ListView.builder(
              itemCount: proximasDoacoes.length,
              itemBuilder: (context, index) {
                final item = proximasDoacoes[index];
                final titulo = item['titulo'];
                final validade = item['validade'];
                final dias = item['dias'];

                Color bgColor;
                Color iconColor;

                if (dias <= 1) {
                  bgColor = const Color(0xFF800000); // Bordô forte
                  iconColor = Colors.white;
                } else if (dias <= 7) {
                  bgColor = Colors.red.shade300;
                  iconColor = Colors.red.shade900;
                } else if (dias <= 15) {
                  bgColor = Colors.yellow.shade200;
                  iconColor = Colors.orange.shade800;
                } else {
                  bgColor = Colors.white;
                  iconColor = Colors.grey;
                }

                return Card(
                  color: bgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded,
                        color: iconColor, size: 32),
                    title: Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: dias <= 1 ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Validade: $validade\nRestam: ${dias < 0 ? 0 : dias} dias',
                      style: TextStyle(
                        color: dias <= 1 ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
