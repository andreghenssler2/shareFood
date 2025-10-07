import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class OngPerfilPage extends StatefulWidget {
  const OngPerfilPage({super.key});

  @override
  State<OngPerfilPage> createState() => _OngPerfilPageState();
}

class _OngPerfilPageState extends State<OngPerfilPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();

  bool cnpjBloqueado = false;

  final cnpjMask = MaskTextInputFormatter(mask: '##.###.###/####-##');
  final telefoneMask = MaskTextInputFormatter(mask: '(##) #####-####');

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('ongs').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nomeController.text = data['nome'] ?? '';
      _telefoneController.text = data['telefone'] ?? '';
      _cnpjController.text = data['cnpj'] ?? '';
      _ruaController.text = data['rua'] ?? '';
      _numeroController.text = data['numero'] ?? '';
      _cidadeController.text = data['cidade'] ?? '';
      _ufController.text = data['uf'] ?? '';
      if (_cnpjController.text.isNotEmpty) {
        setState(() => cnpjBloqueado = true);
      }
    }
  }

  Future<void> salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('ongs').doc(user!.uid).set({
      'uid': user!.uid,
      'email': user!.email,
      'nome': _nomeController.text,
      'telefone': _telefoneController.text,
      'cnpj': _cnpjController.text,
      'rua': _ruaController.text,
      'numero': _numeroController.text,
      'cidade': _cidadeController.text,
      'uf': _ufController.text.toUpperCase(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil salvo com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil da ONG', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome da ONG'),
                validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                inputFormatters: [telefoneMask],
                validator: (v) => v!.isEmpty ? 'Informe o telefone' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cnpjController,
                decoration: const InputDecoration(labelText: 'CNPJ'),
                inputFormatters: [cnpjMask],
                enabled: !cnpjBloqueado,
                validator: (v) => v!.isEmpty ? 'Informe o CNPJ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ruaController,
                decoration: const InputDecoration(labelText: 'Rua'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(labelText: 'Número'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cidadeController,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ufController,
                decoration: const InputDecoration(labelText: 'UF'),
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.length != 2 ? 'UF deve ter 2 letras' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: salvarPerfil,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  'Salvar',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
