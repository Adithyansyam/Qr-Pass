import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onam_pass/utils/constants.dart';

/// Handles all Supabase Auth operations.
class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Current signed-in user, or null if not authenticated.
  static User? get currentUser => _client.auth.currentUser;

  /// Returns the current user's UUID, or null.
  static String? get currentUserId => currentUser?.id;

  /// Returns the current user's email, or null.
  static String? get currentUserEmail => currentUser?.email;

  /// Returns true if a staff member is currently logged in.
  static bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes.
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  /// Sign in with email and password.
  /// Throws [AuthException] on failure.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
