import 'package:flutter/material.dart';
import 'inicio_page.dart';
import 'trilhos_page.dart';
import 'atividade_page.dart';
import 'perfil_page.dart';

class AppNavigator extends StatefulWidget {
  final int startIndex;

  const AppNavigator({super.key, this.startIndex = 0});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  late int _selectedIndex;

  final List<Widget> _pages = const [
    InicioPage(),
    TrilhosPage(),
    AtividadePage(),
    PerfilPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.startIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Início"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Trilhos"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_walk), label: "Atividade"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
