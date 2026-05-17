import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = 'cfe1ad0ce7a9e13a30256051558b0a21';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    try {
      final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=pt');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erro na API de Meteorologia: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar meteorologia: $e');
      return null;
    }
  }
}
