// Autor: Vinícius Castro & Allan Giovanni Matias Paes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/firebase_options.dart';
import 'package:frontend/pages/forgot_password_page.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env might not exist or be empty, we can continue if not strictly needed for all environments
    print("Warning: Could not load .env file: $e");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MesclaInvest());
}

class MesclaInvest extends StatelessWidget {
  const MesclaInvest({super.key});

  @override
  Widget build(BuildContext context) {
    var userName = FirebaseAuth.instance.currentUser?.displayName;

    return MaterialApp(
      title: 'Mescla Invest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A84E)),
        useMaterial3: true,
        fontFamily: 'Inter', // Assuming Inter or standard sans-serif
      ),
      home: HomePage(userName: userName ?? 'Desconhecido'),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgotPassword': (context) => const ForgotPasswordPage()
      },
    );
  }
}