import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../database/database_helper.dart';
import '../services/poi_service.dart';
import '../models/trilho.dart';

class AtividadePage extends StatefulWidget {
  final int idCaminhada;
  final Trilho trilho;

  const AtividadePage({super.key, required this.idCaminhada, required this.trilho});

  @override
  AtividadePageState createState() => AtividadePageState();
}

class AtividadePageState extends State<AtividadePage> {
  Position? _lastPos;
  StreamSubscription<Position>? _gpsStream;
  double distanciaTotal = 0.0;
  int segundos = 0;
  Timer? _timer;

  GoogleMapController? _mapController;
  Set<Marker> _poiMarkers = {};
  bool _poisLoaded = false;
  
  List<LatLng> _rotaPredefinida = [];
  final List<LatLng> _rotaRealizada = [];

  void _iniciarTempo() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        segundos++;
      });
    });
  }

  void _carregarRotaPredefinida() {
    try {
      final List decoded = json.decode(widget.trilho.rotaPredefinida);
      _rotaPredefinida = decoded.map((e) => LatLng(e['lat'], e['lon'])).toList();
    } catch (e) {
      // Fallback ou vazio
    }
  }

  void _iniciarGPS() async {
    LocationPermission perm = await Geolocator.requestPermission();

    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return;
    }

    _gpsStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!_poisLoaded) {
        _carregarPOIs(pos.latitude, pos.longitude);
        _poisLoaded = true;
      }
      
      _guardarPonto(pos);
      _atualizarDistancia(pos);
      
      setState(() {
        _rotaRealizada.add(LatLng(pos.latitude, pos.longitude));
      });
      
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
      }
    });
  }
  
  void _carregarPOIs(double lat, double lon) async {
    final pois = await POIService.getPOIs(lat, lon, radius: 2000);
    Set<Marker> markers = {};
    for (int i = 0; i < pois.length; i++) {
      final poi = pois[i];
      double hue = BitmapDescriptor.hueAzure;
      if (poi.type == 'Miradouro') {
        hue = BitmapDescriptor.hueOrange;
      } else if (poi.type == 'Café') {
        hue = BitmapDescriptor.hueYellow;
      } else if (poi.type == 'Restaurante') {
        hue = BitmapDescriptor.hueRed;
      } else if (poi.type == 'Hospital' || poi.type == 'Farmácia') {
        hue = BitmapDescriptor.hueGreen;
      }

      markers.add(
        Marker(
          markerId: MarkerId('poi_\$i'),
          position: LatLng(poi.lat, poi.lon),
          infoWindow: InfoWindow(title: poi.name, snippet: poi.type),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        )
      );
    }
    
    if (mounted) {
      setState(() {
        _poiMarkers = markers;
      });
    }
  }

  void _guardarPonto(Position pos) async {
    final db = DatabaseHelper.instance;
    await db.insertPontoRota({
      'id_caminhada': widget.idCaminhada,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _atualizarDistancia(Position pos) {
    if (_lastPos != null) {
      double metros = Geolocator.distanceBetween(
        _lastPos!.latitude,
        _lastPos!.longitude,
        pos.latitude,
        pos.longitude,
      );
      distanciaTotal += metros;
    }
    _lastPos = pos;
    setState(() {});
  }

  void _terminar() async {
    _gpsStream?.cancel();
    _timer?.cancel();

    final db = DatabaseHelper.instance;

    await db.update(
      'caminhada',
      {
        'distancia_total': distanciaTotal,
        'duracao': segundos.toDouble(),
        'velocidade_media': segundos == 0 ? 0 : distanciaTotal / segundos,
      },
      where: 'id_caminhada = ?',
      whereArgs: [widget.idCaminhada],
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _carregarRotaPredefinida();
    _iniciarTempo();
    _iniciarGPS();
  }

  @override
  void dispose() {
    _gpsStream?.cancel();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Atividade em curso"),
      ),
      body: Column(
        children: [
          Expanded(
            child: _lastPos == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_lastPos!.latitude, _lastPos!.longitude),
                      zoom: 16,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _poiMarkers,
                    polylines: {
                      if (_rotaPredefinida.isNotEmpty)
                        Polyline(
                          polylineId: const PolylineId('rota_pre'),
                          points: _rotaPredefinida,
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.5),
                          width: 5,
                        ),
                      if (_rotaRealizada.isNotEmpty)
                        Polyline(
                          polylineId: const PolylineId('rota_real'),
                          points: _rotaRealizada,
                          color: Colors.greenAccent,
                          width: 6,
                        ),
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.timer, color: Colors.blueAccent),
                        const SizedBox(height: 4),
                        Text(
                          "${segundos ~/ 60}m ${segundos % 60}s",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.route, color: Colors.green),
                        const SizedBox(height: 4),
                        Text(
                          "${(distanciaTotal / 1000).toStringAsFixed(2)} km",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    onPressed: _terminar,
                    child: const Text("Terminar Caminhada", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

