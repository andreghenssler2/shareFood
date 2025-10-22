import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../auth/services/ong_service.dart';
import '../ong/ong_home_page.dart';

// 🔹 Função para gerar uma cor única e consistente baseada no UID
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

class OngPerfilPage extends StatefulWidget {
  final String uid;

  const OngPerfilPage({super.key, required this.uid});

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

  // ✅ Máscara CNPJ
  final cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // ✅ Máscaras de telefone
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
    user = FirebaseAuth.instance.currentUser;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (user == null) return;
    final dados = await _service.buscarPerfil(widget.uid);

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

      // ✅ Se a ONG ainda não tiver cor, cria automaticamente
      if (dados['corOng'] == null) {
        final novaCor = _gerarCorUnica(widget.uid);
        await _service.salvarPerfil(widget.uid, {'corOng': novaCor.value});
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate() || user == null) return;

    // 🔹 Busca cor existente (ou gera uma nova se não existir)
    final perfilAtual = await _service.buscarPerfil(widget.uid);
    final corOng = perfilAtual?['corOng'] ?? _gerarCorUnica(widget.uid).value;

    final dados = {
      'uid': widget.uid,
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
      'corOng': corOng, // ✅ Cor dinâmica
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    try {
      await _service.salvarPerfil(widget.uid, dados);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil da ONG atualizado com sucesso!')),
      );

      setState(() {
        _isEditing = false;
        _cnpjBloqueado = true;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OngHomePage()),
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
        backgroundColor: Colors.green,
        title: const Text(
          'Meu Perfil da ONG',
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

              // ✅ TELEFONE COM MÁSCARA DINÂMICA
              TextFormField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_telefoneMask],
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                  hintText: '(51) 99999-9999',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o telefone';
                  final numeros = v.replaceAll(RegExp(r'[^0-9]'), '');
                  if (numeros.length < 10 || numeros.length > 11) {
                    return 'Telefone inválido';
                  }
                  return null;
                },
                onChanged: (value) {
                  final numeros = value.replaceAll(RegExp(r'[^0-9]'), '');
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
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Salvar Alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
