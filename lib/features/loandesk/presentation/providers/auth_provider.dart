import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/loandesk_user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final LoanDeskUser? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    LoanDeskUser? user,
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  AuthNotifier() : super(AuthState()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (account != null) {
        final user = LoanDeskUser(
          id: account.id,
          name: account.displayName ?? 'Banker',
          email: account.email,
          profilePhoto: account.photoUrl,
          isProfileComplete: false, // In a real app, you would check this against your database
        );
        state = state.copyWith(isLoading: false, user: user, error: null);
      } else {
        state = state.copyWith(isLoading: false, user: null, error: null);
      }
    });
    
    // Attempt silent sign-in
    _googleSignIn.signInSilently();
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _googleSignIn.signIn();

    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google Sign-In failed: $e');
    }
  }

  void completeProfile() {
    if (state.user != null) {
      state = state.copyWith(
        user: state.user!.copyWith(isProfileComplete: true),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _googleSignIn.signOut();
    state = AuthState();
  }
}
