// Autor: Gemini CLI
import './firebase.dart';

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

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      startupId: json['startupId'] ?? '',
      delta: (json['delta'] ?? 0.0).toDouble(),
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      content: json['content'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: FirestoreTimestamp.fromJson(json['createdAt']).toDateTime(),
    );
  }
}

class EventPaginatedResponse {
  final List<Event> events;
  final String? lastEventId;

  EventPaginatedResponse({
    required this.events,
    this.lastEventId,
  });

  factory EventPaginatedResponse.fromJson(Map<String, dynamic> json) {
    return EventPaginatedResponse(
      events: (json['events'] as List? ?? [])
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastEventId: json['lastEventId'],
    );
  }
}
