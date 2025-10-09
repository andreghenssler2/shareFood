import 'package:flutter/material.dart';

class OngDetalhesPage extends StatelessWidget {
  final Map<String, dynamic> ongData;

  const OngDetalhesPage({required this.ongData, super.key});

  @override
  Widget build(BuildContext context) {
    final endereco = ongData['endereco'] ?? {};
    final nome = ongData['nome'] ?? 'ONG sem nome';
    final email = ongData['email'] ?? 'Não informado';
    final cnpj = ongData['cnpj'] ?? 'Não informado';
    final cidade = endereco['cidade'] ?? '';
    final rua = endereco['rua'] ?? '';
    final numero = endereco['numero'] ?? '';
    final uf = endereco['uf'] ?? '';
    final atualizadoEm = ongData['atualizadoEm'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(nome),
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$rua, $numero - $cidade / $uf',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  children: [
                    const Icon(Icons.email, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(email),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.badge, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text('CNPJ: $cnpj'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Atualizado em: $atualizadoEm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
