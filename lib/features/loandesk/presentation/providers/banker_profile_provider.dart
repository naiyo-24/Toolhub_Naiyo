import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/core/network/api_client_provider.dart';

class BankerProfile {
  final String? mobile;
  final String? role;
  final String? designation;
  final String? employeeId;
  final int? experienceYears;
  final String? orgType;
  final String? orgName;
  final String? branchName;
  final String? city;
  final String? stateRegion;
  final String? loanTypes;

  BankerProfile({
    this.mobile,
    this.role,
    this.designation,
    this.employeeId,
    this.experienceYears,
    this.orgType,
    this.orgName,
    this.branchName,
    this.city,
    this.stateRegion,
    this.loanTypes,
  });

  factory BankerProfile.fromJson(Map<String, dynamic> json) {
    String? parsedLoanTypes;
    if (json['loan_types'] is List) {
      parsedLoanTypes = (json['loan_types'] as List).join(', ');
    } else {
      parsedLoanTypes = json['loan_types']?.toString();
    }

    return BankerProfile(
      mobile: json['mobile'],
      role: json['role'],
      designation: json['designation'],
      employeeId: json['employee_id'],
      experienceYears: json['experience_years'],
      orgType: json['org_type'],
      orgName: json['org_name'],
      branchName: json['branch_name'],
      city: json['city'],
      stateRegion: json['state_region'],
      loanTypes: parsedLoanTypes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'role': role,
      'designation': designation,
      'employee_id': employeeId,
      'experience_years': experienceYears,
      'org_type': orgType,
      'org_name': orgName,
      'branch_name': branchName,
      'city': city,
      'state_region': stateRegion,
      'loan_types': loanTypes,
    };
  }
}

final bankerProfileProvider = StateNotifierProvider<BankerProfileNotifier, AsyncValue<BankerProfile?>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BankerProfileNotifier(apiClient);
});

class BankerProfileNotifier extends StateNotifier<AsyncValue<BankerProfile?>> {
  final dynamic _apiClient; // Using dynamic because ApiClient type might not be directly imported easily here without knowing the exact path

  BankerProfileNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/api/v1/banker/profile');
      if (response.statusCode == 200) {
        state = AsyncValue.data(BankerProfile.fromJson(response.data));
      } else {
        // If profile not found, maybe return a null profile or let them create one
        state = const AsyncValue.data(null);
      }
    } catch (e, stackTrace) {
      // 404 means it doesn't exist yet
      if (e.toString().contains('404')) {
         state = const AsyncValue.data(null);
      } else {
         state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<void> updateProfile(BankerProfile profile) async {
    try {
      // Determine if we should POST (create) or PATCH (update)
      final hasExisting = state.valueOrNull != null;
      final response = hasExisting 
          ? await _apiClient.patch('/api/v1/banker/profile', data: profile.toJson())
          : await _apiClient.post('/api/v1/banker/profile', data: profile.toJson());
          
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = AsyncValue.data(BankerProfile.fromJson(response.data));
      }
    } catch (e) {
      throw e;
    }
  }
}
