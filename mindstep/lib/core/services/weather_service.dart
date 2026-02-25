import 'dart:convert';
import 'package:http/http.dart' as http;

/// Dati meteo semplificati per la home
class WeatherData {
  const WeatherData({
    required this.tempC,
    required this.description,
    required this.weatherCode,
    required this.city,
  });

  final double tempC;
  final String description;
  final int weatherCode; // WMO code da wttr.in
  final String city;

  /// Restituisce l'emoji meteo in base al codice WMO
  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 2) return '⛅';
    if (weatherCode <= 9) return '🌫️';
    if (weatherCode <= 19) return '🌧️';
    if (weatherCode <= 29) return '🌩️';
    if (weatherCode <= 39) return '🌫️';
    if (weatherCode <= 49) return '🌫️';
    if (weatherCode <= 59) return '🌦️';
    if (weatherCode <= 69) return '🌧️';
    if (weatherCode <= 79) return '❄️';
    if (weatherCode <= 84) return '🌧️';
    if (weatherCode <= 94) return '⛈️';
    return '🌩️';
  }

  String get tempFormatted => '${tempC.round()}°C';
}

class WeatherService {
  WeatherData? _cached;
  DateTime? _cacheTime;

  /// Recupera il meteo via wttr.in (no API key richiesta)
  Future<WeatherData?> getWeather(double lat, double lon) async {
    // Cache di 30 minuti
    if (_cached != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!).inMinutes < 30) {
        return _cached;
      }
    }

    try {
      final url =
          'https://wttr.in/$lat,$lon?format=j1&lang=it';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = (json['current_condition'] as List).first
          as Map<String, dynamic>;
      final nearestArea =
          (json['nearest_area'] as List).first as Map<String, dynamic>;

      final tempC =
          double.tryParse(current['temp_C'] as String? ?? '0') ?? 0;
      final code = int.tryParse(
              current['weatherCode'] as String? ?? '0') ??
          0;
      final descList = current['weatherDesc'] as List?;
      final desc = descList != null && descList.isNotEmpty
          ? (descList.first as Map<String, dynamic>)['value'] as String? ?? ''
          : '';

      final areaList = nearestArea['areaName'] as List?;
      final city = areaList != null && areaList.isNotEmpty
          ? (areaList.first as Map<String, dynamic>)['value'] as String? ?? ''
          : '';

      _cached = WeatherData(
        tempC: tempC,
        description: desc,
        weatherCode: code,
        city: city,
      );
      _cacheTime = DateTime.now();
      return _cached;
    } catch (_) {
      return null;
    }
  }
}
