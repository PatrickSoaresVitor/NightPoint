import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RouteService {
  Future<RouteResult> getDrivingRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$startLongitude,$startLatitude;$endLongitude,$endLatitude'
      '?overview=full&geometries=geojson',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar rota.');
    }

    final data = jsonDecode(response.body);

    if (data['code'] != 'Ok') {
      throw Exception('Rota não encontrada.');
    }

    final route = data['routes'][0];

    final coordinates =
        route['geometry']['coordinates'] as List<dynamic>;

    final points = coordinates.map((coordinate) {
      final longitude = (coordinate[0] as num).toDouble();
      final latitude = (coordinate[1] as num).toDouble();

      return LatLng(latitude, longitude);
    }).toList();

    final distanceMeters = (route['distance'] as num).toDouble();
    final durationSeconds = (route['duration'] as num).toDouble();

    return RouteResult(
      points: points,
      distanceKm: distanceMeters / 1000,
      durationMinutes: durationSeconds / 60,
    );
  }
}