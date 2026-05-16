// Autor: Allan Giovanni Matias Paes
// Classe que representa um timestamp do Firestore com segundos e nanosegundos.
class FirestoreTimestamp {
  final int seconds;
  final int nanoseconds;

  FirestoreTimestamp({
    required this.seconds,
    required this.nanoseconds,
  });

  // Método que converte um objeto JSON ou String para FirestoreTimestamp.
  // Se for String, realiza o parse para DateTime e calcula segundos/nanosegundos.
  factory FirestoreTimestamp.fromJson(dynamic json) {
    if (json is String) {
      final dateTime = DateTime.parse(json);
      // O cálculo divide os milissegundos por 1000 para segundos e o resto para nanosegundos.
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

  // Converte o timestamp para o formato DateTime do Dart.
  DateTime toDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
}