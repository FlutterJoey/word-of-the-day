import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/models.dart';
import 'package:wotd/src/services/auth.dart';
import 'package:wotd/src/services/firebase.dart';

class VoteService {
  VoteService({
    required this.date,
    required this.firestore,
    required this.auth,
  });

  final String date;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CollectionReference<WordSuggestion> get _collection =>
      firestore.collection('words/$date/suggestions').withConverter(
            toFirestore: (value, options) => value.toMap(),
            fromFirestore: (snapshot, options) =>
                WordSuggestion.fromFirebase(snapshot),
          );

  Stream<WordSuggestion?> getMySuggestion() {
    var userId = auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }
    return _collection.doc(userId).snapshots().map((event) => event.data());
  }

  Future<void> submitSuggestion(WordSuggestion value) async {
    var userId = auth.currentUser?.uid;
    if (userId == null) {
      return;
    }

    await _collection.doc(userId).set(value);
  }

  Future<void> deleteSuggestion() async {
    var userId = auth.currentUser?.uid;
    if (userId == null) {
      return;
    }

    await _collection.doc(userId).delete();
  }

  Stream<List<WordSuggestion>> getSuggestions() {
    return _collection.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Future<void> voteForSuggestion(WordSuggestion suggestion) async {
    var userId = auth.currentUser?.uid;
    if (userId == null) {
      return;
    }
    var docs = await _collection.where('votes', arrayContains: userId).get();
    for (var doc in docs.docs) {
      await _collection.doc(doc.id).update({
        'votes': FieldValue.arrayRemove([userId]),
      });
    }
    await _collection.doc(suggestion.owner).update({
      'votes': FieldValue.arrayUnion([userId]),
    });
  }
}

final votesServiceProvider = Provider.family<VoteService, String>((ref, date) {
  return VoteService(
    date: date,
    firestore: ref.read(firebaseFirestoreProvider),
    auth: ref.read(firebaseAuthProvider),
  );
});

final wordSuggestionsProvider =
    StreamProvider.family<List<WordSuggestion>, String>((ref, date) {
  ref.watch(currentUserIdProvider);
  var service = ref.read(votesServiceProvider(date));
  return service.getSuggestions();
});

final myVoteSubmissionProvider =
    StreamProvider.family<WordSuggestion?, String>((ref, date) {
  ref.watch(currentUserIdProvider);
  var service = ref.read(votesServiceProvider(date));

  return service.getMySuggestion();
});
