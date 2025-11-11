import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'parceiro_home_page.dart';
import '../auth/services/parceiro_service.dart';

class ParceiroPerfilPage extends StatefulWidget {
  final String uid;

  const ParceiroPerfilPage({super.key, required this.uid});

  @override
  State<ParceiroPerfilPage> createState() => _ParceiroPerfilPageState();
}

class _ParceiroPerfilPageState extends State<ParceiroPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = ParceiroService();

  final _nomeController = TextEditingController();
  final _empresaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _cnpjBloqueado = false;

  final cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  //  Máscaras para telefone (8 e 9 dígitos)
  final telefoneMask8 = MaskTextInputFormatter(
    mask: '(##) ####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final telefoneMask9 = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  MaskTextInputFormatter get _telefoneMask {
    final numeros = _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return numeros.length > 10 ? telefoneMask9 : telefoneMask8;
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final dados = await _service.buscarPerfil(widget.uid);

    if (dados != null) {
      _nomeController.text = dados['nome'] ?? '';
      _empresaController.text = dados['empresa'] ?? '';
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
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final dados = {
      'uid': user.uid,
      'email': user.email,
      'nome': _nomeController.text.trim(),
      'empresa': _empresaController.text.trim(),
      'cnpj': _cnpjController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'endereco': {
        'rua': _ruaController.text.trim(),
        'numero': _numeroController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'uf': _ufController.text.trim(),
      },
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('parceiros')
          .doc(widget.uid)
          .set(dados, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParceiroHomePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
          _cnpjBloqueado = true;
        });
      }
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
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
        title: const Text(
          'Meu Perfil',
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
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Nome da Empresa / Estabelecimento',
                controller: _empresaController,
                enabled: _isEditing,
                validator: (v) => v == null || v.isEmpty
                    ? 'Informe o nome da empresa'
                    : null,
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
                  fillColor: !_isEditing || _cnpjBloqueado
                      ? Colors.grey.shade100
                      : null,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o CNPJ';
                  if (v.length < 18) return 'CNPJ incompleto';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //  Telefone com máscara dinâmica
              TextFormField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_telefoneMask],
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o telefone';
                  final numeros =
                      v.replaceAll(RegExp(r'[^0-9]'), '');
                  if (numeros.length < 10 || numeros.length > 11) {
                    return 'Telefone inválido';
                  }
                  return null;
                },
                onChanged: (value) {
                  final numeros =
                      value.replaceAll(RegExp(r'[^0-9]'), '');
                  final novaMascara =
                      numeros.length > 10 ? telefoneMask9 : telefoneMask8;

                  if (_telefoneMask.getMask() != novaMascara.getMask()) {
                    final textoAtual = _telefoneController.text;
                    final pos = _telefoneController.selection;
                    setState(() {
                      _telefoneController.value = TextEditingValue(
                        text: novaMascara.maskText(textoAtual),
                        selection: pos,
                      );
                    });
                  }
                },
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
                  onPressed: _isLoading ? null : _salvarPerfil,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Salvar Alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

              const SizedBox(height: 16),

              Text(
                'UID: ${widget.uid}',
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
