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
    required String model3dType,
    required String model3dUrl,
  }) async {
    await _firestore.collection('garages').doc(userId).set({
      'userId': userId,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'category': category,
      'model3dType': model3dType,
      'model3dUrl': model3dUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getGarage() {
    return _firestore.collection('garages').doc(userId).snapshots();
  }
}