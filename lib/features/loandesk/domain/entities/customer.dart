class Customer {
  final String id;
  final String name;
  final String panNumber;
  final String phoneNumber;
  final String email;
  final String address;
  final DateTime createdDate;

  Customer({
    required this.id,
    required this.name,
    required this.panNumber,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.createdDate,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? panNumber,
    String? phoneNumber,
    String? email,
    String? address,
    DateTime? createdDate,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      panNumber: panNumber ?? this.panNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}
