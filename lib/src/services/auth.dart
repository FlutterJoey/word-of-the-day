import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/services/firebase.dart';

class AuthService {
  AuthService({required this.auth});

  final FirebaseAuth auth;

  Future<void> login(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      throw LoginFailedException(
          message: switch (error.code) {
        'invalid-email' => 'You need to provide a email',
        'wrong-password' ||
        'user-not-found' ||
        'invalid-credential' =>
          'No account was found for those credentials',
        'user-disabled' => 'You need to disable a us',
        String value => 'Something went wrong whilst logging in: $value'
      });
    }
  }

  bool isSignedInAsAdmin() {
    return !(auth.currentUser?.isAnonymous ?? false);
  }

  Future<void> signOutAdmin() async {
    await auth.signOut();
    await auth.signInAnonymously();
  }

  String? getId() {
    return auth.currentUser?.uid;
  }
}

class LoginFailedException implements Exception {
  final String message;

  LoginFailedException({required this.message});
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(auth: ref.read(firebaseAuthProvider));
});

final currentUserIdProvider = StreamProvider<String?>((ref) {
  return ref
      .read(firebaseAuthProvider)
      .userChanges()
      .map((event) => event?.uid);
});
