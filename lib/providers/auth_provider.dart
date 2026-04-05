import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  GoogleSignInAccount? _user;
  bool _loading = true;

  GoogleSignInAccount? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _loading;
  String get email => _user?.email ?? '';
  String? get photoUrl => _user?.photoUrl;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    _user = await AuthService.silentSignIn();
    _loading = false;
    notifyListeners();
  }

  Future<void> signIn() async {
    _loading = true;
    notifyListeners();
    _user = await AuthService.signIn();
    _loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _user = null;
    notifyListeners();
  }
}