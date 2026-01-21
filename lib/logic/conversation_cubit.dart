import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chitchat/models/chat_models.dart';
import 'package:chitchat/services/api_service.dart';

class ConversationCubit extends Cubit<ConversationState> {
  final APIService _apiService = APIService();
  final String chatId;
  Timer? _typingTimer;
  bool _isTyping = false;
  List<Message> _messages = [];

  ConversationCubit({required this.chatId}) : super(ConversationInitial()) {
    _loadMessages();
    _initializeWebSocket();
  }

  Future<void> _loadMessages() async {
    try {
      emit(ConversationLoading());
      
      // Load messages from API
      final messages = await _apiService.fetchMessages(chatId: chatId);
      
      _messages = messages;
      emit(ConversationLoaded(messages: _messages));
      
    } catch (e, stackTrace) {
      debugPrint('Load messages error: $e\n$stackTrace');
      emit(ConversationError('Failed to load messages: ${e.toString()}'));
    }
  }

  void _initializeWebSocket() async {
    if (!APIService.isLoggedIn()) {
      debugPrint('User not logged in, skipping WebSocket');
      return;
    }
    
    await APIService.connectWebSocket();
    
    APIService.messageStream.listen((message) {
      if (message['type'] == 'message' && message['chat_id'] == chatId) {
        _handleIncomingMessage(message);
      } else if (message['type'] == 'typing' && message['chat_id'] == chatId) {
        _handleTypingIndicator(message);
      }
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> messageData) {
    final newMessage = Message(
      id: messageData['message_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageData['content'] ?? '',
      isMe: false,
      time: DateTime.now(),
      senderName: messageData['sender_name'] ?? 'User',
      senderAvatar: messageData['sender_avatar'] ?? '',
      type: _parseMessageType(messageData['message_type']),
      mediaUrl: messageData['media_url'],
      thumbnailUrl: messageData['thumbnail_url'],
      mediaDuration: messageData['media_duration']?.toDouble(),
      chatId: chatId,
    );
    
    _messages = [newMessage, ..._messages];
    
    final currentState = state;
    if (currentState is ConversationLoaded) {
      emit(currentState.copyWith(messages: _messages));
    }
  }

  void _handleTypingIndicator(Map<String, dynamic> message) {
    final isTyping = message['is_typing'] ?? false;
    final currentState = state;
    
    if (currentState is ConversationLoaded) {
      emit(currentState.copyWith(isOtherTyping: isTyping));
    }
  }

  MessageType _parseMessageType(String? typeString) {
    if (typeString == null) return MessageType.text;
    
    switch (typeString.toLowerCase()) {
      case 'photo':
      case 'image':
        return MessageType.photo;
      case 'voice':
      case 'audio':
        return MessageType.voice;
      case 'sticker':
        return MessageType.sticker;
      case 'video':
        return MessageType.video;
      case 'file':
        return MessageType.file;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }

  Future<void> sendMessage({
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    double? mediaDuration,
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Optimistic update
    final newMessage = Message(
      id: messageId,
      text: text,
      isMe: true,
      time: DateTime.now(),
      status: MessageStatus.sending,
      senderName: 'You',
      senderAvatar: '',
      type: type,
      mediaUrl: mediaUrl,
      mediaDuration: mediaDuration,
      chatId: chatId,
    );
    
    _messages = [newMessage, ..._messages];
    
    final currentState = state;
    if (currentState is ConversationLoaded) {
      emit(currentState.copyWith(messages: _messages));
    }
    
    try {
      final response = await _apiService.sendMessage(
        chatId: chatId,
        content: text,
        type: type,
        mediaUrl: mediaUrl,
        mediaDuration: mediaDuration,
      );
      
      // Update status to sent
      _updateMessageStatus(messageId, MessageStatus.sent);
      
      if (response != null && response['id'] != null) {
        // Simulate delivered and read status (in real app, these come from server)
        Future.delayed(const Duration(seconds: 1), () {
          _updateMessageStatus(messageId, MessageStatus.delivered);
        });
        
        Future.delayed(const Duration(seconds: 2), () {
          _updateMessageStatus(messageId, MessageStatus.read);
        });
      }
    } catch (e) {
      debugPrint('Send message error: $e');
      _updateMessageStatus(messageId, null); // Remove status to show error
    }
  }

  void _updateMessageStatus(String messageId, MessageStatus? status) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
      
      final currentState = state;
      if (currentState is ConversationLoaded) {
        emit(currentState.copyWith(messages: List.from(_messages)));
      }
    }
  }

  void sendTypingIndicator(bool isTyping) {
    if (isTyping == _isTyping) return;
    
    _isTyping = isTyping;
    _typingTimer?.cancel();
    
    if (isTyping) {
      try {
        APIService.sendTypingIndicator(
          chatId: chatId,
          isTyping: true,
        );
      } catch (e) {
        debugPrint('Error sending typing indicator: $e');
      }
      
      // Auto-stop typing after 3 seconds
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _isTyping = false;
        try {
          APIService.sendTypingIndicator(
            chatId: chatId,
            isTyping: false,
          );
        } catch (e) {
          debugPrint('Error stopping typing indicator: $e');
        }
      });
    } else {
      try {
        APIService.sendTypingIndicator(
          chatId: chatId,
          isTyping: false,
        );
      } catch (e) {
        debugPrint('Error stopping typing indicator: $e');
      }
    }
  }

  void clearChat() {
    _messages.clear();
    final currentState = state;
    if (currentState is ConversationLoaded) {
      emit(currentState.copyWith(messages: _messages));
    }
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    sendTypingIndicator(false);
    return super.close();
  }
}

// ==================== CONVERSATION STATES ====================
abstract class ConversationState {
  const ConversationState();
}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationLoaded extends ConversationState {
  final List<Message> messages;
  final bool isOtherTyping;
  
  const ConversationLoaded({
    required this.messages,
    this.isOtherTyping = false,
  });

  ConversationLoaded copyWith({
    List<Message>? messages,
    bool? isOtherTyping,
  }) {
    return ConversationLoaded(
      messages: messages ?? this.messages,
      isOtherTyping: isOtherTyping ?? this.isOtherTyping,
    );
  }
}

class ConversationError extends ConversationState {
  final String message;
  const ConversationError(this.message);
}