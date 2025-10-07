import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'ong_painel_page.dart';
import 'ong_perfil_page.dart';

class OngHomePage extends StatelessWidget {
  const OngHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green, // ou a cor do seu tema
        title: const Text(
          'Painel da ONG',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'ShareFord\nMenu da ONG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Doações Disponíveis'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OngPainelPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Doações Recebidas'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person),
              // title: const Text('Perfil da ONG'),
              // leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Perfil da ONG'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OngPerfilPage()),
                );
              },
            ),

            const Divider(),

            
            // ListTile(
            //   leading: const Icon(Icons.arrow_back),
            //   title: const Text('Voltar para o Menu Principal'),
            //   onTap: () {
            //     Navigator.pop(context); // fecha o Drawer
            //     Navigator.pop(context); // volta para a Home
            //   },
            // ),

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
      body: const Center(
        child: Text(
          'Bem-vindo ao Painel da ONG 🎉',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
