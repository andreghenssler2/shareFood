import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ong_perfil_page.dart';
import 'ong_doacoes_page.dart';
import 'd_OngParceirosListPage.dart';
import 'ong_doacoes_recebidas_page.dart';

class OngHomePage extends StatelessWidget {
  const OngHomePage({super.key});


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Painel da ONG',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.green,
              ),
              accountName: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('ongs')
                    .doc(user?.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text('Carregando...');
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  return Text(
                    data?['nome'] ?? 'ONG sem nome',
                    style: const TextStyle(fontSize: 18),
                  );
                },
              ),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.volunteer_activism, color: Colors.green, size: 36),
              ),
            ),

            // Doações Disponíveis
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Doações Disponíveis'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OngDoacoesPage(),
                  ),
                );
              },
            ),

            // Carrinho (opcionalmente redireciona para mesma tela)
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Carrinho'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OngDoacoesPage(),
                  ),
                );
              },
            ),

            // Doações Recebidas
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Doações Recebidas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OngDoacoesRecebidasPage(),
                  ),
                );
              },
            ),

            // Lista de Parceiros
            ListTile(
              leading: const Icon(Icons.store_mall_directory),
              title: const Text('Lista de Parceiros'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro: ONG não autenticada!'),
                      ),
                    );
                    return;
                  }

                  final doc = await FirebaseFirestore.instance
                      .collection('ongs')
                      .doc(uid)
                      .get();

                  if (!doc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro: ONG não encontrada!'),
                      ),
                    );
                    return;
                  }

                  final endereco = doc.data()?['endereco'];
                  final ongCidade = endereco?['cidade'] ?? '';
                  final ongUF = endereco?['uf'] ?? '';

                  if (ongCidade.isEmpty || ongUF.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Erro: cidade ou UF da ONG não definidos!'),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OngParceirosListPage(
                        ongCidade: ongCidade,
                        ongUF: ongUF,
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao carregar parceiros: $e')),
                  );
                }
              },
            ),

            // Perfil da ONG
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil da ONG'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OngPerfilPage(uid: user!.uid),
                  ),
                );
              },
            ),

            const Divider(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Bem-vindo ao Painel da ONG 🎉',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
