import 'dart:async';
import 'package:fasotransport_mobile/services/api_client.dart';
import 'package:fasotransport_mobile/services/session.dart';

class ChatMessage {
  final String id;
  final String message;
  final String userName;
  final String senderType; // 'PASSENGER' ou 'SUPPORT'
  final DateTime createdAt;
  final String? reply;

  ChatMessage({
    required this.id,
    required this.message,
    required this.userName,
    required this.senderType,
    required this.createdAt,
    this.reply,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      message: json['message'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      senderType: json['senderType'] ?? 'PASSENGER',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      reply: json['reply'] as String?,
    );
  }
}

class ChatService {
  final ApiClient _apiClient = ApiClient();
  final SessionStore _sessionStore = SessionStore();
  
  final StreamController<List<ChatMessage>> _messagesController = StreamController<List<ChatMessage>>.broadcast();
  Stream<List<ChatMessage>> get messages => _messagesController.stream;

  List<ChatMessage> _cachedMessages = [];

  List<ChatMessage> _sortMessages(List<ChatMessage> messages) {
    final sorted = List<ChatMessage>.from(messages);
    sorted.sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return sorted;
  }

  Future<void> loadConversation() async {
    try {
      final token = await _sessionStore.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token non disponible');
      }

      final messages = await _apiClient.getChatConversation(token: token);
      _cachedMessages = _sortMessages(messages
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList());
      
      _messagesController.add(_cachedMessages);
    } catch (e) {
      _messagesController.addError(e);
    }
  }

  Future<void> sendMessage(String message) async {
    try {
      final token = await _sessionStore.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token non disponible');
      }

      await _apiClient.sendChatMessage(
        token: token,
        message: message,
        category: 'GENERAL',
      );

      // Recharger la conversation complète pour récupérer aussi la réponse IA.
      await loadConversation();
    } catch (e) {
      _messagesController.addError(e);
      rethrow;
    }
  }

  void dispose() {
    _messagesController.close();
  }
}
