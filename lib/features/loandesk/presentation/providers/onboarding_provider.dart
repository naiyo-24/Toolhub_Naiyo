import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  // Personal
  final String fullName;
  final String mobileNumber;
  final String email;
  final DateTime? dateOfBirth;

  // Professional
  final String role;
  final String designation;
  final String experience;
  final String employeeId;

  // Organization
  final String orgType;
  final String orgName;
  final String branchName;
  final String branchCode;
  final String city;
  final String state;
  final String officeContact;

  // Preferences
  final List<String> loanTypes;
  final String currency;

  OnboardingState({
    this.fullName = '',
    this.mobileNumber = '',
    this.email = '',
    this.dateOfBirth,
    this.role = 'Bank Manager',
    this.designation = '',
    this.experience = '',
    this.employeeId = '',
    this.orgType = 'Bank',
    this.orgName = '',
    this.branchName = '',
    this.branchCode = '',
    this.city = '',
    this.state = '',
    this.officeContact = '',
    this.loanTypes = const [],
    this.currency = '₹ INR',
  });

  OnboardingState copyWith({
    String? fullName,
    String? mobileNumber,
    String? email,
    DateTime? dateOfBirth,
    String? role,
    String? designation,
    String? experience,
    String? employeeId,
    String? orgType,
    String? orgName,
    String? branchName,
    String? branchCode,
    String? city,
    String? state,
    String? officeContact,
    List<String>? loanTypes,
    String? currency,
  }) {
    return OnboardingState(
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      designation: designation ?? this.designation,
      experience: experience ?? this.experience,
      employeeId: employeeId ?? this.employeeId,
      orgType: orgType ?? this.orgType,
      orgName: orgName ?? this.orgName,
      branchName: branchName ?? this.branchName,
      branchCode: branchCode ?? this.branchCode,
      city: city ?? this.city,
      state: state ?? this.state,
      officeContact: officeContact ?? this.officeContact,
      loanTypes: loanTypes ?? this.loanTypes,
      currency: currency ?? this.currency,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void updateField({
    String? fullName,
    String? mobileNumber,
    String? email,
    DateTime? dateOfBirth,
    String? role,
    String? designation,
    String? experience,
    String? employeeId,
    String? orgType,
    String? orgName,
    String? branchName,
    String? branchCode,
    String? city,
    String? state,
    String? officeContact,
    String? currency,
  }) {
    this.state = this.state.copyWith(
      fullName: fullName,
      mobileNumber: mobileNumber,
      email: email,
      dateOfBirth: dateOfBirth,
      role: role,
      designation: designation,
      experience: experience,
      employeeId: employeeId,
      orgType: orgType,
      orgName: orgName,
      branchName: branchName,
      branchCode: branchCode,
      city: city,
      state: state,
      officeContact: officeContact,
      currency: currency,
    );
  }

  void toggleLoanType(String type) {
    final currentTypes = List<String>.from(state.loanTypes);
    if (currentTypes.contains(type)) {
      currentTypes.remove(type);
    } else {
      currentTypes.add(type);
    }
    state = state.copyWith(loanTypes: currentTypes);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
