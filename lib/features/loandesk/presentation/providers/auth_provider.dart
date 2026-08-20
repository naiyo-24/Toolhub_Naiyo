import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/features/loandesk/data/models/user_model.dart';
import 'package:tool_hub/features/loandesk/data/repositories/auth_repository.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: '129091157986-92ogmcbg3aqpbr00n80oern2r90saps6.apps.googleusercontent.com',
  );

  AuthNotifier(this._authRepository) : super(AuthState()) {
    _initAuth();
  }

  Future<void> _initAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authRepository.getMe();
      state = state.copyWith(isLoading: false, user: user, error: null);
    } catch (e) {
      // If backend fails with 401, token is invalid. Clear it.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      // We should only fallback if it's a network error, but for safety, 
      // if getMe fails, we shouldn't assume the user is logged in if the token is expired.
      // To be safe, if we fail to get the user from the backend, we log them out.
      await prefs.remove('access_token');
      state = state.copyWith(isLoading: false, user: null, error: null);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Force sign out first so the account picker always shows up
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false, error: 'Sign in aborted by user');
        return;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken == null) {
        state = state.copyWith(isLoading: false, error: 'Failed to retrieve ID token');
        return;
      }

      // Send the token to LoanDesk backend
      final authResponse = await _authRepository.loginWithGoogle(idToken);
      UserModel user = authResponse.user;
      
      try {
        final fetchedUser = await _authRepository.getMe();
        user = fetchedUser.copyWith(
          fullName: (fetchedUser.fullName.isEmpty) ? user.fullName : fetchedUser.fullName,
          email: (fetchedUser.email.isEmpty) ? user.email : fetchedUser.email,
          profilePhoto: fetchedUser.profilePhoto ?? user.profilePhoto,
        );
      } catch (_) {}

      // Fallback to Google photo URL if backend profile photo is missing
      if (user.profilePhoto == null && googleUser.photoUrl != null) {
        user = user.copyWith(profilePhoto: googleUser.photoUrl);
      }
      
      state = state.copyWith(isLoading: false, user: user, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _googleSignIn.signOut();
    await _authRepository.logout();
    state = AuthState(); // Reset state
  }

  Future<void> completeProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedUser = await _authRepository.updateProfile(data);
      state = state.copyWith(isLoading: false, user: updatedUser);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to complete profile: $e');
      rethrow;
    }
  }
}
