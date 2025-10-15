import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

// Auth
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';

// Home
import 'features/home/home_page.dart';

// Donations
import 'features/donations/my_donations_page.dart';
import 'features/donations/create_donation_page.dart';

// Profile
import 'features/profile/profile_page.dart';

// ONG Panel
import 'features/ong/ong_painel_page.dart';
import 'features/ong/ong_carrinho_page.dart';

// Partner Panel
import 'features/parceiro/parceiro_painel_page.dart';
import 'features/parceiro/parceiro_criar_doacao_page.dart';
import 'features/parceiro/editar_doacao_page.dart';
import 'features/parceiro/historico_pedidos_page.dart';

// ✅ Admin Panel
import 'features/admin/admin_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ShareFoodApp());
}

class ShareFoodApp extends StatelessWidget {
  const ShareFoodApp({super.key});

  /// 🔍 Decide qual tela abrir ao iniciar o app
  Future<Widget> _getInitialPage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // 🔸 Nenhum usuário logado
      return const LoginPage();
    }

    try {
      // 🔸 Busca o tipo do usuário no Firestore
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        return const LoginPage();
      }

      final tipo = doc['tipo'] ?? '';

      switch (tipo) {
        case 'admin':
          return const AdminDashboardPage();
        case 'ong':
          return const OngPainelPage();
        case 'parceiro':
          return const ParceiroPainelPage();
        default:
          return const HomePage();
      }
    } catch (e) {
      // Em caso de erro, retorna pro login
      await FirebaseAuth.instance.signOut();
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareFood',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,

      // ✅ Inicializa verificando o usuário logado
      home: FutureBuilder<Widget>(
        future: _getInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            );
          }
          return snapshot.data ?? const LoginPage();
        },
      ),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),

        // 👤 Usuário comum
        '/home': (context) => const HomePage(),
        '/my-donations': (context) => const MyDonationsPage(),
        '/create-donation': (context) => const CreateDonationPage(),
        '/profile': (context) => const ProfilePage(),

        // 🏢 ONG
        '/ong': (context) => const OngPainelPage(),
        'ong_carrinho_page': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as List<Map<String, dynamic>>;
          return OngCarrinhoPage(itensCarrinho: args);
        },

        // 🏪 Parceiro
        '/parceiro': (context) => const ParceiroPainelPage(),
        '/criarDoacao': (context) => const ParceiroCriarDoacaoPage(),
        '/editarDoacao': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return EditarDoacaoPage(doacao: args);
        },
        '/historicoDoacoes': (context) => const HistoricoPedidosPage(),

        // 🧑‍💼 Admin
        '/admin': (context) => const AdminDashboardPage(),
      },

      // 🌎 Localização (para português)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
    );
  }
}
