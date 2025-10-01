class Donation {
  final String id;
  final String userId;
  final String name;
  final double quantity;
  final String unit;
  final DateTime validity;
  final String status;
  final DateTime createdAt;

  Donation({
    required this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.validity,
    this.status = "disponível",
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "name": name,
      "quantity": quantity,
      "unit": unit,
      "validity": validity.toIso8601String(),
      "status": status,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory Donation.fromMap(Map<String, dynamic> map, String id) {
    return Donation(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      validity: DateTime.parse(map['validity']),
      status: map['status'] ?? 'disponível',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
