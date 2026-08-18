class LoanDeskUser {
  final String id;
  final String name;
  final String email;
  final String? profilePhoto;
  final bool isProfileComplete;

  LoanDeskUser({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
    this.isProfileComplete = false,
  });

  LoanDeskUser copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePhoto,
    bool? isProfileComplete,
  }) {
    return LoanDeskUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}
