class BankCard {
  const BankCard({required this.id, required this.name, required this.last4});

  final int id;
  final String name;
  final String last4;

  factory BankCard.fromJson(Map<String, dynamic> json) {
    return BankCard(
      id: json['id'] as int,
      name: json['name'] as String,
      last4: json['last4'] as String? ?? '',
    );
  }

  String get displayName => last4.isEmpty ? name : '$name •••• $last4';
}
