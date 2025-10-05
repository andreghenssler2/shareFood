import 'package:flutter/material.dart';
import '../auth/services/auth_service.dart';
import '../ong/ong_home_page.dart'; // ✅ importa a tela principal do menu da ONG

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text('ShareFood')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'ShareFood',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fastfood),
              title: const Text('Minhas Doações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/my-donations');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Criar Doação'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/create-donation');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Meu Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),

            // 🟩 Novo item: Painel da ONG
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Painel da ONG'),
              onTap: () {
                Navigator.pop(context); // fecha o Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OngHomePage(), // ✅ abre o menu da ONG
                  ),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair'),
              onTap: () async {
                await authService.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Bem-vindo ao ShareFood! 🎉\nEscolha uma opção no menu lateral.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
