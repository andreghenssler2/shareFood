import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'admin_dashboard_page.dart';
import '../auth/services/admin_service.dart';

class AdminPerfilPage extends StatefulWidget {
  final String uid;

  const AdminPerfilPage({super.key, required this.uid});

  @override
  State<AdminPerfilPage> createState() => _AdminPerfilPageState();
}

class _AdminPerfilPageState extends State<AdminPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = AdminService();

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _celularController = TextEditingController();

  User? user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _cpfBloqueado = false;

  // ✅ Máscara CPF
  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // ✅ Máscara Telefone
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
    final dados = await _service.buscarPerfil(widget.uid);
    if (dados != null) {
      _nomeController.text = dados['nome'] ?? '';
      _cpfController.text = dados['cpf'] ?? '';
      _celularController.text = dados['celular'] ?? '';

      if (dados['cpf'] != null && dados['cpf'].toString().isNotEmpty) {
        _cpfBloqueado = true;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate() || user == null) return;

    try {
      // 🔹 Verifica se CPF já existe
      final query = await FirebaseFirestore.instance
          .collection('admin')
          .where('cpf', isEqualTo: _cpfController.text.trim())
          .get();

      if (query.docs.isNotEmpty && !_cpfBloqueado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este CPF já está cadastrado.')),
        );
        return;
      }

      final dados = {
        'uid': widget.uid,
        'email': user!.email,
        'nome': _nomeController.text.trim(),
        'cpf': _cpfController.text.trim(),
        'celular': _celularController.text.trim(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      await _service.salvarPerfil(widget.uid, dados);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil do Admin atualizado com sucesso!')),
      );

      setState(() {
        _isEditing = false;
        _cpfBloqueado = true;
      });

      // ✅ Redireciona para tela principal
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
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
        backgroundColor: Colors.indigo,
        title: const Text(
          'Meu Perfil de Admin',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.cancel : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
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
                label: 'Nome Completo',
                controller: _nomeController,
                enabled: _isEditing,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome completo' : null,
              ),
              const SizedBox(height: 16),

              // ✅ CPF formatado e único
              TextFormField(
                controller: _cpfController,
                inputFormatters: [cpfMask],
                enabled: _isEditing && !_cpfBloqueado,
                keyboardType: TextInputType.number,
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

              // ✅ Telefone formatado
              TextFormField(
                controller: _celularController,
                inputFormatters: [telefoneMask],
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Celular',
                  border: OutlineInputBorder(),
                  hintText: '(51) 99999-9999',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o celular';
                  if (v.length < 15) return 'Celular incompleto';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              if (_isEditing)
                ElevatedButton.icon(
                  onPressed: _salvarPerfil,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar Alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
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
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
