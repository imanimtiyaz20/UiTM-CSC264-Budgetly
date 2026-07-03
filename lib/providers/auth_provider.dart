import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  bool _isLoading = true;
  String? _error;
  bool _needsGoogleSetup = false;
  AppUser? _pendingGoogleUser;
  fa.User? _pendingFirebaseUser;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;
  bool get needsGoogleSetup => _needsGoogleSetup;
  AppUser? get pendingGoogleUser => _pendingGoogleUser;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(fa.User? firebaseUser) {
    if (firebaseUser == null) {
      _user = null;
      _needsGoogleSetup = false;
      _pendingGoogleUser = null;
      _pendingFirebaseUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _loadUser(firebaseUser.uid);
  }

  Future<void> _loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    _user = await _authService.getUser(uid);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.signInWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(
      String email, String password, String displayName,
      [String currency = 'MYR']) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.registerWithEmail(
          email, password, displayName, currency: currency);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.signInWithGoogle();
    if (result == null) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final appUser = result['user'] as AppUser;
    final isNew = result['isNew'] as bool;

    if (isNew) {
      _pendingGoogleUser = appUser;
      _pendingFirebaseUser = result['firebaseUser'] as fa.User?;
      _needsGoogleSetup = true;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _user = appUser;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> completeGoogleSetup(
      String password, [String currency = 'MYR']) async {
    if (_pendingGoogleUser == null || _pendingFirebaseUser == null) {
      return false;
    }
    _isLoading = true;
    notifyListeners();

    _user = await _authService.completeGoogleSetup(
      appUser: _pendingGoogleUser!,
      password: password,
      firebaseUser: _pendingFirebaseUser!,
      currency: currency,
    );

    _pendingGoogleUser = null;
    _pendingFirebaseUser = null;
    _needsGoogleSetup = false;
    _isLoading = false;
    notifyListeners();
    return _user != null;
  }

  void cancelGoogleSetup() {
    _pendingGoogleUser = null;
    _pendingFirebaseUser = null;
    _needsGoogleSetup = false;
    _authService.signOut();
    notifyListeners();
  }

  Future<bool> updateUser(AppUser updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.updateUser(updatedUser);
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.updatePassword(currentPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _needsGoogleSetup = false;
    _pendingGoogleUser = null;
    _pendingFirebaseUser = null;
    notifyListeners();
  }
}
