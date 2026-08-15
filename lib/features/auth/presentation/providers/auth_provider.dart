import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tool_hub/core/api/api_config.dart';

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false) {
    _checkInitialAuth();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '129091157986-92ogmcbg3aqpbr00n80oern2r90saps6.apps.googleusercontent.com',
  );

  Future<void> _checkInitialAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_business_logged_in') ?? false;
    state = isLoggedIn;
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        final idToken = auth.idToken;

        if (idToken != null) {
          // Send idToken to backend
          try {
            final response = await http.post(
              Uri.parse('${ApiConfig.baseUrl}/auth/google'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'id_token': idToken}),
            );

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final accessToken = data['access_token'];
              final user = data['user'];
              final needsProfile = user['company_name'] == null ||
                  user['company_name'].toString().isEmpty;

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('auth_token', accessToken);
              await prefs.setBool('is_business_logged_in', true);
              await prefs.setBool('needs_profile', needsProfile);
              await prefs.setString('user_name', user['full_name'] ?? '');
              await prefs.setString('user_email', user['email'] ?? '');
              await prefs.setString('user_pic', user['profile_pic'] ?? '');
              await prefs.setString('company_name', user['company_name'] ?? '');
              if (user['company_logo_url'] != null) {
                String fetchedLogo = user['company_logo_url'];
                if (fetchedLogo.contains('/uploads/')) {
                  fetchedLogo =
                      fetchedLogo.substring(fetchedLogo.indexOf('/uploads/'));
                }
                await prefs.setString('company_logo_url', fetchedLogo);
              }
              state = true;
              return true;
            } else {
              debugPrint(
                  "Backend auth failed: ${response.statusCode} - ${response.body}");
              // Fallback to local only if you want, or return false
            }
          } catch (e) {
            debugPrint("Error connecting to backend for auth: $e");
          }
        }

        // Fallback or if no backend
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_business_logged_in', true);
        state = true;
        return true;
      }
      return false; // User canceled
    } catch (error) {
      debugPrint("Google Sign In Error: $error");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        try {
          await http.post(
            Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (e) {
          debugPrint("Backend logout error: $e");
        }
      }
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_pic');
    await prefs.remove('company_name');
    await prefs.remove('company_address');
    await prefs.remove('phone_number');
    await prefs.remove('whatsapp_number');
    await prefs.remove('gst_number');
    await prefs.remove('business_type');
    await prefs.remove('company_logo_url');
    await prefs.remove('bank_name');
    await prefs.remove('account_name');
    await prefs.remove('account_number');
    await prefs.remove('ifsc_code');
    await prefs.setBool('is_business_logged_in', false);
    state = false;
  }
}
