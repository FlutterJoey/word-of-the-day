import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wotd/src/extensions.dart';
import 'package:wotd/src/models.dart';
import 'package:wotd/src/services/auth.dart';
import 'package:wotd/src/services/firebase.dart';

class WordOfTheDayService {
  final FirebaseFirestore firestore;

  WordOfTheDayService({required this.firestore});

  CollectionReference<WordOfTheDay> get _collection =>
      firestore.collection('words').withConverter(
            toFirestore: (value, options) => value.toMap(),
            fromFirestore: (snapshot, options) =>
                WordOfTheDay.fromFirebase(snapshot),
          );

  Stream<WordOfTheDay> getWordOfToday() {
    var date = DateTime.now().toDateIsoString();
    var snapshots = _collection.doc(date).snapshots();

    return snapshots.map(
      (snapshot) => snapshot.data() ?? WordOfTheDay.empty(),
    );
  }

  Stream<List<WordOfTheDay>> getAllPreviousWordsAsStream() {
    var date = DateTime.now().toDateIsoString();

    var snapshots =
        _collection.where(FieldPath.documentId, isLessThan: date).snapshots();

    return snapshots.map((snapshot) {
      var docs = snapshot.docs;

      return docs
          .map((e) => e.data())
          .where((element) => element.isFinished)
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    });
  }

  Future<void> _ensureExists(
      DocumentReference<WordOfTheDay> doc, WordOfTheDay wordOfTheDay) async {
    var snapshot = await doc.get();

    if (!snapshot.exists) {
      doc.set(
        WordOfTheDay(
            dateTime: wordOfTheDay.dateTime,
            word: '',
            description: '',
            isVoteOpen: false,
            hasVoteConcluded: false),
      );
    }
  }

  Future<void> closeVote(WordOfTheDay wordOfTheDay) async {
    var doc = _collection.doc(wordOfTheDay.id);

    await _ensureExists(doc, wordOfTheDay);
    await doc.update({
      'hasVoteConcluded': true,
    });
  }

  Future<void> openVote(WordOfTheDay wordOfTheDay) async {
    var doc = _collection.doc(wordOfTheDay.id);
    await _ensureExists(doc, wordOfTheDay);
    doc.update({
      'isVoteOpen': true,
    });
  }

  Future<void> reopenVote(WordOfTheDay wordOfTheDay) async {
    var doc = _collection.doc(wordOfTheDay.id);
    await _ensureExists(doc, wordOfTheDay);
    await doc.update({
      'hasVoteConcluded': false,
    });
  }

  Future<void> pickSuggestion(WordSuggestion suggestion) async {
    var tomorrow = DateTime.now()
        .copyWith(
          hour: 12,
        )
        .add(const Duration(days: 1));

    var tomorrowId = tomorrow.toDateIsoString();

    await _collection.doc(tomorrowId).set(
          WordOfTheDay(
            dateTime: tomorrow,
            word: suggestion.word,
            description: suggestion.description,
            isVoteOpen: false,
            hasVoteConcluded: false,
          ),
        );
  }
}

final wotdServiceProvider = Provider<WordOfTheDayService>((ref) {
  return WordOfTheDayService(firestore: ref.read(firebaseFirestoreProvider));
});

final wordOfTodayProvider = StreamProvider<WordOfTheDay>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.read(wotdServiceProvider).getWordOfToday();
});

final wordsOfThePastProvider = StreamProvider<List<WordOfTheDay>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.read(wotdServiceProvider).getAllPreviousWordsAsStream();
});
