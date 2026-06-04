import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GarageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user.uid;
  }

  Future<void> saveGarage({
    required String brand,
    required String model,
    required String year,
    required String color,
    required String category,
  }) async {
    await _firestore.collection('garages').doc(userId).set({
      'userId': userId,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getGarage() {
    return _firestore.collection('garages').doc(userId).snapshots();
  }
}