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

/// Notificador global para alternar entre os temas Light e Dark.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  // Garante que os bindings do Flutter estejam inicializados antes de chamadas assíncronas
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Carrega variáveis de ambiente do arquivo .env
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: Could not load .env file: $e");
  }

  // Inicializa o Firebase com as configurações da plataforma atual
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const MesclaInvest());
}

/// Widget principal da aplicação.
class MesclaInvest extends StatelessWidget {
  const MesclaInvest({super.key});

  @override
  Widget build(BuildContext context) {
    // Verifica se existe um usuário autenticado no Firebase
    final User? user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Mescla Invest',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Configuração do Tema Claro
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00A84E),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: Colors.white,
          ),
          // Configuração do Tema Escuro
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00A84E),
              brightness: Brightness.dark,
              surface: const Color(0xFF0F172A),
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: const Color(0xFF0F172A),
          ),
          // Página inicial: Login se deslogado, Home se autenticado
          home: user == null 
              ? const LoginPage() 
              : HomePage(userName: user.displayName ?? 'Desconhecido'),
          // Definição das rotas nomeadas do aplicativo
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/forgotPassword': (context) => const ForgotPasswordPage(),
            '/home': (context) => HomePage(userName: FirebaseAuth.instance.currentUser?.displayName ?? 'Desconhecido'),
          },
        );
      },
    );
  }
}