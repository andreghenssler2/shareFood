import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sharefood/features/donations/services/donation_service.dart';
import 'package:sharefood/features/donations/models/donation_model.dart';
import 'package:sharefood/features/auth/services/auth_service.dart';

class CreateDonationPage extends StatefulWidget {
  const CreateDonationPage({super.key});

  @override
  State<CreateDonationPage> createState() => _CreateDonationPageState();
}

class _CreateDonationPageState extends State<CreateDonationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _unit = "kg";
  DateTime? _validity;

  final _donationService = DonationService();
  final _authService = AuthService();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _validity = picked);
  }

  Future<void> _saveDonation() async {
    if (_formKey.currentState!.validate() && _validity != null) {
      final user = _authService.currentUser!;
      final id = _donationService.generateId();

      final donation = Donation(
        id: id,
        userId: user.uid,
        name: _nameController.text.trim(),
        quantity: double.parse(_quantityController.text.trim()),
        unit: _unit,
        validity: _validity!,
        createdAt: DateTime.now(),
        status: "disponível",
      );

      await _donationService.addDonation(donation);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Doação criada com sucesso!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Doação')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do alimento',
                ),
                validator: (value) => value!.isEmpty ? 'Digite o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade'),
                validator: (value) =>
                    value!.isEmpty ? 'Digite a quantidade' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _unit,
                items: const [
                  DropdownMenuItem(value: "kg", child: Text("Quilo (kg)")),
                  DropdownMenuItem(value: "unid", child: Text("Unidade")),
                  DropdownMenuItem(value: "cx", child: Text("Caixa")),
                ],
                onChanged: (val) => setState(() => _unit = val!),
                decoration: const InputDecoration(labelText: "Unidade"),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _validity == null
                          ? 'Validade: não escolhida'
                          : 'Validade: ${DateFormat('dd/MM/yyyy').format(_validity!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Escolher data'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveDonation,
                child: const Text('Salvar Doação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
