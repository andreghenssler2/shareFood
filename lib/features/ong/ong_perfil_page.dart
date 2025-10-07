import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../auth/services/ong_service.dart';

class OngPerfilPage extends StatefulWidget {
  const OngPerfilPage({super.key});

  @override
  State<OngPerfilPage> createState() => _OngPerfilPageState();
}

class _OngPerfilPageState extends State<OngPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = OngService();

  final _nomeController = TextEditingController();
  final _responsavelController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();

  User? user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _cnpjBloqueado = false;

  final cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
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
    final dados = await _service.buscarPerfil(user!.uid);

    if (dados != null) {
      _nomeController.text = dados['nome'] ?? '';
      _responsavelController.text = dados['responsavel'] ?? '';
      _cnpjController.text = dados['cnpj'] ?? '';
      _telefoneController.text = dados['telefone'] ?? '';
      _ruaController.text = dados['endereco']?['rua'] ?? '';
      _numeroController.text = dados['endereco']?['numero'] ?? '';
      _cidadeController.text = dados['endereco']?['cidade'] ?? '';
      _ufController.text = dados['endereco']?['uf'] ?? '';

      if (dados['cnpj'] != null && dados['cnpj'].toString().isNotEmpty) {
        _cnpjBloqueado = true;
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate() || user == null) return;

    final dados = {
      'uid': user!.uid,
      'email': user!.email,
      'nome': _nomeController.text.trim(),
      'responsavel': _responsavelController.text.trim(),
      'cnpj': _cnpjController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'endereco': {
        'rua': _ruaController.text.trim(),
        'numero': _numeroController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'uf': _ufController.text.trim().toUpperCase(),
      },
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    await _service.salvarPerfil(user!.uid, dados);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil da ONG atualizado com sucesso!')),
    );

    setState(() {
      _isEditing = false;
      _cnpjBloqueado = true;
    });
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
        backgroundColor: const Color(0xFF002AB3),
        title: const Text(
          'Meu Perfil da ONG',
          style: TextStyle(color: Colors.white),
        ),
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
                label: 'Nome da ONG',
                controller: _nomeController,
                enabled: _isEditing,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome da ONG' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Responsável',
                controller: _responsavelController,
                enabled: _isEditing,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o responsável' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cnpjController,
                inputFormatters: [cnpjMask],
                enabled: _isEditing && !_cnpjBloqueado,
                decoration: InputDecoration(
                  labelText: 'CNPJ',
                  border: const OutlineInputBorder(),
                  suffixIcon: _cnpjBloqueado
                      ? const Icon(Icons.lock, color: Colors.grey)
                      : null,
                  filled: !_isEditing || _cnpjBloqueado,
                  fillColor:
                      !_isEditing || _cnpjBloqueado ? Colors.grey.shade100 : null,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o CNPJ';
                  if (v.length < 18) return 'CNPJ incompleto';
                  return null;
                },
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
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe a UF';
                  if (v.length != 2) return 'UF deve ter 2 letras';
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
