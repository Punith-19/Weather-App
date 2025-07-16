import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class SearchCity extends StatefulWidget {
  const SearchCity({super.key});

  @override
  State<SearchCity> createState() => _SearchCityState();
}

class _SearchCityState extends State<SearchCity> {
  final TextEditingController controller = TextEditingController();
  List<String> suggestions = [];
  Timer? _debounce;

  void fetchSuggestions(String input) async {
    if (input.length < 2) {
      setState(() => suggestions = []);
      return;
    }

    final apiKey = dotenv.env['API_KEY']!;
    final url =
        'https://api.openweathermap.org/geo/1.0/direct?q=$input&limit=5&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          suggestions = data
              .map<String>((e) => "${e['name']}, ${e['country']}")
              .toSet()
              .toList();
        });
      } else {
        setState(() => suggestions = []);
      }
    } catch (e) {
      print("Suggestion fetch failed: $e");
      setState(() => suggestions = []);
    }
  }

  Future<void> useCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied.')),
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      final city = placemarks.first.locality;

      if (city != null && city.isNotEmpty) {
        Navigator.pop(context, city);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine city.')),
        );
      }
    } catch (e) {
      print("Location fetch error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error getting location')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        fetchSuggestions(controller.text.trim());
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search City")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Enter city name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: useCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text("Use Current Location"),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    title: Text(suggestion),
                    onTap: () {
                      final cityName = suggestion.split(',')[0];
                      Navigator.pop(context, cityName);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
