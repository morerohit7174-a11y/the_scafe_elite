// lib/providers/auth_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../widgets/db_constants.dart';
import '../widgets/pref_utils.dart';

class LoginProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  User? get user      => _auth.currentUser;
  bool  get isLoggedIn => _auth.currentUser != null;

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());

      final user = _auth.currentUser;
      if (user != null) {
        await SharedPreferenceUtils.setString(
            DatabaseConstants.userId, user.uid);
        await SharedPreferenceUtils.setString(
            DatabaseConstants.userEmail, user.email ?? '');
        await SharedPreferenceUtils.setBool(
            DatabaseConstants.isLoggedIn, true);
      }

      notifyListeners();
      return null; 
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':    return 'No account found with this email';
        case 'wrong-password':    return 'Incorrect password. Please try again';
        case 'invalid-email':     return 'Please enter a valid email address';
        case 'user-disabled':     return 'This account has been disabled';
        case 'too-many-requests': return 'Too many attempts. Please try again later';
        case 'invalid-credential':return 'Invalid email or password';
        default:                  return 'Login failed. Please try again';
      }
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password.trim());

      final user = _auth.currentUser;
      
      if (user != null) {
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
        await SharedPreferenceUtils.setString(
            DatabaseConstants.userId, user.uid);
        await SharedPreferenceUtils.setString(
            DatabaseConstants.userEmail, user.email ?? '');
        await SharedPreferenceUtils.setBool(
            DatabaseConstants.isLoggedIn, true);
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use': return 'An account already exists with this email';
        case 'weak-password':        return 'Password must be at least 6 characters';
        case 'invalid-email':        return 'Please enter a valid email address';
        case 'operation-not-allowed':return 'Email registration is not enabled';
        default:                     return 'Registration failed. Please try again';
      }
    }
  }

  Future<void> logout() async {
   await _auth.signOut(); 
    await SharedPreferenceUtils.setBool(DatabaseConstants.isLoggedIn, false);
    await SharedPreferenceUtils().clearData(); // Clear all user-related data
    notifyListeners();
  }

  Future<bool> checkSavedLogin() async {
    return await SharedPreferenceUtils.getBool(DatabaseConstants.isLoggedIn);
  }

  Future<String?> getSavedUserId() async {
    return await SharedPreferenceUtils.getString(
        DatabaseConstants.userId);
  }
}