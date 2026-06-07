import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AddressSearchResult {
  final String displayName;
  final LatLng position;
  final double? distanceKm;

  const AddressSearchResult({
    required this.displayName,
    required this.position,
    this.distanceKm,
  });
}

class AddressSearchService {
  Future<List<AddressSearchResult>> searchAddresses({
    required String query,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      throw Exception('Digite um endereço para buscar.');
    }

    final improvedQuery = _buildImprovedQuery(cleanQuery);

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(improvedQuery)}'
      '&format=json'
      '&limit=8'
      '&addressdetails=1'
      '&countrycodes=br',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'NightPointApp/1.0',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar endereço.');
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    if (data.isEmpty) {
      throw Exception('Endereço não encontrado.');
    }

    final results = data.map((item) {
      final result = item as Map<String, dynamic>;

      final latitude = double.parse(result['lat'].toString());
      final longitude = double.parse(result['lon'].toString());

      double? distanceKm;

      if (userLatitude != null && userLongitude != null) {
        final distanceMeters = Geolocator.distanceBetween(
          userLatitude,
          userLongitude,
          latitude,
          longitude,
        );

        distanceKm = distanceMeters / 1000;
      }

      return AddressSearchResult(
        displayName: result['display_name']?.toString() ?? cleanQuery,
        position: LatLng(latitude, longitude),
        distanceKm: distanceKm,
      );
    }).toList();

    results.sort((a, b) {
      final distanceA = a.distanceKm;
      final distanceB = b.distanceKm;

      if (distanceA == null && distanceB == null) return 0;
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;

      return distanceA.compareTo(distanceB);
    });

    return results;
  }

  String _buildImprovedQuery(String query) {
    final lowerQuery = query.toLowerCase();

    final hasCity = lowerQuery.contains('franca');
    final hasState = lowerQuery.contains('sp') ||
        lowerQuery.contains('são paulo') ||
        lowerQuery.contains('sao paulo');
    final hasCountry = lowerQuery.contains('brasil') ||
        lowerQuery.contains('brazil');

    final parts = <String>[query];

    if (!hasCity) {
      parts.add('Franca');
    }

    if (!hasState) {
      parts.add('São Paulo');
    }

    if (!hasCountry) {
      parts.add('Brasil');
    }

    return parts.join(', ');
  }
}