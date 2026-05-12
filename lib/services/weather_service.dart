import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // For demo purposes, you can get a free API key from: https://openweathermap.org/api
  static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get weather data by coordinates
  static Future<Map<String, dynamic>?> getWeatherByCoordinates(
      double lat, double lon) async {
    try {
      // If API key is not set, return dummy data
      if (_apiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
        return _getDummyWeatherData();
      }

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Weather API error: ${response.statusCode}');
        return _getDummyWeatherData();
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return _getDummyWeatherData();
    }
  }

  // Get weather data by city name (fallback)
  static Future<Map<String, dynamic>?> getWeatherByCity(String cityName) async {
    try {
      // If API key is not set, return dummy data
      if (_apiKey == 'YOUR_OPENWEATHERMAP_API_KEY') {
        return _getDummyWeatherData();
      }

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Weather API error: ${response.statusCode}');
        return _getDummyWeatherData();
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return _getDummyWeatherData();
    }
  }

  // Get current temperature
  static Future<Map<String, dynamic>?> getCurrentTemperature() async {
    try {
      final position = await getCurrentPosition();
      
      if (position != null) {
        // Try to get weather by coordinates
        final weatherData = await getWeatherByCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (weatherData != null && !weatherData['is_dummy']) {
          return {
            'temp': weatherData['main']['temp'],
            'description': weatherData['weather'][0]['description'],
            'location': weatherData['name'],
            'humidity': weatherData['main']['humidity'],
            'wind_speed': weatherData['wind']['speed'],
            'icon': weatherData['weather'][0]['icon'],
            'is_default': false
          };
        }
      }
      
      // Fallback to Lahore weather (Pakistan)
      final lahoreWeather = await getWeatherByCity('Lahore');
      if (lahoreWeather != null && !lahoreWeather['is_dummy']) {
        return {
          'temp': lahoreWeather['main']['temp'],
          'description': lahoreWeather['weather'][0]['description'],
          'location': lahoreWeather['name'],
          'humidity': lahoreWeather['main']['humidity'],
          'wind_speed': lahoreWeather['wind']['speed'],
          'icon': lahoreWeather['weather'][0]['icon'],
          'is_default': false
        };
      }
      
      // If all else fails, return dummy data
      return _getDummyWeatherData();
      
    } catch (e) {
      print('Error getting temperature: $e');
      return _getDummyWeatherData();
    }
  }

  // Dummy weather data for immediate UI testing
  static Map<String, dynamic> _getDummyWeatherData() {
    return {
      'temp': 28.0,
      'description': 'Partly cloudy',
      'location': 'Lahore',
      'humidity': 65,
      'wind_speed': 12.0,
      'icon': '02d',
      'is_default': true,
      'is_dummy': true
    };
  }

  // Get weather icon URL
  static String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  // Check if API key is configured
  static bool isApiKeyConfigured() {
    return _apiKey != 'YOUR_OPENWEATHERMAP_API_KEY';
  }
}
