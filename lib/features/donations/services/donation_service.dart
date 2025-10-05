import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/auth_service.dart';
import '../models/donation_model.dart';
import 'package:uuid/uuid.dart';

class DonationService {
  final _db = FirebaseFirestore.instance;
  final _auth = AuthService();

  Future<void> addDonation(Donation donation) async {
    await _db.collection('donations').doc(donation.id).set(donation.toMap());
  }

  Stream<List<Donation>> getUserDonations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }
    return _db
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Donation.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  String generateId() => const Uuid().v4();
}
