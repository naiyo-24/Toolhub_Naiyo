import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tool_hub/features/loandesk/data/models/banker_profile_model.dart';
import 'package:tool_hub/features/loandesk/data/repositories/banker_repository.dart';

final bankerProvider = StateNotifierProvider<BankerNotifier, AsyncValue<BankerProfileModel?>>((ref) {
  final bankerRepository = ref.watch(bankerRepositoryProvider);
  return BankerNotifier(bankerRepository);
});

class BankerNotifier extends StateNotifier<AsyncValue<BankerProfileModel?>> {
  final BankerRepository _bankerRepository;

  BankerNotifier(this._bankerRepository) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final profile = await _bankerRepository.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, stackTrace) {
      if (e.toString().contains('Profile not found')) {
        // Profile doesn't exist yet
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<void> createProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _bankerRepository.createProfile(data);
      state = AsyncValue.data(profile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final organizationsProvider = FutureProvider<List<OrganizationModel>>((ref) async {
  final repository = ref.watch(bankerRepositoryProvider);
  return repository.getOrganizations();
});
