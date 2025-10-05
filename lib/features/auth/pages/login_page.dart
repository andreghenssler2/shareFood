import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

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
      await _authService.signIn(email, senha);
      Navigator.pushReplacementNamed(context, '/home');
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

  // 🔹 Função para exibir o diálogo de erro
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Erro ao fazer login"  ,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
      body: Padding(
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
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
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
                    backgroundColor: const Color.fromARGB(255, 0, 42, 179),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(
                      color: Colors.white, // 🔹 texto branco
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Criar conta'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/reset-password'),
              child: const Text('Esqueci minha senha'),
            ),
          ],
        ),
      ),
    );
  }
}
