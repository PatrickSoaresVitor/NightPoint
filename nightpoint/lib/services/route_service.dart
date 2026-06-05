import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  Future<List<LatLng>> getDrivingRoute({
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

    final coordinates =
        data['routes'][0]['geometry']['coordinates'] as List<dynamic>;

    return coordinates.map((coordinate) {
      final longitude = (coordinate[0] as num).toDouble();
      final latitude = (coordinate[1] as num).toDouble();

      return LatLng(latitude, longitude);
    }).toList();
  }
}