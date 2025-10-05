import 'package:flutter/material.dart';
import '../auth/services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 Nome: ${user?.displayName ?? "Não informado"}'),
            const SizedBox(height: 8),
            Text('📧 E-mail: ${user?.email ?? "Não informado"}'),
            const SizedBox(height: 8),
            Text('UID: ${user?.uid ?? "-"}'),
          ],
        ),
      ),
    );
  }
}
