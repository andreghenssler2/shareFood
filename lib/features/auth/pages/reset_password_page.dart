// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';

// class ResetPasswordPage extends StatefulWidget {
//   const ResetPasswordPage({super.key});

//   @override
//   State<ResetPasswordPage> createState() => _ResetPasswordPageState();
// }

// class _ResetPasswordPageState extends State<ResetPasswordPage> {
//   final _emailController = TextEditingController();
//   final _authService = AuthService();

//   void _resetPassword() async {
//     try {
//       await _authService.resetPassword(_emailController.text.trim());
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('E-mail de redefinição enviado!')),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Erro: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Redefinir Senha')),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(labelText: 'E-mail'),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _resetPassword,
//               child: const Text('Enviar e-mail de redefinição'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
