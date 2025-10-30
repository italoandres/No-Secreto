import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificacoesRepository {
  static Future<void> updateUserFcmToken({
    required String token,
  }) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'fcmTokem': token,
    });
  }
}
