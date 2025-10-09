import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OngDetalhesPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const OngDetalhesPage({required this.data, super.key});

  Future<void> _ligarParaOng(String telefone) async {
    final Uri uri = Uri(scheme: 'tel', path: telefone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Não foi possível abrir o discador.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final endereco = data['endereco'] ?? {};
    final nome = data['nome'] ?? 'ONG sem nome';
    final email = data['email'] ?? 'Sem e-mail';
    final telefone = endereco['telefone'] ?? data['telefone'] ?? 'Sem telefone';
    final cidade = endereco['cidade'] ?? 'Cidade não informada';
    final uf = endereco['uf'] ?? '';
    final rua = endereco['rua'] ?? '';
    final numero = endereco['numero'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(nome,style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.apartment, size: 48, color: Colors.redAccent),
                const SizedBox(height: 8),
                Text(
                  nome,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('E-mail: $email'),
                Text('Telefone: $telefone'),
                const SizedBox(height: 8),
                Text('Endereço: $rua, $numero'),
                Text('Cidade: $cidade - $uf'),
                const SizedBox(height: 16),

                if (telefone != 'Sem telefone')
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: const Text(
                        'Ligar para ONG',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _ligarParaOng(telefone),
                    ),
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Localização no mapa (em breve)',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
