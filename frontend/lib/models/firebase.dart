class FirestoreTimestamp {
  final int seconds;
  final int nanoseconds;

  FirestoreTimestamp({
    required this.seconds,
    required this.nanoseconds,
  });

  factory FirestoreTimestamp.fromJson(Map<String, dynamic> json) {
    return FirestoreTimestamp(
      seconds: json['_seconds'],
      nanoseconds: json['_nanoseconds'],
    );
  }

  DateTime toDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
}