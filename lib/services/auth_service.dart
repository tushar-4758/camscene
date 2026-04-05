import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const [
      'email',
      'https://www.googleapis.com/auth/drive',
    ],
    serverClientId:
    AppConfig.webClientId.isEmpty ? null : AppConfig.webClientId,
  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      await _googleSignIn.signOut();
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('Sign in error: $e');
      return null;
    }
  }

  static Future<GoogleSignInAccount?> silentSignIn() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Silent sign in error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  static Future<http.Client?> getAuthClient() async {
    try {
      final user = _googleSignIn.currentUser ?? await silentSignIn();
      if (user == null) return null;
      final headers = await user.authHeaders;
      return _AuthClient(headers);
    } catch (e) {
      debugPrint('Auth client error: $e');
      return null;
    }
  }
}