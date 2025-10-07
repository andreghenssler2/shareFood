import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

// Auth
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
// import 'features/auth/pages/reset_password_page.dart';

// Home
import 'features/home/home_page.dart';

// Donations
import 'features/donations/my_donations_page.dart';
import 'features/donations/create_donation_page.dart';

// Profile
import 'features/profile/profile_page.dart';

// ONG Panel
import 'features/ong/ong_painel_page.dart';

// Partner Panel
import 'features/parceiro/parceiro_painel_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ShareFoodApp());
}

class ShareFoodApp extends StatelessWidget {
  const ShareFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareFood',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        // '/reset-password': (context) => const ResetPasswordPage(),
        '/home': (context) => const HomePage(),
        '/my-donations': (context) => const MyDonationsPage(),
        '/create-donation': (context) => const CreateDonationPage(),
        '/profile': (context) => const ProfilePage(),
        '/ong': (context) => const OngPainelPage(),
        '/parceiro': (context) => const ParceiroPainelPage(),
      },
    );
  }
}
