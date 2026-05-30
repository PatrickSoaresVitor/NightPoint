import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createEvent({
    required String title,
    required String location,
    required String time,
    required String category,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    await _firestore.collection('events').add({
      'title': title,
      'location': location,
      'time': time,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}