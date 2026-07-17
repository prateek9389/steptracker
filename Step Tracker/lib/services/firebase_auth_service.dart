import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

class FirebaseAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Ensures Firebase is initialized before performing any operation.
  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('FirebaseAuthService: Firebase not initialized, initializing now...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('FirebaseAuthService: Firebase initialized successfully.');
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    await _ensureFirebaseInitialized();
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password, {String? name}) async {
    await _ensureFirebaseInitialized();
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;

    if (user != null) {
      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
      }
      
      // Store user data in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    return userCredential;
  }


  Future<UserCredential?> signInWithGoogle() async {
    await _ensureFirebaseInitialized();
    try {
      // Force account picker to always show
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Save or merge user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    try { await _googleSignIn.signOut(); } catch (_) {}
    await _auth.signOut();
  }
}
