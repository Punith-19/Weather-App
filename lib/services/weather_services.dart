import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/models/weather_model.dart';
import 'package:location/location.dart' as loc; // alias to avoid conflict
import 'package:geocoding/geocoding.dart';

class WeatherServices {
  static const BASE_URL = 'https://api.openweathermap.org/data/2.5/weather';
  final String apiKey;

  WeatherServices(this.apiKey);

  // Fetch weather by city name
  Future<Weather> getWeather(String city) async {
    final response = await http.get(
      Uri.parse('$BASE_URL?q=$city&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load weather data");
    }
  }

  // Get user's current city from device location
  Future<String?> getCurrentCity(BuildContext context) async {
    try {
      final location = loc.Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return null;
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return null;
      }

      loc.LocationData? locationData;
      int retries = 0;
      while (locationData == null && retries < 5) {
        locationData = await location.getLocation();
        await Future.delayed(Duration(seconds: 1));
        retries++;
      }

      if (locationData != null) {
        final lat = locationData.latitude;
        final lon = locationData.longitude;

        final response = await http.get(Uri.parse(
            'https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey'));

        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          if (data.isNotEmpty) return data[0]['name'];
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't get location. Try using search."),
        ),
      );
    } catch (e) {
      print("Error getting current city: $e");
    }

    return null;
  }
}
