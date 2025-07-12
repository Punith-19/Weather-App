import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:weather_app/services/weather_services.dart';

import '../models/weather_model.dart';
class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final _weatherService = WeatherServices('4a56654574f1801aa38b47e69db74875');
  Weather? _weather;
  _fetchWeather() async{
    String city = await _weatherService.getCurrentCity();
    try{
      final weather = await _weatherService.getWeather(city);
      setState(() {
        _weather = weather;
      });
    }
    catch (e){
      print(e);
    }
  }
  String getWeatherAnimation(String? mainCondition){
    if(mainCondition == null) return '';
    switch(mainCondition.toLowerCase()){
      case 'clouds' :
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'assets/Cloudy.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/rainy. json';
      case 'thunderstorm':
        return 'assets/Thunderstorm.json';
      case 'clear':
        return 'assets/sunny. json';
      default:
        return '';
    }
  }
  @override
  void initState(){
    super.initState();
    _fetchWeather();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_weather?.city ?? "loading city.."),
                Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),
                Text(_weather?.mainCondition ?? ""),
                Text('${_weather?.temperature.round()}C'),
                

              ],
          ),
        ),
    );
  }
}
