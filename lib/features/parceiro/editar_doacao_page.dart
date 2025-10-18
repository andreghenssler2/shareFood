import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditarDoacaoPage extends StatefulWidget {
  final Map<String, dynamic> doacao;

  const EditarDoacaoPage({super.key, required this.doacao});

  @override
  State<EditarDoacaoPage> createState() => _EditarDoacaoPageState();
}

class _EditarDoacaoPageState extends State<EditarDoacaoPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _tituloController;
  late TextEditingController _quantidadeController;
  late TextEditingController _validadeController;
  late TextEditingController _marcaController;

  String _unidadeSelecionada = 'Kg';
  bool _ativo = true;
  // File? _imagemSelecionada;
  bool _salvando = false;

  final unidades = ['Kg', 'Litros', 'Unidade'];

  @override
  void initState() {
    super.initState();
    final data = widget.doacao;
    _tituloController = TextEditingController(text: data['titulo']);
    _quantidadeController = TextEditingController(text: data['quantidade']?.toString());
    _validadeController = TextEditingController(text: data['validade']);
    _marcaController = TextEditingController(text: data['marca']);
    _unidadeSelecionada = data['unidade'] ?? 'Kg';
    _ativo = data['ativo'] ?? true;
  }


  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final docId = widget.doacao['id'];
      final imagemUrl = '';

      await FirebaseFirestore.instance.collection('doacoes').doc(docId).update({
        'titulo': _tituloController.text.trim(),
        'quantidade': double.tryParse(_quantidadeController.text) ?? 0,
        'validade': _validadeController.text.trim(),
        'marca': _marcaController.text.trim(),
        'unidade': _unidadeSelecionada,
        'imagem': imagemUrl,
        'ativo': _ativo,
        'ultimaAtualizacao': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final imagemUrl = widget.doacao['imagem'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Doação',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
        
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔹 muda a cor da seta para branca
        ),
        centerTitle: true,
      ),
      body: _salvando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                  
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título do Produto',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe o título' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _marcaController,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantidadeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantidade',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Informe a quantidade' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _unidadeSelecionada,
                            decoration: const InputDecoration(
                              labelText: 'Unidade',
                              border: OutlineInputBorder(),
                            ),
                            items: unidades
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _unidadeSelecionada = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _validadeController,
                      decoration: InputDecoration(
                        labelText: 'Validade (dd/MM/yyyy)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final dataAtual = DateTime.now();
                            final novaData = await showDatePicker(
                              context: context,
                              initialDate: dataAtual,
                              firstDate: dataAtual,
                              lastDate: DateTime(2100),
                            );
                            if (novaData != null) {
                              setState(() {
                                _validadeController.text =
                                    DateFormat('dd/MM/yyyy').format(novaData);
                              });
                            }
                          },
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe a validade' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Produto ativo'),
                      value: _ativo,
                      activeColor: Colors.green,
                      onChanged: (v) => setState(() => _ativo = v),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _salvarAlteracoes,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar alterações'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(158, 13, 0, 1),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
