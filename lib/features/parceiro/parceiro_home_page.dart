import 'package:flutter/material.dart';
// import 'parceiro_painel_page.dart'; // tela principal do painel do parceiro
// import '../home/home_page.dart'; // para voltar ao menu principal
import 'parceiro_criar_doacao_page.dart'; // tela de criar doação
import 'parceiro_perfil_page.dart'; // tela de perfil do parceiro

class ParceiroHomePage extends StatelessWidget {
  const ParceiroHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(158, 13, 0, 1),
        title: const Text(
          'Painel do Parceiro',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // 🔹 Drawer (menu lateral)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromRGBO(185, 55, 43, 100),
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

            // 🔸 Itens do menu do parceiro
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
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Minhas Doações'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de Doações'),
              onTap: () {},
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

      // 🔸 Corpo principal do painel
      body: const Center(
        child: Text(
          'Bem-vindo ao Painel do Parceiro 🏪',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
