import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class OngDetalhesPage extends StatelessWidget {
  final String ongId;

  const OngDetalhesPage({required this.ongId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes da ONG',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔹 muda a cor da seta para branca
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('ongs').doc(ongId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar os detalhes da ONG.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ONG não encontrada.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final endereco = data['endereco'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: const Color(0xFFF9F4F4),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🏷️ Nome da ONG
                    Text(
                      data['nome'] ?? 'Sem nome',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(158, 13, 0, 1),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 👤 Responsável
                    _infoRow('Responsável', data['responsavel']),
                    const SizedBox(height: 8),

                    // 📧 Email
                    _infoRow('E-mail', data['email']),
                    const SizedBox(height: 8),

                    // ☎️ Telefone
                    _infoRow('Telefone', data['telefone']),
                    const SizedBox(height: 8),

                    // 🏙️ Endereço completo
                    const Divider(height: 24, thickness: 1),
                    const Text(
                      'Endereço',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(158, 13, 0, 1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${endereco['rua'] ?? ''}, ${endereco['numero'] ?? ''}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${endereco['cidade'] ?? ''} - ${endereco['uf'] ?? ''}',
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 16),
                    // 🆔 CNPJ
                    if (data['cnpj'] != null)
                      _infoRow('CNPJ', data['cnpj']),
                    const SizedBox(height: 16),

                    // 🕓 Atualizado em (formatado)
                    if (data['atualizadoEm'] != null)
                      _infoRow(
                        'Atualizado em',
                        _formatarData(data['atualizadoEm']),
                      ),

                    const SizedBox(height: 24),
                    const Divider(height: 24),

                    // 🔘 Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // 👉 Substitua pela rota da página de doações da ONG
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Função "Ver Doações" ainda não implementada.',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(158, 13, 0, 1),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.volunteer_activism,
                                color: Colors.white),
                            label: const Text(
                              'Ver Doações',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final telefone = data['telefone'];
                              if (telefone != null && telefone.isNotEmpty) {
                                final uri = Uri.parse(
                                  'https://wa.me/55${telefone.replaceAll(RegExp(r'[^0-9]'), '')}',
                                );
                                launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Número de telefone não disponível.'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon:
                               const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),

                            label: const Text(
                              'WhatsApp',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Exibe campo formatado
  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Formata Timestamp (Firestore) em DD/MM/AAAA às HH:mm
  String _formatarData(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final dateTime = timestamp.toDate();
        return '${dateTime.day.toString().padLeft(2, '0')}/'
            '${dateTime.month.toString().padLeft(2, '0')}/'
            '${dateTime.year} às '
            '${dateTime.hour.toString().padLeft(2, '0')}:'
            '${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return timestamp.toString();
    } catch (_) {
      return '-';
    }
  }
}
