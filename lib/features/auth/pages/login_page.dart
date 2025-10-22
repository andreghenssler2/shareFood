import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'reset_password_page.dart';

// Telas principais
import '../../ong/ong_home_page.dart';
import '../../ong/ong_perfil_page.dart';
import '../../parceiro/parceiro_home_page.dart';
import '../../parceiro/parceiro_perfil_page.dart';
import '../../admin/admin_dashboard_page.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

      // Se preferir delegar redirecionamento para main.dart (StreamBuilder),
      // basta COMENTAR a linha abaixo. Aqui eu mantenho a verificação e
      // navegação para compatibilidade com a lógica anterior.
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

  /// 🔍 Verifica o tipo e redireciona (mantido como no código original)
  Future<void> _verificarTipoUsuario(String uid, String email) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final ongsRef = FirebaseFirestore.instance.collection('ongs');
    final parceirosRef = FirebaseFirestore.instance.collection('parceiros');
    final adminRef = FirebaseFirestore.instance.collection('admin');

    // Tenta obter o documento 'users' principal
    DocumentSnapshot userDoc = await usersRef.doc(uid).get();

    // Se não existir, avisa — normalmente o cadastro deve criar esse doc
    if (!userDoc.exists) {
      _showErrorDialog('Usuário não encontrado no banco de dados.');
      return;
    }

    final tipo = userDoc['tipo'] ?? '';

    if (tipo == 'admin') {
      // Verifica se já existe perfil específico no collection "admin"
      final adminQuery = await adminRef.where('uid', isEqualTo: uid).limit(1).get();

      if (adminQuery.docs.isEmpty) {
        // Admin sem perfil preenchido → abrir dashboard (ou página de cadastro se houver)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboardPage(),
          ),
        );
      } else {
        // Admin com perfil → ir para dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      }
      return;
    }

    if (tipo == 'ong') {
      // Verifica se ONG já cadastrou o perfil
      final ongQuery = await ongsRef.where('uid', isEqualTo: uid).limit(1).get();

      if (ongQuery.docs.isEmpty) {
        // ONG ainda não cadastrada → preencher perfil (manter UID)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OngPerfilPage(uid: uid),
          ),
        );
      } else {
        // Já tem perfil → vai pra home da ONG
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OngHomePage()),
        );
      }
      return;
    }

    if (tipo == 'parceiro') {
      // Verifica se parceiro já cadastrou o perfil
      final parceiroQuery = await parceirosRef.where('uid', isEqualTo: uid).limit(1).get();

      if (parceiroQuery.docs.isEmpty) {
        // Parceiro ainda não cadastrou → vai preencher perfil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ParceiroPerfilPage(uid: uid),
          ),
        );
      } else {
        // Já tem perfil → vai pra home do parceiro
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParceiroHomePage()),
        );
      }
      return;
    }

    // Se chegar aqui, tipo desconhecido
    _showErrorDialog('Tipo de usuário desconhecido.');
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
              Image.asset('assets/images/logo.png', height: 120),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
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
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordPage(),
                    ),
                  );
                },
                child: const Text('Esqueceu a senha?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
