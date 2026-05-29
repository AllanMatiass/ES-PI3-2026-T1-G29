// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/pages/invest/catalog_page.dart';
import 'package:frontend/views/home_view.dart';
import 'package:frontend/pages/profile/profile_page.dart';
import 'package:frontend/views/offers_view.dart';
import 'package:frontend/views/wallet_view.dart';

import 'package:frontend/views/news_view.dart';

/// Controlador principal de navegação da aplicação (Bottom Navigation Bar).
/// Gerencia a exibição das diferentes visões (Início, Notícias, Investir, Mercado, Carteira e Perfil)
/// mantendo o estado de cada uma através do IndexedStack.
class HomePage extends StatefulWidget {
  final String userName;
  final int initialIndex; // Aba a ser selecionada ao abrir a página
  final String? initialStartupId; // Passado opcionalmente para abrir notícias filtradas

  const HomePage({
    super.key,
    required this.userName,
    this.initialIndex = 0,
    this.initialStartupId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Inicializa todas as visões principais do app. 
    // O IndexedStack manterá o estado (scroll, inputs) delas vivo durante a navegação.
    _pages = [
      HomeView(
        userName: widget.userName,
        onNavigateToCatalog: () => _onItemTapped(2), // Atalho para a aba "Investir"
      ),
      NewsView(initialStartupId: widget.initialStartupId),
      const CatalogPage(),
      const OffersView(),
      const WalletView(),
      const ProfilePage(),
    ];
  }

  /// Atualiza o índice da aba ativa
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Garante que a página só seja renderizada se houver um usuário autenticado
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      // Redireciona para o login de forma segura após o término do frame atual
      // para evitar a exceção "setState() or markNeedsBuild() called during build"
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // IndexedStack renderiza todas as telas sobrepostas, mas só exibe a de índice _selectedIndex.
      // Isso é crucial para que o usuário não perca sua posição de scroll ao trocar de aba.
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper),
            label: 'Notícias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Investir', // Leva ao Catálogo de Startups
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.candlestick_chart),
            activeIcon: Icon(Icons.candlestick_chart),
            label: 'Balcão', // Balcão
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Carteira',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant.withOpacity(
          0.6,
        ),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.shifting,
        backgroundColor: theme.colorScheme.surface,
        elevation: 8,
      ),
    );
  }
}
