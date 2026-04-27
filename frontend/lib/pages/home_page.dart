// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:frontend/pages/catalog_page.dart';
import 'package:frontend/widgets/home_view.dart';
import 'package:frontend/widgets/soon_view.dart';

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
      HomeView(userName: widget.userName),
      CatalogPage(),
      const SoonView(title: 'Carteira'),
      const SoonView(title: 'Conta'),
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
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Carteira',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Conta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF00A84E),
        unselectedItemColor: const Color(0xFF9AA3AE),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
