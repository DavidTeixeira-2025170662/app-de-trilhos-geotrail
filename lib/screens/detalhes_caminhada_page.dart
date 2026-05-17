import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class DetalhesCaminhadaPage extends StatefulWidget {
  final Map<String, dynamic> caminhada;

  const DetalhesCaminhadaPage({super.key, required this.caminhada});

  @override
  State<DetalhesCaminhadaPage> createState() => _DetalhesCaminhadaPageState();
}

class _DetalhesCaminhadaPageState extends State<DetalhesCaminhadaPage> {
  GoogleMapController? _mapController;
  List<LatLng> _rota = [];
  bool _loadingRota = true;

  @override
  void initState() {
    super.initState();
    _carregarRota();
  }

  Future<void> _carregarRota() async {
    final id = widget.caminhada['id_caminhada'] as int?;
    if (id == null) {
      setState(() => _loadingRota = false);
      return;
    }
    final pontos = await DatabaseHelper.instance.getRotaByCaminhada(id);
    setState(() {
      _rota = pontos
          .map((p) => LatLng(p['latitude'] as double, p['longitude'] as double))
          .toList();
      _loadingRota = false;
    });
  }

String _formatarDuracao(dynamic segundos) {
    final s = (segundos as num).toInt();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h ${m}m ${sec}s';
    return '${m}m ${sec}s';
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caminhada;
    final LatLng? centro = _rota.isNotEmpty ? _rota[_rota.length ~/ 2] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Caminhada'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partilhar conquista',
            onPressed: () {
              final dist = (c['distancia_total'] as num).toStringAsFixed(2);
              final tempo = _formatarDuracao(c['duracao']);
              final vel = (c['velocidade_media'] as num).toStringAsFixed(1);
              final desnivel = (c['desnivel_acumulado'] as num).toStringAsFixed(0);
              
              final msg = "Olha a minha conquista! Fiz um trilho de $dist km em $tempo.\n\nOlha o meu percurso e as minhas métricas:\n• Velocidade Média: $vel km/h\n• Desnível Acumulado: $desnivel m\n\nVem fazer trilhos comigo na GeoTrail!";
              
              Share.share(msg);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Mapa com rota gravada ---
          SizedBox(
            height: 280,
            child: _loadingRota
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.deepPurpleAccent))
                : centro == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.location_off_rounded,
                                color: Colors.white38, size: 48),
                            SizedBox(height: 8),
                            Text('Sem dados de rota gravados',
                                style: TextStyle(color: Colors.white38)),
                          ],
                        ),
                      )
                    : GoogleMap(
                        style: Theme.of(context).brightness == Brightness.dark ? _darkMapStyle : null,
                        onMapCreated: (controller) {
                            _mapController = controller;
                            if (_rota.isNotEmpty) {
                                  final bounds = _calcularBounds(_rota);
                                  controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                            }
                          },
                        initialCameraPosition: CameraPosition(
                          target: centro,
                          zoom: 15,
                        ),
                        polylines: {
                            Polyline(
                              polylineId: PolylineId("rota"),
                              points: _rota,
                              color: Colors.blue,
                              width: 5,
                            ),
                        },
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        markers: {
                          if (_rota.isNotEmpty)
                            Marker(
                              markerId: const MarkerId('inicio'),
                              position: _rota.first,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen),
                              infoWindow: const InfoWindow(title: 'Início'),
                            ),
                          if (_rota.length > 1)
                            Marker(
                              markerId: const MarkerId('fim'),
                              position: _rota.last,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRed),
                              infoWindow: const InfoWindow(title: 'Fim'),
                            ),
                        },
                      ),
          ),
          // --- Estatísticas ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Cards de métricas
                  Row(
                    children: [
                      _statCard(
                        '${(c['distancia_total'] as num).toStringAsFixed(2)} km',
                        'Distância',
                        Icons.route_rounded,
                        const Color(0xFF26A69A),
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        _formatarDuracao(c['duracao']),
                        'Duração',
                        Icons.timer_outlined,
                        const Color(0xFFFF9800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard(
                        '${(c['velocidade_media'] as num).toStringAsFixed(1)} km/h',
                        'Vel. Média',
                        Icons.speed_rounded,
                        const Color(0xFF5C6BC0),
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        '${(c['desnivel_acumulado'] as num).toStringAsFixed(0)} m',
                        'Desnível',
                        Icons.terrain_rounded,
                        Colors.deepPurpleAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Data
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Colors.white38, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          c['data']?.toString() ?? 'Data desconhecida',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String valor, String label, IconData icon, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cor, size: 24),
            const SizedBox(height: 8),
            Text(valor,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  LatLngBounds _calcularBounds(List<LatLng> pontos) {
    double minLat = pontos.first.latitude;
    double maxLat = pontos.first.latitude;
    double minLng = pontos.first.longitude;
    double maxLng = pontos.first.longitude;
    for (final p in pontos) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';
