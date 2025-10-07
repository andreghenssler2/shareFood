import 'package:cloud_firestore/cloud_firestore.dart';

class OngService {
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> buscarPerfil(String uid) async {
    final doc = await _firestore.collection('ongs').doc(uid).get();
    return doc.data();
  }

  Future<void> salvarPerfil(String uid, Map<String, dynamic> dados) async {
    await _firestore.collection('ongs').doc(uid).set(dados, SetOptions(merge: true));
  }
}
