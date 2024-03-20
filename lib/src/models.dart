import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:wotd/src/extensions.dart';

class WordOfTheDay {
  final DateTime dateTime;
  final String? word;
  final String? description;
  final bool isVoteOpen;
  final bool hasVoteConcluded;

  String get id => dateTime.toDateIsoString();

  WordOfTheDay({
    required this.dateTime,
    required this.word,
    required this.description,
    required this.isVoteOpen,
    required this.hasVoteConcluded,
  });

  factory WordOfTheDay.empty() => WordOfTheDay(
        dateTime: DateTime.now().getDate(),
        word: null,
        description: null,
        isVoteOpen: false,
        hasVoteConcluded: false,
      );

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'description': description,
      'isVoteOpen': isVoteOpen,
      'hasVoteConcluded': hasVoteConcluded,
    };
  }

  bool get isFinished => word != null && description != null;

  factory WordOfTheDay.fromFirebase(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    var map = snapshot.data();

    var date = DateTime.tryParse(snapshot.id);

    if (date == null || map == null) {
      throw WordFormatInvalidException();
    }

    return WordOfTheDay(
      dateTime: DateTime.parse(snapshot.id),
      word: map['word'],
      description: map['description'],
      isVoteOpen: map['isVoteOpen'] ?? false,
      hasVoteConcluded: map['hasVoteConcluded'] ?? false,
    );
  }
}

class WordSuggestion {
  WordSuggestion({
    required this.owner,
    required this.word,
    required this.description,
    required this.reason,
    required this.votes,
  });

  factory WordSuggestion.empty() {
    return WordSuggestion(
      owner: '',
      word: '',
      description: '',
      reason: '',
      votes: [],
    );
  }

  factory WordSuggestion.fromFirebase(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    var map = snapshot.data();

    if (map == null) {
      throw WordFormatInvalidException();
    }

    var votes = map['votes'];
    var voteList = <String>[];
    if (votes is List) {
      voteList = votes.whereType<String>().toList();
    }

    return WordSuggestion(
      owner: snapshot.id,
      word: map['word'],
      description: map['description'],
      reason: map['reason'],
      votes: voteList,
    );
  }

  final String owner;
  final String word;
  final String description;
  final String reason;
  final List<String> votes;

  Map<String, dynamic> toMap() => {
        'word': word,
        'description': description,
        'reason': reason,
        'votes': votes,
      };

  bool hasVoted(String userId) {
    return votes.contains(userId);
  }

  WordSuggestion copyWith({
    String? owner,
    String? word,
    String? description,
    String? reason,
    List<String>? votes,
  }) {
    return WordSuggestion(
      owner: owner ?? this.owner,
      word: word ?? this.word,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      votes: votes ?? this.votes,
    );
  }
}

class WordFormatInvalidException implements Exception {}
