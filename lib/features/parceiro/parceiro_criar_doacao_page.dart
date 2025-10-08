import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParceiroCriarDoacaoPage extends StatefulWidget {
  const ParceiroCriarDoacaoPage({super.key});

  @override
  State<ParceiroCriarDoacaoPage> createState() => _ParceiroCriarDoacaoPageState();
}

class _ParceiroCriarDoacaoPageState extends State<ParceiroCriarDoacaoPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _validadeController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();

  String? _unidadeSelecionada;
  bool _isLoading = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _quantidadeController.dispose();
    _validadeController.dispose();
    _marcaController.dispose();
    super.dispose();
  }

  Future<void> _criarDoacao() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    // 🔎 Verificação de autenticação
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: usuário não autenticado!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔎 UID do parceiro logado: ${user.uid}');

      await FirebaseFirestore.instance.collection('doacoes').add({
        'titulo': _tituloController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'quantidade': int.parse(_quantidadeController.text),
        'unidade': _unidadeSelecionada,
        'marca': _marcaController.text.trim(),
        'validade': _validadeController.text.trim(),
        'criadoEm': FieldValue.serverTimestamp(),
        'parceiroId': user.uid, // ✅ garante vinculação correta
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doação criada com sucesso! 🎉')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar doação: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Criar Doação - Parceiro',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Preencha as informações da doação:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // 🟦 Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o título' : null,
              ),
              const SizedBox(height: 16),

              // 🟦 Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 16),

              // 🟦 Quantidade
              TextFormField(
                controller: _quantidadeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe a quantidade' : null,
              ),
              const SizedBox(height: 16),

              // 🟦 Unidade
              DropdownButtonFormField<String>(
                value: _unidadeSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Unidade',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                  DropdownMenuItem(value: 'Litros', child: Text('Litros')),
                  DropdownMenuItem(value: 'Unidade', child: Text('Unidade')),
                ],
                onChanged: (value) => setState(() {
                  _unidadeSelecionada = value;
                }),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Selecione a unidade' : null,
              ),
              const SizedBox(height: 16),

              // 🟩 Marca
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe a marca' : null,
              ),
              const SizedBox(height: 16),

              // 🟩 Validade
              TextFormField(
                controller: _validadeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Validade',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _validadeController.text =
                        '${date.day}/${date.month}/${date.year}';
                  }
                },
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe a validade' : null,
              ),
              const SizedBox(height: 30),

              // 🟦 Botão Criar
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _isLoading ? 'Salvando...' : 'Criar Doação',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 42, 179),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _isLoading ? null : _criarDoacao,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
