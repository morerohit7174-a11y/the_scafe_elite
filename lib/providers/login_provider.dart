// lib/providers/auth_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../widgets/db_constants.dart';
import '../widgets/pref_utils.dart';

class LoginProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _error;

  User? get user      => _auth.currentUser;
  bool  get isLoggedIn => _auth.currentUser != null;
  bool  get isLoading => _isLoading;
  String? get error   => _error;

  // ✅ Initialize and restore user session on app start
  Future<bool> restoreSession() async {
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = _auth.currentUser;
      
      if (user != null) {
        // ✅ User is still logged in with Firebase
        // Restore to SharedPreferences for consistency
        await SharedPreferenceUtils.setString(
            DatabaseConstants.userId, user.uid);
        await SharedPreferenceUtils.setString(
            DatabaseConstants.userEmail, user.email ?? '');
        await SharedPreferenceUtils.setBool(
            DatabaseConstants.isLoggedIn, true);
        
        debugPrint("✅ Session restored: ${user.uid}");
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // ✅ No Firebase user, clear SharedPreferences
        await SharedPreferenceUtils.setBool(DatabaseConstants.isLoggedIn, false);
        debugPrint("⚠️ No active session found");
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ restoreSession error: $e");
      _error = "Failed to restore session: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());

      final user = _auth.currentUser;
      if (user != null) {
        // ✅ Save to SharedPreferences with proper error handling
        try {
          await SharedPreferenceUtils.setString(
              DatabaseConstants.userId, user.uid);
          await SharedPreferenceUtils.setString(
              DatabaseConstants.userEmail, user.email ?? '');
          await SharedPreferenceUtils.setBool(
              DatabaseConstants.isLoggedIn, true);
          
          debugPrint("✅ Login successful: ${user.uid}");
          debugPrint("✅ Saved to SharedPreferences: userId=${user.uid}");
        } catch (e) {
          debugPrint("❌ Failed to save to SharedPreferences: $e");
          _error = "Failed to save login data: $e";
          _isLoading = false;
          notifyListeners();
          return "Failed to save login data";
        }
      }

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = e.code;
      notifyListeners();
      
      switch (e.code) {
        case 'user-not-found':    return 'No account found with this email';
        case 'wrong-password':    return 'Incorrect password. Please try again';
        case 'invalid-email':     return 'Please enter a valid email address';
        case 'user-disabled':     return 'This account has been disabled';
        case 'too-many-requests': return 'Too many attempts. Please try again later';
        case 'invalid-credential':return 'Invalid email or password';
        default:                  return 'Login failed: ${e.code}';
      }
    } catch (e) {
      _isLoading = false;
      _error = "Unexpected error: $e";
      notifyListeners();
      return "Unexpected error: $e";
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password.trim());

      final user = _auth.currentUser;
      
      if (user != null) {
        try {
          // ✅ Save user role to Firestore with error handling
          await FirebaseFirestore.instance
              .collection('cafe_elite')
              .doc('data')
              .collection('users')
              .doc(user.uid)
              .set({
            'role': 'admin', // or 'staff'
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          // ✅ Save to SharedPreferences with error handling
          await SharedPreferenceUtils.setString(
              DatabaseConstants.userId, user.uid);
          await SharedPreferenceUtils.setString(
              DatabaseConstants.userEmail, user.email ?? '');
          await SharedPreferenceUtils.setBool(
              DatabaseConstants.isLoggedIn, true);
          
          debugPrint("✅ Registration successful: ${user.uid}");
          debugPrint("✅ User role saved to Firestore");
        } catch (e) {
          debugPrint("❌ Failed to save user data: $e");
          _error = "Failed to save user data: $e";
          _isLoading = false;
          notifyListeners();
          return "Failed to save user data";
        }
      }

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = e.code;
      notifyListeners();
      
      switch (e.code) {
        case 'email-already-in-use': return 'An account already exists with this email';
        case 'weak-password':        return 'Password must be at least 6 characters';
        case 'invalid-email':        return 'Please enter a valid email address';
        case 'operation-not-allowed':return 'Email registration is not enabled';
        default:                     return 'Registration failed: ${e.code}';
      }
    } catch (e) {
      _isLoading = false;
      _error = "Unexpected error: $e";
      notifyListeners();
      return "Unexpected error: $e";
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // ✅ Sign out from Firebase
      await _auth.signOut();
      
      // ✅ Clear SharedPreferences with error handling
      try {
        await SharedPreferenceUtils.setBool(DatabaseConstants.isLoggedIn, false);
        await SharedPreferenceUtils.remove(DatabaseConstants.userId);
        await SharedPreferenceUtils.remove(DatabaseConstants.userEmail);
        debugPrint("✅ SharedPreferences cleared");
      } catch (e) {
        debugPrint("❌ Failed to clear SharedPreferences: $e");
      }
      
      debugPrint("✅ User logged out"); 
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Logout error: $e");
      _error = "Failed to logout: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkSavedLogin() async {
    return await SharedPreferenceUtils.getBool(DatabaseConstants.isLoggedIn);
  }

  Future<String?> getSavedUserId() async {
    return await SharedPreferenceUtils.getString(
        DatabaseConstants.userId);
  }
}