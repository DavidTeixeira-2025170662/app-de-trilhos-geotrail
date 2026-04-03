import 'package:flutter/material.dart';
import 'app_navigator.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              // Header
              const Text(
                "Bem-vindo(a),",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Explorador!",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),
              
              // Grid com os cartões do menu
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.85,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildDashboardCard(
                      context: context,
                      title: "Início",
                      icon: Icons.home_rounded,
                      index: 0,
                      gradientColors: [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
                    ),
                    _buildDashboardCard(
                      context: context,
                      title: "Trilhos",
                      icon: Icons.map_rounded,
                      index: 1,
                      gradientColors: [const Color(0xFF00695C), const Color(0xFF26A69A)],
                    ),
                    _buildDashboardCard(
                      context: context,
                      title: "Atividade",
                      icon: Icons.directions_walk_rounded,
                      index: 2,
                      gradientColors: [const Color(0xFFE65100), const Color(0xFFFF9800)],
                    ),
                    _buildDashboardCard(
                      context: context,
                      title: "Perfil",
                      icon: Icons.person_rounded,
                      index: 3,
                      gradientColors: [const Color(0xFF283593), const Color(0xFF5C6BC0)],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required int index,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent, // Transparente para deixar ver o gradiente por baixo
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AppNavigator(startIndex: index),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ícone circular no topo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: Colors.white),
                ),
                // Título no fim do cartão
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}