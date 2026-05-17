import 'dart:convert';
import 'package:http/http.dart' as http;

class POI {
  final String name;
  final String type;
  final double lat;
  final double lon;

  POI({required this.name, required this.type, required this.lat, required this.lon});
}

class POIService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  static Future<List<POI>> getPOIs(double lat, double lon, {int radius = 3000}) async {
    // Busca miradouros, cafés, restaurantes, hospitais num raio de 3000m
    final query = '''
      [out:json];
      (
        node["tourism"="viewpoint"](around:$radius, $lat, $lon);
        node["amenity"="cafe"](around:$radius, $lat, $lon);
        node["amenity"="restaurant"](around:$radius, $lat, $lon);
        node["amenity"="hospital"](around:$radius, $lat, $lon);
        node["amenity"="pharmacy"](around:$radius, $lat, $lon);
      );
      out center;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'GeoTrailApp/1.0',
        },
        body: 'data=${Uri.encodeQueryComponent(query)}',
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'] ?? [];
        List<POI> pois = [];

        for (var el in elements) {
          final tags = el['tags'] ?? {};
          final name = tags['name'] ?? 'Ponto sem nome';
          
          String type = 'Outro';
          if (tags['tourism'] == 'viewpoint') type = 'Miradouro';
          else if (tags['amenity'] == 'cafe') type = 'Café';
          else if (tags['amenity'] == 'restaurant') type = 'Restaurante';
          else if (tags['amenity'] == 'hospital') type = 'Hospital';
          else if (tags['amenity'] == 'pharmacy') type = 'Farmácia';

          pois.add(POI(
            name: name,
            type: type,
            lat: el['lat'],
            lon: el['lon'],
          ));
        }
        return pois;
      }
    } catch (e) {
      print('Erro ao buscar POIs: \$e');
    }
    return [];
  }
}
