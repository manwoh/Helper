import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import 'profile_service.dart';

class AuthResult {
  const AuthResult({
    required this.user,
    required this.session,
  });

  final User? user;
  final Session? session;

  bool get needsEmailConfirmation => user != null && session == null;
  bool get isSignedIn => session != null;
}

class AuthService {
  Stream<AuthState> get authChanges => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user != null) {
      await ProfileService().ensureCurrentProfile();
    }

    return AuthResult(user: response.user, session: response.session);
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );

    if (response.session != null) {
      await ProfileService().ensureCurrentProfile(displayName: displayName);
    }

    return AuthResult(user: response.user, session: response.session);
  }

  Future<void> signOut() => supabase.auth.signOut();
}
