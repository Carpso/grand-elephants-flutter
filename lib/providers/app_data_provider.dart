import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

class Address {
  final String id;
  final String title;
  final String details;
  final bool isDefault;

  const Address({
    required this.id,
    required this.title,
    required this.details,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        details: json['details'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String createdAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: '${json['id']}',
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class AppDataProvider extends ChangeNotifier {
  List<Address> _addresses = [];
  List<ChatMessage> _messages = [];
  final bool _loading = false;
  String? _error;

  List<Address> get addresses => _addresses;
  List<ChatMessage> get messages => _messages;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAddresses() async {
    try {
      final res = await ApiClient.instance.get('/api/addresses');
      _addresses = (res as List)
          .map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = '$e';
    }
  }

  Future<void> addAddress({required String title, required String details, bool isDefault = false}) async {
    try {
      await ApiClient.instance.post('/api/addresses',
          body: {'title': title, 'details': details, 'isDefault': isDefault});
      await loadAddresses();
    } catch (e) {
      debugPrint('Add address failed: $e');
      rethrow;
    }
  }

  Future<void> updateAddress(String id, {String? title, String? details, bool? isDefault}) async {
    try {
      await ApiClient.instance.put('/api/addresses/$id',
          body: {
            if (title != null) 'title': title,
            if (details != null) 'details': details,
            if (isDefault != null) 'isDefault': isDefault,
          });
      await loadAddresses();
    } catch (e) {
      debugPrint('Update address failed: $e');
      rethrow;
    }
  }

  Future<void> removeAddress(String id) async {
    try {
      await ApiClient.instance.delete('/api/addresses/$id');
      await loadAddresses();
    } catch (e) {
      debugPrint('Remove address failed: $e');
      rethrow;
    }
  }

  Future<void> loadChat() async {
    try {
      final res = await ApiClient.instance.get('/api/chat/messages');
      _messages = (res as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = '$e';
    }
  }

  Future<void> sendChatMessage(String text) async {
    try {
      await ApiClient.instance.post('/api/chat/messages', body: {'text': text});
      await loadChat();
    } catch (e) {
      debugPrint('Send message failed: $e');
      rethrow;
    }
  }
}