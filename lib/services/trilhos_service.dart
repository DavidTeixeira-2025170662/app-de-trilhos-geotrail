import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/trilho.dart';

class TrilhosService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  static Future<List<Trilho>> getTrilhosProximos(double lat, double lon, {double radius = 20000}) async {
    final query = '''
      [out:json];
      relation["route"="hiking"](around:$radius, $lat, $lon);
      out geom;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'GeoTrailApp/1.0',
        },
        body: 'data=${Uri.encodeQueryComponent(query)}',
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        List<Trilho> trilhos = [];

        for (var el in elements) {
          if (el['type'] == 'relation') {
            final tags = el['tags'] ?? {};
            final members = el['members'] ?? [];

            String nome = tags['name'] ?? 'Trilho Desconhecido';
            double distancia = 0.0;
            
            if (tags.containsKey('distance')) {
              try {
                String dstr = tags['distance'].toString().replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
                distancia = double.parse(dstr);
              } catch (e) {}
            }

            String descricao = tags['description'] ?? 'Trilho descoberto através do OpenStreetMap.';

            List<Map<String, double>> rotaPontos = [];
            
            for (var member in members) {
              if (member['type'] == 'way' && member['geometry'] != null) {
                for (var geom in member['geometry']) {
                  rotaPontos.add({'lat': geom['lat'], 'lon': geom['lon']});
                }
              }
            }

            if (rotaPontos.isEmpty) continue;

            if (distancia == 0.0 && rotaPontos.length > 1) {
              for (int i = 0; i < rotaPontos.length - 1; i++) {
                distancia += Geolocator.distanceBetween(
                  rotaPontos[i]['lat']!, rotaPontos[i]['lon']!,
                  rotaPontos[i+1]['lat']!, rotaPontos[i+1]['lon']!
                );
              }
              distancia = distancia / 1000.0;
            }

            // Ignorar caminhos gigantescos (ex: Caminho de Santiago completo ou Grandes Rotas Nacionais)
            if (distancia > 100.0) continue;

            String dificuldade = tags['sac_scale'] ?? tags['caminando:dificultad'] ?? 'Desconhecido';
            if (dificuldade.contains('hiking')) dificuldade = 'Fácil';
            else if (dificuldade.contains('mountain')) dificuldade = 'Média';
            else if (dificuldade.contains('alpine')) dificuldade = 'Difícil';
            else {
              if (distancia < 7.0) dificuldade = 'Fácil';
              else if (distancia < 15.0) dificuldade = 'Média';
              else dificuldade = 'Difícil';
            }

            double desnivel = 0.0;
            if (tags.containsKey('ascent')) {
              try {
                desnivel = double.parse(tags['ascent'].toString().replaceAll(RegExp(r'[^0-9.]'), ''));
              } catch(e) {}
            }
            if (desnivel == 0.0) {
              desnivel = distancia * 15.0;
            }

            String coordenadas = "${rotaPontos.first['lat']}, ${rotaPontos.first['lon']}";
            String rotaPredefinida = json.encode(rotaPontos);
            
            trilhos.add(
              Trilho(
                id: el['id'],
                nome: nome,
                distancia: distancia,
                dificuldade: dificuldade,
                descricao: descricao,
                coordenadas: coordenadas,
                desnivel: desnivel,
                imagem: Uint8List(0),
                rotaPredefinida: rotaPredefinida,
              )
            );
          }
        }
        
        return trilhos;
      }
    } catch (e) {
      print('Erro ao buscar trilhos reais: $e');
    }
    
    return [];
  }
}
