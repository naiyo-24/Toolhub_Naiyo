class Customer {
  final String id;
  final String name; // maps to fullName in DB, or we can leave as name
  final String panNumber;
  final String phoneNumber;
  final String email;
  final String address;
  final DateTime createdDate;
  
  // New fields
  final DateTime? dob;
  final String? occupation;
  final String? legalName;
  final String? businessName;
  final String? businessType;
  final String? udyamNumber;
  final String? gstin;

  Customer({
    required this.id,
    required this.name,
    required this.panNumber,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.createdDate,
    this.dob,
    this.occupation,
    this.legalName,
    this.businessName,
    this.businessType,
    this.udyamNumber,
    this.gstin,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'].toString(),
      name: json['full_name'] ?? json['fullName'] ?? json['name'] ?? '',
      panNumber: json['pan'] ?? '',
      phoneNumber: json['mobile'] ?? json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      createdDate: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      occupation: json['occupation'],
      legalName: json['legal_name'],
      businessName: json['business_name'],
      businessType: json['business_type'],
      udyamNumber: json['udyam_number'],
      gstin: json['gstin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_name': name,
      'pan': panNumber,
      'mobile': phoneNumber,
      'email': email,
      'address': address,
      'created_at': createdDate.toIso8601String(),
      if (dob != null) 'dob': dob!.toIso8601String().split('T').first,
      if (occupation != null) 'occupation': occupation,
      if (legalName != null) 'legal_name': legalName,
      if (businessName != null) 'business_name': businessName,
      if (businessType != null) 'business_type': businessType,
      if (udyamNumber != null) 'udyam_number': udyamNumber,
      if (gstin != null) 'gstin': gstin,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? panNumber,
    String? phoneNumber,
    String? email,
    String? address,
    DateTime? createdDate,
    DateTime? dob,
    String? occupation,
    String? legalName,
    String? businessName,
    String? businessType,
    String? udyamNumber,
    String? gstin,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      panNumber: panNumber ?? this.panNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      createdDate: createdDate ?? this.createdDate,
      dob: dob ?? this.dob,
      occupation: occupation ?? this.occupation,
      legalName: legalName ?? this.legalName,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      udyamNumber: udyamNumber ?? this.udyamNumber,
      gstin: gstin ?? this.gstin,
    );
  }
}
