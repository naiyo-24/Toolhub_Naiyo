class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePhoto;
  final bool isProfileComplete;
  
  // Onboarding Fields
  final String? mobileNumber;
  final DateTime? dateOfBirth;
  final String? loandeskRole;
  final String? designation;
  final String? experienceYears;
  final String? employeeId;
  final String? orgType;
  final String? orgName;
  final String? branchName;
  final String? city;
  final String? stateRegion;
  final List<String>? loanTypes;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.profilePhoto,
    this.isProfileComplete = false,
    this.mobileNumber,
    this.dateOfBirth,
    this.loandeskRole,
    this.designation,
    this.experienceYears,
    this.employeeId,
    this.orgType,
    this.orgName,
    this.branchName,
    this.city,
    this.stateRegion,
    this.loanTypes,
  });

  String get name => fullName;

  static DateTime? _safeParseDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isActive: json['is_active'] ?? true,
      createdAt: _safeParseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _safeParseDate(json['updated_at']) ?? DateTime.now(),
      profilePhoto: json['profile_photo'] ?? json['profile_pic'],
      isProfileComplete: (json['is_profile_complete'] == true) || (json['designation'] != null && json['employee_id'] != null),
      mobileNumber: (json['mobile'] ?? json['phone_number'] ?? json['mobile_number'])?.toString(),
      dateOfBirth: _safeParseDate(json['date_of_birth']),
      loandeskRole: json['role']?.toString() ?? json['loandesk_role']?.toString(),
      designation: json['designation']?.toString(),
      experienceYears: json['experience_years']?.toString(),
      employeeId: json['employee_id']?.toString(),
      orgType: json['org_type']?.toString(),
      orgName: json['org_name']?.toString(),
      branchName: json['branch_name']?.toString(),
      city: json['city']?.toString(),
      stateRegion: json['state_region']?.toString(),
      loanTypes: json['loan_types'] != null ? List<String>.from(json['loan_types']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile_photo': profilePhoto,
      'is_profile_complete': isProfileComplete,
      'mobile': mobileNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'role': loandeskRole,
      'designation': designation,
      'experience_years': experienceYears,
      'employee_id': employeeId,
      'org_type': orgType,
      'org_name': orgName,
      'branch_name': branchName,
      'city': city,
      'state_region': stateRegion,
      'loan_types': loanTypes,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePhoto,
    bool? isProfileComplete,
    String? mobileNumber,
    DateTime? dateOfBirth,
    String? loandeskRole,
    String? designation,
    String? experienceYears,
    String? employeeId,
    String? orgType,
    String? orgName,
    String? branchName,
    String? city,
    String? stateRegion,
    List<String>? loanTypes,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      loandeskRole: loandeskRole ?? this.loandeskRole,
      designation: designation ?? this.designation,
      experienceYears: experienceYears ?? this.experienceYears,
      employeeId: employeeId ?? this.employeeId,
      orgType: orgType ?? this.orgType,
      orgName: orgName ?? this.orgName,
      branchName: branchName ?? this.branchName,
      city: city ?? this.city,
      stateRegion: stateRegion ?? this.stateRegion,
      loanTypes: loanTypes ?? this.loanTypes,
    );
  }
}
