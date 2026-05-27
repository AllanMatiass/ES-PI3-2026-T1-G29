// Autor: Allan Giovanni Matias Paes - 25008211
import './firebase.dart';

enum NewsSentiment {
  excellent,
  good,
  neutral,
  bad,
  disaster;

  static NewsSentiment fromDelta(double delta) {
    if (delta > 0.6) return NewsSentiment.excellent;
    if (delta > 0.1) return NewsSentiment.good;
    if (delta >= -0.1) return NewsSentiment.neutral;
    if (delta > -0.6) return NewsSentiment.bad;
    return NewsSentiment.disaster;
  }

  String get label {
    return switch (this) {
      NewsSentiment.excellent => 'Excelente',
      NewsSentiment.good => 'Boa',
      NewsSentiment.neutral => 'Neutra',
      NewsSentiment.bad => 'Ruim',
      NewsSentiment.disaster => 'Desastre',
    };
  }
}

class Event {
  final String id;
  final String startupId;
  final double delta;
  final String title;
  final String summary;
  final String content;
  final List<String> tags;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.startupId,
    required this.delta,
    required this.title,
    required this.summary,
    required this.content,
    required this.tags,
    required this.createdAt,
  });

  NewsSentiment get sentiment => NewsSentiment.fromDelta(delta);

  factory Event.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return Event(
      id: data['id'] ?? '',
      startupId: data['startupId'] ?? '',
      delta: (data['delta'] ?? 0.0).toDouble(),
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      content: data['content'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: FirestoreTimestamp.fromJson(data['createdAt']).toDateTime(),
    );
  }
}

class EventPaginatedResponse {
  final List<Event> events;
  final String? lastEventId;

  EventPaginatedResponse({required this.events, this.lastEventId});

  factory EventPaginatedResponse.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return EventPaginatedResponse(
      events: (data['events'] as List? ?? [])
          .map((e) => Event.fromJson(e))
          .toList(),
      lastEventId: data['lastEventId'],
    );
  }
}
