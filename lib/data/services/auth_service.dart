import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        await _ensureDefaultGroup(credential.user!);
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        await _ensureDefaultGroup(credential.user!);
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Usar authenticate() em vez de signIn() para v7.2.0+
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // accessToken não é mais garantido no GoogleSignInAuthentication v7+ 
        // sem autorização explícita de escopos, mas o idToken basta para o Firebase.
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _ensureDefaultGroup(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> _ensureDefaultGroup(User user) async {
    final groupsRef = _firestore.collection('groups');
    final query = await groupsRef
        .where('ownerId', isEqualTo: user.uid)
        .where('name', isEqualTo: 'Pessoal')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      await groupsRef.add({
        'name': 'Pessoal',
        'ownerId': user.uid,
        'isDefault': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
