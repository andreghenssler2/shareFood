import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import '../../ong/ong_home_page.dart';
import '../../parceiro/parceiro_home_page.dart';
import '../../home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final senha = _passwordController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      _showErrorDialog('Preencha todos os campos.');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.signIn(email, senha);

      if (user == null) {
        _showErrorDialog('Erro ao autenticar usuário.');
        return;
      }

      await _verificarTipoUsuario(user.uid, email);

    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao fazer login.';

      switch (e.code) {
        case 'user-not-found':
          message = 'Usuário não encontrado.';
          break;
        case 'wrong-password':
          message = 'Senha incorreta.';
          break;
        case 'invalid-email':
          message = 'E-mail inválido.';
          break;
        case 'user-disabled':
          message = 'Usuário desativado.';
          break;
      }

      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog('Erro inesperado. Tente novamente.');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🔍 Verifica o tipo do usuário por UID ou E-MAIL
  Future<void> _verificarTipoUsuario(String uid, String email) async {
    DocumentSnapshot? doc;

    // 1️⃣ Tenta buscar pelo UID
    final uidDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (uidDoc.exists) {
      doc = uidDoc;
    } else {
      // 2️⃣ Se não achar, tenta buscar pelo e-mail
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        doc = query.docs.first;
      }
    }

    if (doc == null || !doc.exists) {
      _showErrorDialog('Usuário não encontrado no banco de dados.');
      return;
    }

    final tipo = doc['tipo'] ?? '';

    if (tipo == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (tipo == 'ong') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OngHomePage()));
    } else if (tipo == 'parceiro') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParceiroHomePage()));
    } else {
      _showErrorDialog('Tipo de usuário desconhecido.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Entrar'),
                    ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
