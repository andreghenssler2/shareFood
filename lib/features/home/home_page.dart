import 'package:flutter/material.dart';
import '../auth/services/auth_service.dart';

// Telas principais por perfil
import '../ong/ong_home_page.dart';
import '../parceiro/parceiro_home_page.dart';
import '../admin/admin_dashboard_page.dart';

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

            // Itens padrão do usuário comum
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

            const Divider(),

            // Painel ONG
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Painel da ONG'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OngHomePage(),
                  ),
                );
              },
            ),

            // Painel Parceiro
            ListTile(
              leading: const Icon(Icons.store_mall_directory),
              title: const Text('Painel do Parceiro'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParceiroHomePage(),
                  ),
                );
              },
            ),

            // Painel do Administrador (novo)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Painel do Administrador'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboardPage(),
                  ),
                );
              },
            ),

            const Divider(),

            // Sair
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair'),
              onTap: () async {
                Navigator.pop(context);
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
