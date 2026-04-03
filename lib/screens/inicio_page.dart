import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'caminhada_page.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  GoogleMapController? _mapController;
  LatLng? _posicaoAtual;
  StreamSubscription<Position>? _positionSub;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _iniciarLocalizacao();
  }

  Future<void> _iniciarLocalizacao() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    // Obter posição inicial
    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _posicaoAtual = LatLng(pos.latitude, pos.longitude));
    }

    // Seguir posição em tempo real
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _posicaoAtual = latLng);
      if (_mapReady && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(latLng));
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Mapa compacto no topo ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 320,
                  child: _posicaoAtual == null
                      ? Container(
                          color: const Color(0xFF1E1E1E),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                    color: Colors.deepPurpleAccent),
                                SizedBox(height: 12),
                                Text('A obter localização...',
                                    style: TextStyle(color: Colors.white54)),
                              ],
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _posicaoAtual!,
                                zoom: 16,
                              ),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              onMapCreated: (controller) {
                                _mapController = controller;
                                _mapReady = true;
                                controller.setMapStyle(_darkMapStyle);
                              },
                            ),
                            // Botão centrar
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: FloatingActionButton.small(
                                heroTag: 'centerBtn',
                                backgroundColor: const Color(0xFF1E1E1E),
                                onPressed: () {
                                  if (_posicaoAtual != null &&
                                      _mapController != null) {
                                    _mapController!.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                          _posicaoAtual!, 16),
                                    );
                                  }
                                },
                                child: Icon(Icons.my_location_rounded,
                                    color: accent),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Conteúdo abaixo do mapa ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'O que queres fazer?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Botão Iniciar Caminhada
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions_walk_rounded,
                            size: 24),
                        label: const Text('Iniciar Caminhada',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: accent.withOpacity(0.4),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CaminhadaPage()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estilo JSON do Google Maps para tema escuro
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