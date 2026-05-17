import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trilho.dart';
import '../services/trilhos_service.dart';
import 'detalhes_trilho_page.dart';


class TrilhosPage extends StatefulWidget {
  const TrilhosPage({super.key});

  @override
  State<TrilhosPage> createState() => _TrilhosPageState();
}

class _TrilhosPageState extends State<TrilhosPage> {
  List<Trilho> trilhos = [];
  bool isLoading = false;
  double searchRadius = 20.0; // km
  Position? currentPos;

  @override
  void initState() {
    super.initState();
    _procurarTrilhos();
  }

  Future<void> _procurarTrilhos() async {
    setState(() {
      isLoading = true;
      trilhos = [];
    });

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium)
        );

        final data = await TrilhosService.getTrilhosProximos(
          currentPos!.latitude, 
          currentPos!.longitude, 
          radius: searchRadius * 1000 // Converter para metros
        );
        
        setState(() {
          trilhos = data;
        });
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      isLoading = false;
    });
  }

  String _getImagePath(int? id) {
    int index = ((id ?? 0) % 10) + 1;
    return index <= 4 ? 'assets/trilhos/trilho$index.jpg' : 'assets/trilhos/trilho$index.jpeg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trilhos Reais")),
      body: Column(
        children: [
          // Filtro de Raio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
            ),
            child: Row(
              children: [
                const Icon(Icons.radar, color: Colors.deepPurpleAccent),
                const SizedBox(width: 8),
                Text("Raio: ${searchRadius.toInt()} km", style: const TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Slider(
                    value: searchRadius,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    activeColor: Colors.deepPurpleAccent,
                    onChanged: (val) {
                      setState(() {
                        searchRadius = val;
                      });
                    },
                    onChangeEnd: (_) {
                      _procurarTrilhos(); // Pesquisar novamente ao largar o slider
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("A pesquisar trilhos no OpenStreetMap...")
                      ],
                    )
                  )
                : trilhos.isEmpty
                    ? const Center(
                        child: Text(
                          "Nenhum trilho encontrado neste raio.",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: trilhos.length,
                        itemBuilder: (context, index) {
                          final t = trilhos[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  _getImagePath(t.id),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(t.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                "${t.distancia.toStringAsFixed(2)} km • ${t.dificuldade}",
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetalhesTrilhoPage(trilho: t),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
