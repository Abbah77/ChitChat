import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chitchat/models/chat_models.dart';
import 'package:chitchat/services/api_service.dart';

class ChatCubit extends Cubit<ChatState> {
  final APIService _apiService = APIService();
  Timer? _typingTimer;
  final Map<String, bool> _typingStatus = {};

  ChatCubit() : super(ChatInitial()) {
    loadChats();
  }

  Future<void> loadChats() async {
    try {
      emit(ChatLoading());
      
      // Load chats from API
      final chats = await _apiService.fetchChats();
      
      // Connect to WebSocket for real-time updates
      await _apiService.connectWebSocket();
      
      // Listen to WebSocket messages
      _listenToWebSocket();
      
      emit(ChatLoaded(
        chats: chats,
        typingStatus: Map<String, bool>.from(_typingStatus),
        searchQuery: '',
      ));
    } catch (e, stackTrace) {
      debugPrint('Chat load error: $e\n$stackTrace');
      emit(ChatError('Failed to load chats: ${e.toString()}'));
    }
  }

  void _listenToWebSocket() {
    _apiService.messageStream.listen((message) {
      final currentState = state;
      if (currentState is ChatLoaded) {
        // Handle different message types
        final type = message['type'];
        
        if (type == 'typing') {
          final chatId = message['chat_id'];
          final isTyping = message['is_typing'] ?? false;
          _updateTypingStatus(chatId, isTyping);
        } else if (type == 'message') {
          // Handle new incoming message
          _handleNewMessage(message);
        }
      }
    });
  }

  void _updateTypingStatus(String chatId, bool isTyping) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      _typingStatus[chatId] = isTyping;
      emit(currentState.copyWith(typingStatus: Map.from(_typingStatus)));
      
      // Clear typing status after 3 seconds
      if (isTyping) {
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          _typingStatus.remove(chatId);
          if (state is ChatLoaded) {
            emit((state as ChatLoaded).copyWith(typingStatus: Map.from(_typingStatus)));
          }
        });
      }
    }
  }

  void _handleNewMessage(Map<String, dynamic> message) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final chatId = message['chat_id'];
      final chats = currentState.chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(
            lastMessage: message['content'] ?? '',
            time: DateTime.now(),
            unreadCount: chat.unreadCount + 1,
          );
        }
        return chat;
      }).toList();
      
      // Sort by pinned and time
      chats.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.time.compareTo(a.time);
      });
      
      emit(currentState.copyWith(chats: chats));
    }
  }

  void updateSearchQuery(String query) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void markAsRead(String chatId) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final chats = currentState.chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(unreadCount: 0);
        }
        return chat;
      }).toList();
      
      emit(currentState.copyWith(chats: chats));
    }
  }

  void togglePin(String chatId) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final chats = currentState.chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(isPinned: !chat.isPinned);
        }
        return chat;
      }).toList();
      
      // Sort by pinned status
      chats.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.time.compareTo(a.time);
      });
      
      emit(currentState.copyWith(chats: chats));
    }
  }

  void deleteChat(String chatId) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final chats = currentState.chats.where((chat) => chat.id != chatId).toList();
      emit(currentState.copyWith(chats: chats));
    }
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    _apiService.disconnectWebSocket();
    return super.close();
  }
}

abstract class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Chat> chats;
  final Map<String, bool> typingStatus;
  final String searchQuery;

  const ChatLoaded({
    required this.chats,
    required this.typingStatus,
    required this.searchQuery,
  });

  ChatLoaded copyWith({
    List<Chat>? chats,
    Map<String, bool>? typingStatus,
    String? searchQuery,
  }) {
    return ChatLoaded(
      chats: chats ?? this.chats,
      typingStatus: typingStatus ?? this.typingStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Chat> get filteredChats {
    if (searchQuery.isEmpty) return chats;
    return chats.where((chat) {
      return chat.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
             chat.lastMessage.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
}
