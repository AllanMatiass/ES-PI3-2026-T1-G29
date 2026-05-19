// Autor: Allan Giovanni Matias Paes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/pages/invest/catalog_page.dart';
import 'package:frontend/views/home_view.dart';
import 'package:frontend/views/soon_view.dart';
import 'package:frontend/views/offers_view.dart';
import 'package:frontend/views/wallet_view.dart';

class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();


    _pages = [
      HomeView(
        userName: widget.userName,
        onNavigateToCatalog: () => _onItemTapped(1),
      ),
      const CatalogPage(),
      const OffersView(),
      const WalletView(),
      const SoonView(title: 'Perfil'),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      // Usamos Future.microtask para evitar erros de navegação durante o build
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Investir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.candlestick_chart),
            activeIcon: Icon(Icons.candlestick_chart),
            label: 'Mercado',
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
        unselectedItemColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.colorScheme.surface,
        elevation: 8,
      ),
    );
  }
}