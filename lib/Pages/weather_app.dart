import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/data/notifiers.dart';
import 'package:weather_app/services/weather_services.dart';
import '../data/constants.dart' as constants;
import '../models/weather_model.dart';

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  late final WeatherServices _weatherService;
  Weather? _weather;


  @override
  void initState() {
    super.initState();
    _weatherService = WeatherServices(dotenv.env['API_KEY']!);
    _loadSavedCity();
  }
  String? _currentCity;
  Future<void> _fetchWeather(String city) async {
    try {
      final weather = await _weatherService.getWeather(city);
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      print("Weather fetch failed: $e");
    }
  }
  Future<void> saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_city', city);
  }
  Future<void> _autoGetCity() async {
    _currentCity = await _weatherService.getCurrentCity(context);
    await _fetchWeather(_currentCity!);
    saveCity(_currentCity!);
  }

  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('saved_city');

    if (savedCity != null && savedCity.isNotEmpty) {
      _currentCity = savedCity;
      await _fetchWeather(savedCity);
    } else {
      await Future.delayed(Duration(seconds: 3));
      await _autoGetCity(); // fallback
    }
  }
  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return '';
    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'assets/Cloudy.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/rainy.json';
      case 'thunderstorm':
        return 'assets/Thunderstorm.json';
      case 'clear':
        return 'assets/sunny.json';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        actions: [
          TextButton(
            onPressed: () async {
              final city = await Navigator.pushNamed(context, '/search') as String?;
              if (city != null && city.isNotEmpty) {
                _currentCity = city;
                await _fetchWeather(_currentCity!);
                saveCity(_currentCity!);
              }
            },
            child: const Text('Change Location'),
          ),
          IconButton(
            onPressed: () async {
              isDarkMode.value = !isDarkMode.value;
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool(constants.Kconst.theme, isDarkMode.value);
            },
            icon: ValueListenableBuilder(
              valueListenable: isDarkMode,
              builder: (context, isDark, child) {
                return Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: () async {
            if (_currentCity != null && _currentCity!.isNotEmpty) {
              print("Refreshing weather for: $_currentCity");
              await _fetchWeather(_currentCity!);
              saveCity(_currentCity!);
              print("Weather refreshed successfully");
            } else {
              print("City not set yet — cannot refresh.");
            }
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              alignment: Alignment.center,
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_weather?.city ?? "Loading city..."),
                if (_weather != null)
                  Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),
                Text(_weather?.mainCondition ?? ""),
                Text('${_weather?.temperature.round() ?? "--"}°C'),
              ],
              ),
            ),
          ),
        ),
       ),
    );
  }
}
