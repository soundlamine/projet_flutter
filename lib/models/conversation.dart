// lib/models/conversation.dart
import 'chat_message.dart';

class Conversation {
  final String id;
  final String userId;
  String? title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'messages': messages.map((msg) => msg.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      messages: List<ChatMessage>.from(
        (map['messages'] as List).map((msg) => ChatMessage.fromMap(msg)),
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Méthode de copie avec modifications optionnelles
  Conversation copyWith({
    String? id,
    String? userId,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }


  @override
  String toString() {
    return 'Conversation{id: $id, title: $title, messages: ${messages.length}, updatedAt: $updatedAt}';
  }
}