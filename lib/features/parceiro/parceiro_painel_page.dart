import 'package:flutter/material.dart';

class ParceiroPainelPage extends StatelessWidget {
  const ParceiroPainelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(185, 55, 43, 100), // ou a cor do seu tema
        title: const Text(
          'Criar Doação',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text(
          'Página de criação de doações do Parceiro',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
