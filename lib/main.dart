import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ⬅️ Adicione isto
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/auth/pages/login_page.dart';
import 'features/ong/ong_home_page.dart';
import 'features/parceiro/parceiro_home_page.dart';
import 'features/admin/admin_dashboard_page.dart';
import 'features/parceiro/editar_doacao_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialPage(User user) async {
    // Busca o tipo de usuário no Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) {
      await FirebaseAuth.instance.signOut();
      return const LoginPage();
    }

    final tipo = data['tipo'] ?? '';

    if (tipo == 'parceiro') {
      return const ParceiroHomePage();
    } else if (tipo == 'ong') {
      return const OngHomePage();
    } else if (tipo == 'admin') {
      return const AdminDashboardPage();
    } else {
      await FirebaseAuth.instance.signOut();
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShareFood',

      // 🔹 Adicione estas linhas para corrigir o erro do DatePicker e traduzir para português
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],

      // 🔹 Rotas nomeadas
      routes: {
        '/editarDoacao': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return EditarDoacaoPage(doacao: args);
        },
      },

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Enquanto inicializa
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Se não há usuário logado
          if (!snapshot.hasData) {
            return const LoginPage();
          }

          // Usuário logado — carrega tipo do Firestore
          return FutureBuilder<Widget>(
            future: _getInitialPage(snapshot.data!),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (futureSnapshot.hasError) {
                return const Scaffold(
                  body: Center(child: Text('Erro ao carregar usuário')),
                );
              }
              return futureSnapshot.data!;
            },
          );
        },
      ),
    );
  }
}
