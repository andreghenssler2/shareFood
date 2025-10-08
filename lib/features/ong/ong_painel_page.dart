// lib/features/ong/ong_painel_page.dart
import 'package:flutter/material.dart';

class OngPainelPage extends StatelessWidget {
  const OngPainelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel da ONG'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Bem-vindo ao Painel da ONG!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
