// Autor: Vinícius Castro & Allan Giovanni Matias Paes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:frontend/firebase_options.dart';
import 'package:frontend/pages/auth/forgot_password_page.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/auth/login_page.dart';
import 'package:frontend/pages/auth/register_page.dart';
import 'package:frontend/constants/colors.dart';

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

  // Inicializa a formatação de data para o locale brasileiro
  await initializeDateFormatting('pt_BR', null);
  
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
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: AppColors.white,
          ),
          // Configuração do Tema Escuro
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
              surface: AppColors.surfaceDark,
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: AppColors.surfaceDark,
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