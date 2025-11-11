import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'admin_dashboard_page.dart';

Color _gerarCorUnica(String id) {
  final hash = id.codeUnits.fold(0, (a, b) => a + b);
  final random = Random(hash);
  return Color.fromARGB(
    255,
    100 + random.nextInt(156),
    100 + random.nextInt(156),
    100 + random.nextInt(156),
  );
}

class AdminPerfilPage extends StatefulWidget {
  final String uid;

  const AdminPerfilPage({super.key, required this.uid});

  @override
  State<AdminPerfilPage> createState() => _AdminPerfilPageState();
}

class _AdminPerfilPageState extends State<AdminPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final firestore = FirebaseFirestore.instance;

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _cpfBloqueado = false;

  User? user;

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (user == null) return;
    final doc = await firestore.collection('admin').doc(widget.uid).get();

    if (doc.exists) {
      final dados = doc.data()!;
      _nomeController.text = dados['nome'] ?? '';
      _cpfController.text = dados['cpf'] ?? '';
      _telefoneController.text = dados['telefone'] ?? '';

      if (_cpfController.text.isNotEmpty) _cpfBloqueado = true;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    // Valida CPF único
    final query = await firestore
        .collection('admin')
        .where('cpf', isEqualTo: _cpfController.text)
        .get();

    if (query.docs.isNotEmpty && !_cpfBloqueado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CPF já cadastrado para outro usuário.')),
      );
      return;
    }

    final dados = {
      'uid': widget.uid,
      'email': user?.email,
      'nome': _nomeController.text.trim(),
      'cpf': _cpfController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'corAdmin': _gerarCorUnica(widget.uid).value,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    try {
      await firestore.collection('admin').doc(widget.uid).set(dados);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );

      setState(() {
        _isEditing = false;
        _cpfBloqueado = true;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar perfil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        title: const Text('Meu Perfil - Administrador ',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.cancel : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                label: 'Nome do Administrador',
                controller: _nomeController,
                enabled: _isEditing,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cpfController,
                inputFormatters: [cpfMask],
                enabled: _isEditing && !_cpfBloqueado,
                decoration: InputDecoration(
                  labelText: 'CPF',
                  border: const OutlineInputBorder(),
                  suffixIcon: _cpfBloqueado
                      ? const Icon(Icons.lock, color: Colors.grey)
                      : null,
                  filled: !_isEditing || _cpfBloqueado,
                  fillColor:
                      !_isEditing || _cpfBloqueado ? Colors.grey.shade100 : null,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o CPF';
                  if (v.length < 14) return 'CPF incompleto';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [telefoneMask],
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Contato Celular',
                  hintText: '(51) 99999-9999',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o celular';
                  if (v.replaceAll(RegExp(r'[^0-9]'), '').length != 11) {
                    return 'Celular inválido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              if (_isEditing)
                ElevatedButton.icon(
                  onPressed: _salvarPerfil,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Salvar Alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              const SizedBox(height: 16),

              if (user?.email != null)
                Text(
                  'Email: ${user!.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
      validator: validator,
    );
  }
}
