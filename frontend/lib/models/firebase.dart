class FirestoreTimestamp {
  final int seconds;
  final int nanoseconds;

  FirestoreTimestamp({
    required this.seconds,
    required this.nanoseconds,
  });

  factory FirestoreTimestamp.fromJson(dynamic json) {
    if (json is String) {
      final dateTime = DateTime.parse(json);
      return FirestoreTimestamp(
        seconds: dateTime.millisecondsSinceEpoch ~/ 1000,
        nanoseconds: (dateTime.millisecondsSinceEpoch % 1000) * 1000000,
      );
    }
    return FirestoreTimestamp(
      seconds: json['_seconds'] ?? 0,
      nanoseconds: json['_nanoseconds'] ?? 0,
    );
  }

  DateTime toDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
}