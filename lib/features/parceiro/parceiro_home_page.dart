import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'parceiro_criar_doacao_page.dart';
import 'doacoes_parceiro_page.dart';
import 'parceiro_perfil_page.dart';
import 'parceiro_ongs_page.dart'; // ✅ tela de listagem de ONGs

class ParceiroHomePage extends StatelessWidget {
  const ParceiroHomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // <-- ADICIONE ESTA LINHA
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

      // 🔹 Menu lateral (Drawer)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromRGBO(185, 55, 43, 1),
              ),
              child: Text(
                'ShareFood\nMenu do Parceiro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
             // 🏠 Home
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ParceiroHomePage()),
                );
              },
            ),
            // 🟩 Criar Doação
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Criar Doação'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParceiroCriarDoacaoPage(),
                  ),
                );
              },
            ),

            // 🟦 Minhas Doações
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Minhas Doações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoacoesParceiroPage(),
                  ),
                );
              },
            ),

            // 🟨 Lista de ONGs
            ListTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Lista de ONGs'),
              onTap: () async {
                Navigator.pop(context); // fecha o menu

                try {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro: parceiro não autenticado!')),
                    );
                    return;
                  }

                  // 🔎 Busca dados do parceiro
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
                      const SnackBar(content: Text('Erro: cidade ou UF do parceiro não definidos!')),
                    );
                    return;
                  }

                  // 🚀 Abre a tela de ONGs
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

            // 🕓 Histórico
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de Doações'),
              onTap: () {},
            ),

            const Divider(),

            // 👤 Perfil
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Meu Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParceiroPerfilPage(),
                  ),
                );
              },
            ),

            // 🚪 Sair
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),

      // 🔸 Corpo principal
      // body: const Center(
      //   child: Text(
      //     'Bem-vindo ao Painel do Parceiro 🏪',
      //     style: TextStyle(fontSize: 18),
      //   ),
      // ),
      body: user == null
    ? const Center(
        child: Text('Usuário não autenticado.'),
      )
    : Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('doacoes')
              .where('parceiroId', isEqualTo: user.uid)
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

            final doacoes = snapshot.data!.docs;
            final proximasDoacoes = <Map<String, dynamic>>[];

            for (var doc in doacoes) {
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
              } catch (_) {
                // ignora datas inválidas
              }
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
              padding: const EdgeInsets.all(12),
              itemCount: proximasDoacoes.length,
              itemBuilder: (context, index) {
                final item = proximasDoacoes[index];
                final titulo = item['titulo'];
                final validade = item['validade'];
                final dias = item['dias'];

                IconData icon;
                Color iconColor;

                if (dias <= 7) {
                  icon = Icons.error_outline;
                  iconColor = Colors.red;
                } else {
                  icon = Icons.warning_amber_rounded;
                  iconColor = Colors.orange;
                }

                return Card(
                  color: const Color(0xFFF8F8F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(icon, color: iconColor, size: 30),
                    title: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Validade: $validade\nRestam: ${dias < 0 ? 0 : dias} dias',
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
