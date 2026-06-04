import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/avatar_helper.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUserProfile({
    required String nickname,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'nickname': nickname,
      'avatarStyle': AvatarHelper.defaultStyle,
      'avatarSeed': nickname.trim().isEmpty
          ? AvatarHelper.defaultSeed
          : nickname.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> getCurrentUserNickname() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Usuário';
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      return 'Usuário';
    }

    final data = doc.data();

    return data?['nickname'] ?? 'Usuário';
  }

  Future<Map<String, dynamic>> getCurrentUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      return {
        'nickname': 'Usuário',
        'avatarStyle': AvatarHelper.defaultStyle,
        'avatarSeed': AvatarHelper.defaultSeed,
      };
    }

    final data = doc.data() ?? {};

    return {
      'nickname': data['nickname'] ?? 'Usuário',
      'avatarStyle': data['avatarStyle'] ?? AvatarHelper.defaultStyle,
      'avatarSeed': data['avatarSeed'] ?? AvatarHelper.defaultSeed,
    };
  }

  Future<void> updateNickname({
    required String nickname,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'nickname': nickname,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfile({
    required String nickname,
    required String avatarStyle,
    required String avatarSeed,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'nickname': nickname,
      'avatarStyle': avatarStyle,
      'avatarSeed': avatarSeed.trim().isEmpty ? nickname : avatarSeed.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getCurrentUserProfile() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return _firestore.collection('users').doc(user.uid).snapshots();
  }
}