import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:corn_disease_app/config/firebase_config.dart';
import 'package:flutter/foundation.dart';
class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: FirebaseConfig.webConfig['apiKey']!,
        authDomain: FirebaseConfig.webConfig['authDomain']!,
        projectId: FirebaseConfig.webConfig['projectId']!,
        storageBucket: FirebaseConfig.webConfig['storageBucket']!,
        messagingSenderId: FirebaseConfig.webConfig['messagingSenderId']!,
        appId: FirebaseConfig.webConfig['appId']!,
      ),
    );
  }

  // Google Sign-In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In...');
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      debugPrint('Google Sign-In successful!');
      return userCredential;
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
      return null;
    }
  }

  // Email/Password Registration with error handling
  static Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        debugPrint('Email/Password authentication is disabled in Firebase Console');
        throw Exception('Email/Password registration is currently disabled. Please use Google Sign-In.');
      } else if (e.code == 'email-already-in-use') {
        debugPrint('Email already in use');
        throw Exception('This email is already registered. Please sign in instead.');
      } else if (e.code == 'weak-password') {
        debugPrint('Weak password');
        throw Exception('Password is too weak. Please use a stronger password.');
      } else if (e.code == 'invalid-email') {
        debugPrint('Invalid email');
        throw Exception('Please enter a valid email address.');
      } else {
        debugPrint('Registration Error: ${e.code} - ${e.message}');
        throw Exception('Registration failed: ${e.message}');
      }
    } catch (error) {
      debugPrint('Registration Error: $error');
      rethrow;
    }
  }

  // Email/Password Login with error handling
  static Future<UserCredential?> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        debugPrint('Email/Password authentication is disabled');
        throw Exception('Email/Password login is currently disabled. Please use Google Sign-In.');
      } else if (e.code == 'user-not-found') {
        debugPrint('User not found');
        throw Exception('No account found with this email.');
      } else if (e.code == 'wrong-password') {
        debugPrint('Wrong password');
        throw Exception('Incorrect password. Please try again.');
      } else if (e.code == 'user-disabled') {
        debugPrint('User disabled');
        throw Exception('This account has been disabled.');
      } else if (e.code == 'invalid-email') {
        debugPrint('Invalid email');
        throw Exception('Please enter a valid email address.');
      } else if (e.code == 'too-many-requests') {
        debugPrint('Too many requests');
        throw Exception('Too many failed attempts. Please try again later.');
      } else {
        debugPrint('Login Error: ${e.code} - ${e.message}');
        throw Exception('Login failed: ${e.message}');
      }
    } catch (error) {
      debugPrint('Login Error: $error');
      rethrow;
    }
  }

  // Check if user is new (for Google Sign-In)
  static bool isNewUser(UserCredential userCredential) {
    return userCredential.additionalUserInfo?.isNewUser ?? false;
  }

  // Sign out
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Get current user
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // Get user display name
  static String? getUserName() {
    return FirebaseAuth.instance.currentUser?.displayName;
  }

  // Get user email
  static String? getUserEmail() {
    return FirebaseAuth.instance.currentUser?.email;
  }

  // Get user profile photo
  static String? getUserPhotoUrl() {
    return FirebaseAuth.instance.currentUser?.photoURL;
  }

  // Get user metadata
  static DateTime? getUserCreationTime() {
    return FirebaseAuth.instance.currentUser?.metadata.creationTime;
  }

  static DateTime? getUserLastSignInTime() {
    return FirebaseAuth.instance.currentUser?.metadata.lastSignInTime;
  }

  // Update user display name
  static Future<void> updateUserDisplayName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload();
    }
  }

  // Update user photo URL
  static Future<void> updateUserPhotoUrl(String photoUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updatePhotoURL(photoUrl);
      await user.reload();
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Please enter a valid email address.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Too many requests. Please try again later.');
      } else {
        throw Exception('Failed to send password reset email: ${e.message}');
      }
    } catch (error) {
      throw Exception('Failed to send password reset email: $error');
    }
  }

  // Delete user account
  static Future<void> deleteUserAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  // Reauthenticate user (for sensitive operations)
  static Future<void> reauthenticateUser(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } else {
      throw Exception('User not found or no email associated');
    }
  }
}