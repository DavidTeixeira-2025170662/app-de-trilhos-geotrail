import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class TestDBPage extends StatefulWidget {
  const TestDBPage({super.key});

  @override
  State<TestDBPage> createState() => _TestDBPageState();
}

class _TestDBPageState extends State<TestDBPage> {
  List<Map<String, dynamic>> favoritos = [];
  List<Map<String, dynamic>> caminhadas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    favoritos = await DatabaseHelper.instance.getFavoritos();
    caminhadas = await DatabaseHelper.instance.getCaminhadas();
    setState(() {});
  }

  Future<void> _addFavorito() async {
    await DatabaseHelper.instance.insertFavorito({
      'id_trilho': 1,
      'id_utilizador': 1,
      'data_adicionado': DateTime.now().toString(),
    });
    _loadData();
  }

  Future<void> _addCaminhada() async {
    await DatabaseHelper.instance.insertCaminhada({
      'id_trilho': 1,
      'id_utilizador': 1,
      'data': DateTime.now().toString(),
      'distancia_total': 5.2,
      'velocidade_media': 4.1,
      'rota': '[]',
      'desnivel_acumulado': 120,
      'duracao': 3600,
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teste BD")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _addFavorito,
            child: const Text("Adicionar Favorito"),
          ),
          ElevatedButton(
            onPressed: _addCaminhada,
            child: const Text("Adicionar Caminhada"),
          ),
          const SizedBox(height: 20),
          const Text("Favoritos:", style: TextStyle(fontSize: 20)),
          Expanded(
            child: ListView(
              children: favoritos
                  .map((f) => ListTile(
                        title: Text("Trilho: ${f['id_trilho']}"),
                        subtitle: Text("Data: ${f['data_adicionado']}"),
                      ))
                  .toList(),
            ),
          ),
          const Text("Caminhadas:", style: TextStyle(fontSize: 20)),
          Expanded(
            child: ListView(
              children: caminhadas
                  .map((c) => ListTile(
                        title: Text("Trilho: ${c['id_trilho']}"),
                        subtitle: Text("Distância: ${c['distancia_total']} km"),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}