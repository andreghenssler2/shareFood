import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/services/parceiro_service.dart';

class ParceiroPerfilPage extends StatefulWidget {
  const ParceiroPerfilPage({super.key});

  @override
  State<ParceiroPerfilPage> createState() => _ParceiroPerfilPageState();
}

class _ParceiroPerfilPageState extends State<ParceiroPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = ParceiroService();

  final _nomeController = TextEditingController();
  final _empresaController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();

  User? user;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (user == null) return;
    final dados = await _service.buscarPerfil(user!.uid);

    if (dados != null) {
      _nomeController.text = dados['nome'] ?? '';
      _empresaController.text = dados['empresa'] ?? '';
      _telefoneController.text = dados['telefone'] ?? '';
      _ruaController.text = dados['endereco']?['rua'] ?? '';
      _numeroController.text = dados['endereco']?['numero'] ?? '';
      _cidadeController.text = dados['endereco']?['cidade'] ?? '';
      _ufController.text = dados['endereco']?['uf'] ?? '';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate() || user == null) return;

    final dados = {
      'uid': user!.uid,
      'email': user!.email,
      'nome': _nomeController.text,
      'empresa': _empresaController.text,
      'telefone': _telefoneController.text,
      'endereco': {
        'rua': _ruaController.text,
        'numero': _numeroController.text,
        'cidade': _cidadeController.text,
        'uf': _ufController.text,
      },
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    await _service.salvarPerfil(user!.uid, dados);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso!')),
    );

    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
// appBar: AppBar(
      //   backgroundColor: Color.fromRGBO(158, 13, 0, 1),
      //   title: const Text(
      //     'Painel do Parceiro',
      //     style: TextStyle(color: Colors.white),
      //   ),
      //   iconTheme: const IconThemeData(color: Colors.white),
      // ),
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil',style: TextStyle(color: Colors.white),),
        backgroundColor: Color.fromRGBO(158, 13, 0, 1),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit, color: Colors.white),
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
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Nome da Empresa / Estabelecimento',
                controller: _empresaController,
                enabled: _isEditing,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome da empresa' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Telefone',
                controller: _telefoneController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              const Text(
                'Endereço',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildTextField(
                label: 'Rua',
                controller: _ruaController,
                enabled: _isEditing,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                label: 'Número',
                controller: _numeroController,
                enabled: _isEditing,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                label: 'Cidade',
                controller: _cidadeController,
                enabled: _isEditing,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                label: 'UF',
                controller: _ufController,
                enabled: _isEditing,
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),

              if (_isEditing)
                ElevatedButton.icon(
                  onPressed: _salvarPerfil,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar Alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
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
