import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_service.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Future<void> createEvent({
    required String title,
    required String location,
    required String time,
    required String category,
    required String description,
    required double latitude,
    required double longitude,
    required String date,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final nickname = await _userService.getCurrentUserNickname();

    await _firestore.collection('events').add({
      'title': title,
      'location': location,
      'time': time,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'createdBy': user.uid,
      'creatorEmail': user.email,
      'creatorNickname': nickname,
      'createdAt': FieldValue.serverTimestamp(),
      'date': date,
    });
  }
}