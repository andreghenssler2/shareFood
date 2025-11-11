import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Criar conta
  Future<User?> signUp(String email, String senha, String tipo) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );

    final user = userCredential.user;
    if (user != null) {
      // Salvar no Firestore o tipo de usuário
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'tipo': tipo, // admin / ong / parceiro
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  // Login
  Future<User?> signIn(String email, String senha) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );
    return userCredential.user;
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Usuário atual
  User? get currentUser => _auth.currentUser;
}
