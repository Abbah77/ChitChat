import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

// Import your models
import 'screens/chat_page.dart';
import 'models/chat_models.dart';

class APIService {
  // ============ INSTANCE VARIABLES ============
  final String _baseUrl;
  final String _wsUrl;
  final FlutterSecureStorage _storage;
  final Logger _logger;
  
  // WebSocket variables
  WebSocket? _webSocket;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  
  // Stream controllers
  late final StreamController<Map<String, dynamic>> _messageStreamController;
  late final StreamController<Map<String, dynamic>> _chatUpdateStreamController;
  
  // ============ CONSTRUCTOR ============
  APIService({
    String? baseUrl,
    FlutterSecureStorage? storage,
    Logger? logger,
  }) : 
    _baseUrl = baseUrl ?? _getBaseUrl(),
    _wsUrl = _getWsUrl(baseUrl ?? _getBaseUrl()),
    _storage = storage ?? const FlutterSecureStorage(),
    _logger = logger ?? Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 3,
        lineLength: 80,
        colors: true,
        printEmojis: false,
        printTime: true,
      ),
    ) {
    _initializeStreams();
    _logger.i('APIService instance created');
  }
  
  // Helper methods to get URLs
  static String _getBaseUrl() {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    
    const devUrl = 'https://your-api-domain.com/api/v1';
    assert(devUrl != 'https://your-api-domain.com/api/v1', 
      '⚠️ API_BASE_URL not configured!');
    return devUrl;
  }
  
  static String _getWsUrl(String baseUrl) {
    return baseUrl
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://')
      .replaceFirst('/api/v1', '/ws');
  }
  
  void _initializeStreams() {
    _messageStreamController = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _logger.d('Message stream cancelled'),
    );
    _chatUpdateStreamController = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _logger.d('Chat update stream cancelled'),
    );
  }
  
  // Stream getters
  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get chatUpdateStream => _chatUpdateStreamController.stream;
  
  // ============ HTTP HEADERS ============
  
  Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'ChitChat/1.0.0 (${Platform.operatingSystem})',
      'X-App-Version': '1.0.0',
    };
    
    if (includeAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // ============ HTTP RESPONSE HANDLING ============
  
  Map<String, dynamic> _handleResponse(http.Response response) {
    // Check for empty response
    if (response.body.isEmpty) {
      return {'error': 'Empty response from server', 'statusCode': response.statusCode};
    }
    
    try {
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        return _handleErrorResponse(response.statusCode, responseBody);
      }
    } catch (e) {
      _logger.e('Failed to parse server response', error: e);
      return {
        'error': 'Invalid server response format',
        'statusCode': response.statusCode,
        'rawResponse': response.body.length > 100 
            ? '${response.body.substring(0, 100)}...' 
            : response.body,
      };
    }
  }
  
  Map<String, dynamic> _handleErrorResponse(int statusCode, Map<String, dynamic>? responseBody) {
    final errorMessage = responseBody?['message'] ?? responseBody?['error'];
    
    switch (statusCode) {
      case 400:
        return {
          'error': errorMessage ?? 'Bad request. Please check your input.',
          'statusCode': statusCode,
          'requiresRetry': false,
        };
      case 401:
        // Clear token on unauthorized
        _storage.delete(key: 'token');
        return {
          'error': errorMessage ?? 'Session expired. Please login again.',
          'statusCode': statusCode,
          'requiresLogin': true,
        };
      case 403:
        return {
          'error': errorMessage ?? 'Access forbidden.',
          'statusCode': statusCode,
          'requiresLogin': true,
        };
      case 404:
        return {
          'error': errorMessage ?? 'Resource not found.',
          'statusCode': statusCode,
          'requiresRetry': false,
        };
      case 422:
        return {
          'error': errorMessage ?? 'Validation failed.',
          'statusCode': statusCode,
          'validationErrors': responseBody?['errors'],
          'requiresRetry': false,
        };
      case 429:
        return {
          'error': errorMessage ?? 'Too many requests. Please wait.',
          'statusCode': statusCode,
          'requiresRetry': true,
        };
      case 500:
        return {
          'error': errorMessage ?? 'Internal server error. Please try again later.',
          'statusCode': statusCode,
          'requiresRetry': true,
        };
      case 503:
        return {
          'error': errorMessage ?? 'Service temporarily unavailable.',
          'statusCode': statusCode,
          'requiresRetry': true,
        };
      default:
        return {
          'error': errorMessage ?? 'An error occurred (Status: $statusCode)',
          'statusCode': statusCode,
          'requiresRetry': true,
        };
    }
  }
  
  // ============ HTTP REQUEST METHODS ============
  
  Future<Map<String, dynamic>> _postRequest(
    String endpoint, {
    Map<String, dynamic> body = const {},
    bool includeAuth = true,
  }) async {
    return _makeRequest(
      'POST',
      endpoint,
      includeAuth: includeAuth,
      body: body,
    );
  }
  
  Future<Map<String, dynamic>> _getRequest(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    return _makeRequest(
      'GET',
      endpoint,
      includeAuth: includeAuth,
    );
  }
  
  Future<Map<String, dynamic>> _putRequest(
    String endpoint, {
    Map<String, dynamic> body = const {},
    bool includeAuth = true,
  }) async {
    return _makeRequest(
      'PUT',
      endpoint,
      includeAuth: includeAuth,
      body: body,
    );
  }
  
  Future<Map<String, dynamic>> _deleteRequest(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    return _makeRequest(
      'DELETE',
      endpoint,
      includeAuth: includeAuth,
    );
  }
  
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    bool includeAuth = true,
    Map<String, dynamic> body = const {},
  }) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    final headers = await _buildHeaders(includeAuth: includeAuth);
    final startTime = DateTime.now();
    
    _logger.i('🌐 $method $endpoint');
    
    try {
      http.Response response;
      
      switch (method) {
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 15));
          break;
        case 'GET':
          response = await http.get(url, headers: headers)
            .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers)
            .timeout(const Duration(seconds: 15));
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      final duration = DateTime.now().difference(startTime);
      _logger.i('✅ $method $endpoint - ${response.statusCode} (${duration.inMilliseconds}ms)');
      
      final result = _handleResponse(response);
      
      // Auto-logout on 401
      if (result['requiresLogin'] == true) {
        await logoutUser();
      }
      
      return result;
      
    } on SocketException {
      _logger.w('🌐 $method $endpoint - No internet connection');
      return {
        'error': 'No internet connection. Please check your network.',
        'networkError': true,
      };
    } on TimeoutException {
      _logger.w('🌐 $method $endpoint - Request timed out');
      return {
        'error': 'Request timed out. Please try again.',
        'timeout': true,
      };
    } catch (e, stackTrace) {
      _logger.e('🌐 $method $endpoint - Request failed', error: e, stackTrace: stackTrace);
      return {
        'error': 'An unexpected error occurred: ${e.toString()}',
        'exception': e.toString(),
      };
    }
  }
  
  // ============ MISSING POST METHODS ============
  
  Future<Map<String, dynamic>> savePost(String postId) async {
    return await _postRequest('posts/$postId/save');
  }
  
  Future<Map<String, dynamic>> unsavePost(String postId) async {
    return await _postRequest('posts/$postId/unsave');
  }
  
  Future<Map<String, dynamic>> addComment(String postId, String content) async {
    return await _postRequest('posts/$postId/comments', body: {'content': content});
  }
  
  Future<Map<String, dynamic>> sharePost(String postId) async {
    return await _postRequest('posts/$postId/share');
  }
  
  // ============ MISSING STORY METHODS ============
  
  Future<Map<String, dynamic>> sendStoryReaction(String storyId, String reaction) async {
    return await _postRequest('stories/$storyId/reactions', body: {'reaction': reaction});
  }
  
  Future<Map<String, dynamic>> sendStoryReply(String storyId, String reply) async {
    return await _postRequest('stories/$storyId/replies', body: {'reply': reply});
  }
  
  // ============ MEDIA UPLOAD ============
  
  Future<Map<String, dynamic>> uploadMedia(File file, {bool isVideo = false}) async {
    try {
      final url = Uri.parse('$_baseUrl/upload');
      final token = await getToken();
      
      if (token == null) {
        return {'error': 'Not authenticated'};
      }
      
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: '${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}',
      );
      
      request.files.add(multipartFile);
      request.fields['type'] = isVideo ? 'video' : 'image';
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(responseBody);
        return {'url': jsonResponse['url'], 'success': true};
      } else {
        return {'error': 'Upload failed: ${response.statusCode}'};
      }
    } catch (e) {
      _logger.e('Media upload error', error: e);
      return {'error': 'Upload failed: $e'};
    }
  }
  
  // ============ AUTHENTICATION ============
  
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String username,
    required String email,
    required String date,
    required String gender,
    required String password,
  }) async {
    final response = await _postRequest('register', body: {
      'name': name,
      'username': username,
      'email': email,
      'date_of_birth': date,
      'gender': gender,
      'password': password,
    }, includeAuth: false);
    
    if (response['token'] != null) {
      await _saveAuthData(response['token'] as String);
    }
    
    return response;
  }
  
  Future<Map<String, dynamic>> loginUser(String credential, String password) async {
    final response = await _postRequest('login', body: {
      'credential': credential,
      'password': password,
    }, includeAuth: false);
    
    if (response['token'] != null) {
      await _saveAuthData(response['token'] as String);
      // Connect WebSocket after successful login
      await connectWebSocket();
    }
    
    return response;
  }
  
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _postRequest('forgot-password', body: {'email': email});
  }
  
  Future<void> logoutUser() async {
    _logger.i('👋 Logging out user');
    disconnectWebSocket();
    await _storage.deleteAll();
  }
  
  Future<void> _saveAuthData(String token) async {
    await Future.wait([
      _storage.write(key: 'token', value: token),
      _storage.write(key: 'isLoggedIn', value: 'true'),
    ]);
    _logger.i('🔐 Auth data saved');
  }
  
  // ============ USER PROFILE ============
  
  Future<Map<String, dynamic>> getUserProfile() async {
    return await _getRequest('user/profile');
  }
  
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String username,
    required String email,
    required String dateOfBirth,
    required String gender,
  }) async {
    return await _putRequest('user/profile', body: {
      'name': name,
      'username': username,
      'email': email,
      'date_of_birth': dateOfBirth,
      'gender': gender,
    });
  }
  
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _postRequest('user/change-password', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
  
  Future<String> _getCurrentUserId() async {
    try {
      final profile = await getUserProfile();
      return profile['id']?.toString() ?? '0';
    } catch (e) {
      _logger.w('Failed to get current user ID', error: e);
      return '0';
    }
  }
  
  // ============ CHAT SYSTEM ============
  
  Future<List<Chat>> fetchChats() async {
    final response = await _getRequest('chats');
    
    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }
    
    final List<dynamic> chatsData = response['chats'] ?? response['data'] ?? [];
    return chatsData.map((chatData) {
      return Chat(
        id: chatData['id'].toString(),
        name: chatData['name'] ?? chatData['username'] ?? 'Unknown User',
        lastMessage: chatData['last_message'] ?? '',
        profileImage: chatData['profile_image'] ?? chatData['avatar'] ?? '',
        time: DateTime.parse(chatData['last_message_time'] ?? 
            chatData['updated_at'] ?? DateTime.now().toString()),
        unreadCount: chatData['unread_count'] ?? 0,
        isOnline: chatData['is_online'] ?? false,
        isGroup: chatData['is_group'] ?? false,
        isAI: chatData['is_ai'] ?? false,
        isPinned: chatData['is_pinned'] ?? false,
        lastMessageType: _parseMessageType(chatData['last_message_type']),
      );
    }).toList();
  }
  
  Future<List<Map<String, dynamic>>> fetchChatMessages({
    required String chatId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _getRequest('chats/$chatId/messages?page=$page&limit=$limit');
    
    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }
    
    final List<dynamic> messagesData = response['messages'] ?? response['data'] ?? [];
    final currentUserId = await _getCurrentUserId();
    
    return messagesData.map((msg) {
      final isMe = msg['sender_id']?.toString() == currentUserId;
      return {
        'id': msg['id'].toString(),
        'text': msg['content'] ?? msg['text'] ?? '',
        'isMe': isMe,
        'time': DateTime.parse(msg['created_at'] ?? DateTime.now().toString()),
        'status': isMe ? _parseMessageStatus(msg['status']) : null,
        'senderName': msg['sender_name'] ?? (isMe ? 'You' : 'User'),
        'senderAvatar': msg['sender_avatar'] ?? '',
        'type': _parseMessageType(msg['type']),
        'mediaUrl': msg['media_url'],
      };
    }).toList();
  }
  
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    final body = {
      'content': content,
      'type': type.name,
      if (mediaUrl != null) 'media_url': mediaUrl,
    };
    
    final response = await _postRequest('chats/$chatId/messages', body: body);
    
    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }
    
    // Send via WebSocket for real-time delivery
    if (_webSocket?.readyState == WebSocket.open) {
      sendMessageViaWebSocket(
        chatId: chatId,
        content: content,
        messageId: response['message_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        mediaUrl: mediaUrl,
      );
    }
    
    return {
      'id': response['message_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'text': content,
      'isMe': true,
      'time': DateTime.now(),
      'status': MessageStatus.sent,
      'type': type,
      'mediaUrl': mediaUrl,
    };
  }
  
  Future<Map<String, dynamic>> createChat({
    required String recipientId,
    String? initialMessage,
  }) async {
    final body = {'recipient_id': recipientId};
    if (initialMessage != null && initialMessage.isNotEmpty) {
      body['initial_message'] = initialMessage;
    }
    
    final response = await _postRequest('chats', body: body);
    
    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }
    
    return {
      'chatId': response['chat_id'] ?? response['id'],
      'success': true,
    };
  }

  // ============ POSTS & FEED ============

  Future<Map<String, dynamic>> fetchPosts({int page = 1, int limit = 20}) async {
    final response = await _getRequest('posts?page=$page&limit=$limit');
    
    // Return in format dashboard expects
    return {
      'posts': response['posts'] ?? response['data'] ?? [],
      'hasMore': response['has_more'] ?? true,
      'currentPage': page,
    };
  }

  Future<Map<String, dynamic>> fetchFriends() async {
    return await _getRequest('friends');
  }

  Future<Map<String, dynamic>> fetchNotifications() async {
    final response = await _getRequest('notifications');
    
    return {
      'notifications': response['notifications'] ?? response['data'] ?? [],
    };
  }

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final response = await _getRequest('dashboard');
    
    // Return in format dashboard expects
    return {
      'stats': response['stats'] ?? {
        'posts_today': 0,
        'interactions': 0,
        'new_followers': 0,
        'story_views': 0,
      },
      'notifications': response['notifications'] ?? [],
    };
  }

  Future<Map<String, dynamic>> createPost({
    required String content,
    String? image,
    String? video,
  }) async {
    final body = {
      'content': content,
      if (image != null && image.isNotEmpty) 'image': image,
      if (video != null && video.isNotEmpty) 'video': video,
    };
    
    return await _postRequest('posts', body: body);
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    return await _postRequest('posts/$postId/like');
  }

  Future<Map<String, dynamic>> unlikePost(String postId) async {
    return await _postRequest('posts/$postId/unlike');
  }

  // ============ TYPING INDICATORS ============

  void sendTypingIndicator({
    required String chatId,
    required bool isTyping,
  }) {
    if (_webSocket?.readyState != WebSocket.open) {
      _logger.w('Cannot send typing indicator: WebSocket not connected');
      return;
    }
    
    try {
      final typingMessage = {
        'type': 'typing',
        'chat_id': chatId,
        'is_typing': isTyping,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      _webSocket!.add(jsonEncode(typingMessage));
      _logger.d('⌨️ Typing indicator sent: $isTyping for chat $chatId');
      
    } catch (e) {
      _logger.e('Failed to send typing indicator', error: e);
    }
  }

  // ============ STORIES ============

  Future<Map<String, dynamic>> fetchStories() async {
    final response = await _getRequest('stories');
    
    // Return in format dashboard expects
    return {
      'stories': response['stories'] ?? response['data'] ?? [],
    };
  }

  Future<Map<String, dynamic>> createStory({
    required String mediaUrl,
    String? caption,
    bool isVideo = false,
  }) async {
    final body = {
      'media_url': mediaUrl,
      'is_video': isVideo,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    };
    
    return await _postRequest('stories', body: body);
  }

  Future<Map<String, dynamic>> viewStory(String storyId) async {
    return await _postRequest('stories/$storyId/view');
  }

  // ============ WEB SOCKET (REAL-TIME) ============
  
  Future<void> connectWebSocket() async {
    if (_webSocket?.readyState == WebSocket.open) {
      _logger.d('WebSocket already connected');
      return;
    }
    
    if (_isConnecting) {
      _logger.d('WebSocket connection already in progress');
      return;
    }
    
    _isConnecting = true;
    _reconnectAttempts = 0;
    
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        _logger.w('No token available for WebSocket connection');
        _isConnecting = false;
        return;
      }
      
      _logger.i('🔌 Connecting to WebSocket...');
      
      final wsUrl = '$_wsUrl?token=$token';
      _webSocket = await WebSocket.connect(wsUrl);
      
      _webSocket!.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            final type = message['type'];
            
            switch (type) {
              case 'message':
                _messageStreamController.add(message);
                break;
              case 'chat_update':
                _chatUpdateStreamController.add(message);
                break;
              case 'typing':
                _messageStreamController.add(message);
                break;
              case 'message_status':
                _messageStreamController.add(message);
                break;
              default:
                _logger.d('Unknown WebSocket message type: $type');
            }
          } catch (e) {
            _logger.e('Failed to parse WebSocket message', error: e);
          }
        },
        onError: (error) {
          _logger.e('WebSocket error', error: error);
          _reconnectWebSocket();
        },
        onDone: () {
          _logger.i('WebSocket disconnected');
          _reconnectWebSocket();
        },
      );
      
      _logger.i('✅ WebSocket connected successfully');
      _isConnecting = false;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to connect WebSocket', error: e, stackTrace: stackTrace);
      _isConnecting = false;
      _reconnectWebSocket();
    }
  }
  
  void _reconnectWebSocket() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return;
    }
    
    _reconnectAttempts++;
    
    // Exponential backoff with max 30 seconds
    final delaySeconds = _reconnectAttempts.clamp(1, 6);
    final delay = Duration(seconds: delaySeconds * 2);
    
    _logger.i('🔄 Reconnecting WebSocket in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      if (await isLoggedIn()) {
        await connectWebSocket();
      }
    });
  }
  
  void disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    
    if (_webSocket != null) {
      _webSocket!.close();
      _webSocket = null;
      _logger.i('🔌 WebSocket disconnected');
    }
  }
  
  void sendMessageViaWebSocket({
    required String chatId,
    required String content,
    required String messageId,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) {
    if (_webSocket?.readyState != WebSocket.open) {
      _logger.w('Cannot send WebSocket message: connection not open');
      return;
    }
    
    try {
      // Limit content size
      final safeContent = content.length > 5000 
          ? content.substring(0, 5000)
          : content;
      
      final message = {
        'type': 'message',
        'chat_id': chatId,
        'content': safeContent,
        'message_id': messageId,
        'message_type': type.name,
        'media_url': mediaUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      _webSocket!.add(jsonEncode(message));
      _logger.d('📤 WebSocket message sent: $messageId');
      
    } catch (e) {
      _logger.e('Failed to send WebSocket message', error: e);
    }
  }
  
  // ============ HELPER METHODS ============
  
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
      default:
        return MessageType.text;
    }
  }
  
  MessageStatus _parseMessageStatus(String? statusString) {
    if (statusString == null) return MessageStatus.sent;
    
    switch (statusString.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }
  
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    final isLoggedIn = await _storage.read(key: 'isLoggedIn');
    return token != null && isLoggedIn == 'true';
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }
  
  Future<void> clearStorage() async {
    await _storage.deleteAll();
    _logger.i('🧹 Storage cleared');
  }
  
  // ============ CLEANUP ============
  
  void dispose() {
    disconnectWebSocket();
    _messageStreamController.close();
    _chatUpdateStreamController.close();
    _logger.i('APIService disposed');
  }
}

class SearchService {
  // Add your search methods here
  Future<List<dynamic>> searchUsers(String query) async {
    // Implement user search
    return [];
  }
  
  Future<List<dynamic>> searchPosts(String query) async {
    // Implement post search
    return [];
  }
  
  Future<List<dynamic>> searchTags(String query) async {
    // Implement hashtag search
    return [];
  }
}
