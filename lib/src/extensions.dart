extension Date on DateTime {
  DateTime getDate() {
    return DateTime(year, month, day);
  }

  String toDateIsoString() {
    return toIso8601String().substring(0, 10);
  }
}
