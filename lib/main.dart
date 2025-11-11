import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ShareFood',

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
          ],

          routes: {
            '/editarDoacao': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return EditarDoacaoPage(doacao: args);
            },
          },

          // Aqui está o ponto principal
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final user = snapshot.data;
              if (user == null) {
                return const LoginPage();
              }

              return FutureBuilder<Widget>(
                future: _getInitialPage(user),
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
      },
    );
  }
}
