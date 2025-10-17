import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final _collection = FirebaseFirestore.instance.collection('admin');

  Future<Map<String, dynamic>?> buscarPerfil(String uid) async {
    final doc = await _collection.doc(uid).get();
    return doc.data();
  }

  Future<void> salvarPerfil(String uid, Map<String, dynamic> dados) async {
    await _collection.doc(uid).set(dados, SetOptions(merge: true));
  }
}
