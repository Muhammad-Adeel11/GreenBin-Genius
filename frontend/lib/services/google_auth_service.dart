/// GreenBin Genius – Google Auth Service
/// Handles Google Sign-In OAuth flow and backend token verification.
/// Used in the Claim Account flow to verify a real Gmail address.

import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class GoogleAuthService {
  GoogleAuthService._();

  // Web Client ID from Google Cloud Console (type 3 in google-services.json)
  // Required on Android to receive an idToken
  static const String _webClientId =
      '765275404655-r49q8li2knel95shk0g0iqooundd5c2s.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: ['email', 'profile'],
  );

  /// Triggers the Google Sign-In popup.
  /// Returns the [GoogleSignInAccount] on success, or null if cancelled.
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      // Always sign out first to force account picker
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      return null;
    }
  }

  /// Extracts the Google ID token from the signed-in account.
  /// This token is sent to the backend for real verification.
  static Future<String?> getIdToken(GoogleSignInAccount account) async {
    try {
      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      return null;
    }
  }

  /// Full flow: sign in → get token → verify with backend → claim account.
  /// Returns the backend response (new JWT + user info) on success.
  static Future<Map<String, dynamic>> signInAndClaim({
    String? username,
  }) async {
    // Step 1: Trigger Google Sign-In
    final account = await signIn();
    if (account == null) throw Exception('Google Sign-In was cancelled.');

    // Step 2: Get the ID token
    final idToken = await getIdToken(account);
    if (idToken == null) {
      throw Exception('Failed to get Google ID token. Please try again.');
    }

    // Step 3: Send to backend for real verification and account claim
    return ApiService.instance.verifyGoogleAndClaim(
      idToken: idToken,
      username: username,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  /// Sign out of Google (called on app logout)
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
