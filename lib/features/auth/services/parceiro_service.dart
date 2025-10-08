import 'package:cloud_firestore/cloud_firestore.dart';

class ParceiroService {
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> buscarPerfil(String uid) async {
    final doc = await _firestore.collection('parceiros').doc(uid).get();
    if (doc.exists) return doc.data();
    return null;
  }

  Future<void> salvarPerfil(String uid, Map<String, dynamic> dados) async {
    await _firestore.collection('parceiros').doc(uid).set(dados, SetOptions(merge: true));
  }
}
