import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _tipoUsuario = 'ong';
  bool _loading = false;

  final AuthService _authService = AuthService();

  Future<void> _registrar() async {
    final email = _emailController.text.trim();
    final senha = _passwordController.text.trim();
    final confirmarSenha = _confirmPasswordController.text.trim();

    if (email.isEmpty || senha.isEmpty || confirmarSenha.isEmpty) {
      _showErrorDialog('Preencha todos os campos.');
      return;
    }

    if (senha != confirmarSenha) {
      _showErrorDialog('As senhas não coincidem.');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.signUp(email, senha, _tipoUsuario);

      if (user != null) {
        // Garante que o Firestore tenha o documento com UID como ID
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'tipo': _tipoUsuario,
          'criadoEm': FieldValue.serverTimestamp(),
        });

        _showSuccessDialog('Conta criada com sucesso!');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao criar conta.';
      if (e.code == 'email-already-in-use') {
        message = 'Este e-mail já está em uso.';
      } else if (e.code == 'invalid-email') {
        message = 'E-mail inválido.';
      } else if (e.code == 'weak-password') {
        message = 'A senha deve ter pelo menos 6 caracteres.';
      }
      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog('Erro inesperado. Tente novamente.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sucesso'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar Senha'),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _tipoUsuario,
              decoration: const InputDecoration(labelText: 'Tipo de Usuário'),
              items: const [
                // DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                DropdownMenuItem(value: 'ong', child: Text('ONG')),
                DropdownMenuItem(value: 'parceiro', child: Text('Parceiro')),
              ],
              onChanged: (value) {
                setState(() => _tipoUsuario = value!);
              },
            ),
            const SizedBox(height: 32),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _registrar,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: const Color.fromARGB(255, 13, 110, 253),
                    ),
                    child: const Text(
                      'Registrar',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text('Já tem conta? Fazer login', style: TextStyle(color: Color.fromARGB(255, 8, 77, 228), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
