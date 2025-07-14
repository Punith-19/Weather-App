import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'package:weather_app/data/notifiers.dart';
import 'package:weather_app/services/weather_services.dart';
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
    _weatherService = WeatherServices(dotenv.env['API_KEY']!); // ✅ Safe access here
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    String city = await _weatherService.getCurrentCity(context);
    try {
      final weather = await _weatherService.getWeather(city);
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      print("Weather fetch failed: $e");
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
              String? city = await _weatherService.getCityFromUser(context);
              if (city != null && city.isNotEmpty) {
                try {
                  final weather = await _weatherService.getWeather(city);
                  setState(() {
                    _weather = weather;
                  });
                } catch (e) {
                  print("Manual weather fetch failed: $e");
                }
              }
            },
            child: const Text('Change Location'),
          ),
          IconButton(
            onPressed: () {
              isDarkMode.value = !isDarkMode.value;
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
        child: SingleChildScrollView(
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
    );
  }
}
