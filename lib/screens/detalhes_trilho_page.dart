import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../models/trilho.dart';
import '../services/weather_service.dart';
import '../services/poi_service.dart';
import 'atividade_page.dart';

class DetalhesTrilhoPage extends StatelessWidget {
  final Trilho trilho;

  const DetalhesTrilhoPage({super.key, required this.trilho});

  String _getImagePath(int? id) {
    int index = ((id ?? 0) % 10) + 1;
    return index <= 4 ? 'assets/trilhos/trilho$index.jpg' : 'assets/trilhos/trilho$index.jpeg';
  }

  void _partilharConvite(BuildContext context) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'ESCOLHE O DIA DA CAMINHADA',
    );

    if (dataSelecionada == null || !context.mounted) return;

    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'ESCOLHE A HORA DA CAMINHADA',
    );

    if (horaSelecionada == null) return;

    final DateTime dataCompleta = DateTime(
      dataSelecionada.year,
      dataSelecionada.month,
      dataSelecionada.day,
      horaSelecionada.hour,
      horaSelecionada.minute,
    );

    final String dataFormatada = DateFormat('dd/MM/yyyy').format(dataCompleta);
    final String horaFormatada = DateFormat('HH:mm').format(dataCompleta);

    final String mensagem = "Dia $dataFormatada às $horaFormatada vou realizar o trilho '${trilho.nome}'. São ${trilho.distancia.toStringAsFixed(2)} km de dificuldade ${trilho.dificuldade}. Queres-te juntar?\n\nVem fazer trilhos comigo na app GeoTrail! 🥾";

    await Share.share(mensagem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(trilho.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _partilharConvite(context),
            tooltip: 'Partilhar convite',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // FOTO DO TRILHO (placeholder)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(_getImagePath(trilho.id)),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // NOME
            Text(
              trilho.nome,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // DISTÂNCIA + DIFICULDADE
            Row(
              children: [
                Icon(Icons.route, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text("${trilho.distancia.toStringAsFixed(2)} km"),

                const SizedBox(width: 20),

                Icon(Icons.flag, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(trilho.dificuldade),
              ],
            ),

            const SizedBox(height: 20),

            // DESCRIÇÃO
            const Text(
              "Descrição",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              trilho.descricao,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // DESNÍVEL E GRÁFICO DE ALTIMETRIA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Altimetria",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "↑ ${trilho.desnivel} m",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.deepPurpleAccent.shade100,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('0km', style: TextStyle(fontSize: 10, color: Colors.grey));
                          if (value == trilho.distancia) return Text('${trilho.distancia.toInt()}km', style: const TextStyle(fontSize: 10, color: Colors.grey));
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: trilho.distancia,
                  minY: 0,
                  maxY: trilho.desnivel * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 0),
                        FlSpot(trilho.distancia * 0.2, trilho.desnivel * 0.3),
                        FlSpot(trilho.distancia * 0.4, trilho.desnivel * 0.8),
                        FlSpot(trilho.distancia * 0.6, trilho.desnivel * 0.6),
                        FlSpot(trilho.distancia * 0.8, trilho.desnivel * 1.0),
                        FlSpot(trilho.distancia, trilho.desnivel * 0.85),
                      ],
                      isCurved: true,
                      color: Colors.deepPurpleAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // MAPA DE PRÉ-VISUALIZAÇÃO
            const Text(
              "Percurso do Trilho",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                List<LatLng> pontos = [];
                try {
                  final List decoded = json.decode(trilho.rotaPredefinida);
                  pontos = decoded.map((e) => LatLng(e['lat'], e['lon'])).toList();
                } catch (e) {
                  // Fallback para a coordenada principal
                  final parts = trilho.coordenadas.split(',');
                  if (parts.length == 2) {
                    pontos = [LatLng(double.parse(parts[0].trim()), double.parse(parts[1].trim()))];
                  }
                }

                if (pontos.isEmpty) return const SizedBox();

                return Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: pontos.first, zoom: 14),
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      scrollGesturesEnabled: false,
                      polylines: {
                        if (pontos.length > 1)
                          Polyline(
                            polylineId: const PolylineId('rota_pre'),
                            points: pontos,
                            color: Colors.deepPurpleAccent,
                            width: 5,
                          ),
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('inicio'),
                          position: pontos.first,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                        if (pontos.length > 1)
                          Marker(
                            markerId: const MarkerId('fim'),
                            position: pontos.last,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          ),
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // METEOROLOGIA
            const Text(
              "Meteorologia Atual",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                double lat = 0.0;
                double lon = 0.0;
                try {
                  final parts = trilho.coordenadas.split(',');
                  if (parts.length == 2) {
                    lat = double.parse(parts[0].trim());
                    lon = double.parse(parts[1].trim());
                  }
                } catch (e) {
                  return const Text('Coordenadas inválidas para obter meteorologia.');
                }

                return FutureBuilder<Map<String, dynamic>?>(
                  future: WeatherService.getWeather(lat, lon),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return const Text('Não foi possível obter a meteorologia.');
                    }

                    final data = snapshot.data!;
                    final temp = data['main']['temp'].round();
                    final desc = data['weather'][0]['description'];
                    final iconCode = data['weather'][0]['icon'];
                    final iconUrl = 'https://openweathermap.org/img/wn/$iconCode@2x.png';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Image.network(iconUrl, width: 50, height: 50),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$temp°C",
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${desc[0].toUpperCase()}${desc.substring(1)}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // POIs
            const Text(
              "Pontos de Interesse (Raio 3km)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                double lat = 0.0;
                double lon = 0.0;
                try {
                  final parts = trilho.coordenadas.split(',');
                  if (parts.length == 2) {
                    lat = double.parse(parts[0].trim());
                    lon = double.parse(parts[1].trim());
                  }
                } catch (e) {
                  return const SizedBox();
                }

                return FutureBuilder<List<POI>>(
                  future: POIService.getPOIs(lat, lon, radius: 3000),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Nenhum ponto de interesse encontrado nas redondezas.');
                    }

                    final pois = snapshot.data!;
                    final Map<String, int> counts = {};
                    for (var poi in pois) {
                      counts[poi.type] = (counts[poi.type] ?? 0) + 1;
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: counts.entries.map((e) {
                        IconData ic = Icons.place;
                        Color c = Colors.grey;
                        if (e.key == 'Miradouro') { ic = Icons.camera_alt; c = Colors.orange; }
                        else if (e.key == 'Café') { ic = Icons.local_cafe; c = Colors.brown; }
                        else if (e.key == 'Restaurante') { ic = Icons.restaurant; c = Colors.redAccent; }
                        else if (e.key == 'Hospital' || e.key == 'Farmácia') { ic = Icons.local_hospital; c = Colors.green; }

                        return Chip(
                          avatar: Icon(ic, color: c, size: 20),
                          label: Text('${e.value} ${e.key}(s)'),
                          backgroundColor: c.withValues(alpha: 0.1),
                          side: BorderSide(color: c.withValues(alpha: 0.3)),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),

            // BOTÃO OBTER DIREÇÕES
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.directions_car),
                label: const Text("Obter Direções"),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepPurpleAccent),
                ),
                onPressed: () async {
                  final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${trilho.coordenadas.replaceAll(' ', '')}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // BOTÃO INICIAR TRILHO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text("Iniciar Trilho"),
                onPressed: () async {
                  final db = DatabaseHelper.instance;

                  // 0. Sincronizar o trilho da API para a Base de Dados Local
                  await db.insertOrUpdateTrilho(trilho);

                  // 1. Criar nova caminhada
                  int idCaminhada = await db.insertCaminhada({
                    'id_trilho': trilho.id,
                    'id_utilizador': 1, // ou o ID real do utilizador
                    'data': DateTime.now().toIso8601String(),
                    'distancia_total': 0.0,
                    'velocidade_media': 0.0,
                    'rota': '',
                    'desnivel_acumulado': 0.0,
                    'duracao': 0.0,
                  });

                  // 2. Abrir página de atividade passando o ID e o trilho
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AtividadePage(idCaminhada: idCaminhada, trilho: trilho),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
