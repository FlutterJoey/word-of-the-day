import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/services/firebase.dart';

final initializationProvider = FutureProvider<void>((ref) async {
  var auth = ref.read(firebaseAuthProvider);
  var user = auth.currentUser;

  if (user == null) {
    await auth.signInAnonymously();
  }

  return;
});
