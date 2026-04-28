import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    User? createdUser;

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      createdUser = userCredential.user;
    } catch (e) {
      // Some firebase_auth versions may throw a cast error from Pigeon
      // even though the account was actually created.
      final currentUser = _auth.currentUser;
      if (currentUser != null &&
          (currentUser.email ?? '').toLowerCase() == email.toLowerCase()) {
        createdUser = currentUser;
      } else {
        rethrow;
      }
    }

    if (createdUser == null) {
      throw Exception('Failed to create user account');
    }

    final uid = createdUser.uid;

    // Step 2: Fire and forget - save to Firestore asynchronously without waiting
    // This prevents Pigeon serialization errors
    Future.delayed(const Duration(milliseconds: 500)).then((_) async {
      try {
        await _firestore.collection('users').doc(uid).set(
          {
            'username': username,
            'email': email,
            'createdAt': DateTime.now(),
          },
          SetOptions(merge: true),
        );
      } catch (_) {
        // Silent fail - user is already created in Auth.
      }
    });
  }

  // Login with email and password
  Future<void> login({
    required String emailOrUsername,
    required String password,
  }) async {
    String email = emailOrUsername;

    // If input is username, find the email
    if (!emailOrUsername.contains('@')) {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: emailOrUsername)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Username tidak ditemukan',
        );
      }

      final userData = querySnapshot.docs.first.data();
      email = userData['email'] ?? '';
      
      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Email tidak ditemukan',
        );
      }
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Some firebase_auth versions can throw cast errors from Pigeon
      // while auth state has actually changed successfully.
      final currentUser = _auth.currentUser;
      final isActuallyLoggedIn = currentUser != null &&
          (currentUser.email ?? '').toLowerCase() == email.toLowerCase();
      if (!isActuallyLoggedIn) {
        rethrow;
      }
    }

    print('✅ Login successful: $email');
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    
    final data = doc.data();
    return data;
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Check if user exists by username
  Future<bool> usernameExists(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }
}
