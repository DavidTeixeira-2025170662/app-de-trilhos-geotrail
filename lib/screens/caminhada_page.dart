import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'detalhes_caminhada_page.dart';

class CaminhadaPage extends StatefulWidget {
  const CaminhadaPage({super.key});

  @override
  State<CaminhadaPage> createState() => _CaminhadaPageState();
}

class _CaminhadaPageState extends State<CaminhadaPage> {
  List<Map<String, dynamic>> caminhadas = [];
  
  // GPS tracking
  GoogleMapController? _mapController;
  StreamSubscription<Position>? positionSub;
  Position? ultimaPosicao;
  double distanciaTotal = 0.0;
  List<Position> rota = [];
  List<LatLng> rotaLatLng = [];
  bool tracking = false;
  LatLng? _posicaoAtual;

  @override
  void initState() {
    super.initState();
    _loadCaminhadas();
    _obterPosicaoInicial();
  }

  Future<void> _obterPosicaoInicial() async {
    bool ok = await _checkPermissions();
    if (!ok) return;
    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _posicaoAtual = LatLng(pos.latitude, pos.longitude));
    }
  }

  Future<void> _loadCaminhadas() async {
    final data = await DatabaseHelper.instance.getCaminhadas();
    if (mounted) setState(() => caminhadas = data);
  }

  // ativar o tracking real
  Future<bool> _checkPermissions() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return false;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  return permission == LocationPermission.always ||
         permission == LocationPermission.whileInUse;
}

// Iniciar caminhada (tracking contínuo)
void _iniciarCaminhada() async {
  bool ok = await _checkPermissions();
  if (!ok) return;

  distanciaTotal = 0.0;
  rota.clear();
  rotaLatLng.clear();
  ultimaPosicao = null;

  setState(() => tracking = true);

  positionSub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1,
    ),
  ).listen((pos) {
    if (ultimaPosicao != null) {
      distanciaTotal += Geolocator.distanceBetween(
        ultimaPosicao!.latitude,
        ultimaPosicao!.longitude,
        pos.latitude,
        pos.longitude,
      );
    }

    ultimaPosicao = pos;
      rota.add(pos);
      final latLng = LatLng(pos.latitude, pos.longitude);
      rotaLatLng.add(latLng);

      if (mounted) {
        setState(() => _posicaoAtual = latLng);
        _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      }
  });
}

// Parar caminhada, guardar no SQLite e guardar rota ponto a ponto
void _pararCaminhada() async {
  await positionSub?.cancel();
  positionSub = null;

  // Se não houver pontos, ainda assim guardar caminhada
  if (rota.isEmpty) {
    int caminhadaId = await DatabaseHelper.instance.insertCaminhada({
      'id_trilho': 1,
      'id_utilizador': 1,
      'data': DateTime.now().toString(),
      'distancia_total': 0,
      'velocidade_media': 0,
      'rota': '',
      'desnivel_acumulado': 0,
      'duracao': 0.0,
    });

    _loadCaminhadas();
    return;
  }

  final inicio = rota.first.timestamp;
  final fim = rota.last.timestamp;
  final duracaoSegundos = fim.difference(inicio).inSeconds;
  final distanciaKm = distanciaTotal / 1000;
  final duracaoHoras = duracaoSegundos / 3600;
  final velocidadeMedia = duracaoHoras > 0 ? distanciaKm / duracaoHoras : 0;

  int caminhadaId = await DatabaseHelper.instance.insertCaminhada({
    'id_trilho': 1,
    'id_utilizador': 1,
    'data': DateTime.now().toString(),
    'distancia_total': distanciaKm,
    'velocidade_media': velocidadeMedia,
    'rota': '', // já não usamos JSON
    'desnivel_acumulado': 0,
    'duracao': duracaoSegundos.toDouble(),
  });

  for (var p in rota) {
    await DatabaseHelper.instance.insertPontoRota({
      'id_caminhada': caminhadaId,
      'latitude': p.latitude,
      'longitude': p.longitude,
      'timestamp': p.timestamp.toIso8601String(),
    });
  }

  _loadCaminhadas();
}

String _formatarDuracao(dynamic segundos) {
    final s = (segundos as num).toInt();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
    void dispose() {
      positionSub?.cancel();
      _mapController?.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caminhada'),
        centerTitle: true,
      ),
      body: Column(
        children: [
            // --- Mini mapa com rota em tempo real ---
            SizedBox(
              height: 260,
              child: _posicaoAtual == null
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.deepPurpleAccent))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _posicaoAtual!,
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    polylines: tracking && rotaLatLng.length > 1
                      ? {
                            Polyline(
                              polylineId: const PolylineId('rota'),
                              points: rotaLatLng,
                              color: accent,
                              width: 5,
                            ),
                          }
                      : {},
                    onMapCreated: (c) {
                      _mapController = c;
                      c.setMapStyle(_darkMapStyle);
                    },
                  ),
          ),
          // --- Métricas ao vivo ---
          if (tracking)
            Container(
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricaViva(
                      '${(distanciaTotal / 1000).toStringAsFixed(2)} km',
                      'Distância'),
                  _metricaViva('${rota.length}', 'Pontos GPS'),
                ],
              ),
            ),

            // --- Botões ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(tracking
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded),
                    label: Text(tracking ? 'Parar' : 'Iniciar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          tracking ? Colors.redAccent : Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed:
                        tracking ? _pararCaminhada : _iniciarCaminhada,
                  ),
                ),
              ],
            ),
          ),

          // --- Lista de caminhadas anteriores ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Caminhadas anteriores',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8))),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: caminhadas.isEmpty
                ? const Center(
                    child: Text('Ainda não tens caminhadas registadas.',
                        style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: caminhadas.length,
                    itemBuilder: (_, i) {
                      final c = caminhadas[i];
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: accent.withOpacity(0.2),
                            child: Icon(Icons.route_rounded, color: accent),
                          ),
                          title: Text(
                            '${(c['distancia_total'] as num).toStringAsFixed(2)} km',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${_formatarDuracao(c['duracao'])}  •  ${c['data']?.toString().substring(0, 10) ?? ''}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: Colors.white38),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetalhesCaminhadaPage(caminhada: c),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metricaViva(String valor, String label) {
    return Column(
      children: [
        Text(valor,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}

const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}
]
''';
          