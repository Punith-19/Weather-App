
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/models/weather_model.dart';
import 'package:geolocator/geolocator.dart';
class WeatherServices{
  static const  BASE_URL = 'https://api.openweathermap.org/data/2.5/weather';
  final String apiKey;
  WeatherServices(this.apiKey);
  Future<Weather> getWeather(String city) async{
    final response = await http.get(Uri.parse('$BASE_URL?q=$city&appid=$apiKey&units=metric'));
    if(response.statusCode == 200){
      return Weather.fromJson(jsonDecode(response.body));
    }
    else{
      throw Exception("Failed to load weather data");
    }
  }
  Future<String?> getCityFromUser(BuildContext context) async {
    TextEditingController controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter City Manually"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "City name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }
  Future<String> getCurrentCity(BuildContext context) async{
    String? city = "";
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied || permission == LocationPermission.deniedForever){
      String? city = await getCityFromUser(context);
      return city ?? "";
    }
    else {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      city = placemarks[0].locality;
    }
    return city ?? "";
  }
}