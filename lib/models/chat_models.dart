// models/chat_models.dart

import 'package:equatable/equatable.dart'; // Importing the Equatable package for value comparison
import 'services/api_service.dart'; // Importing the API service for network operations

// ==================== ENUMS ====================
// Enum to represent the status of a message
enum MessageStatus { sending, sent, delivered, read }

// Enum to represent the type of a message
enum MessageType { text, photo, voice, sticker, video, file, location }

// ==================== CHAT MODEL ====================
// Chat model class that extends Equatable for value comparison
class Chat extends Equatable {
  final String id; // Unique identifier for the chat
  final String name; // Name of the chat or user
  final String lastMessage; // The last message sent in the chat
  final String profileImage; // URL of the profile image
  final DateTime time; // Timestamp of the last message
  final int unreadCount; // Count of unread messages
  final bool isOnline; // Indicates if the user is online
  final bool isGroup; // Indicates if the chat is a group chat
  final bool isAI; // Indicates if the chat is with an AI
  final bool isPinned; // Indicates if the chat is pinned
  final MessageType lastMessageType; // Type of the last message
  final String? lastMessageSender; // Sender of the last message
  final bool isMuted; // Indicates if the chat is muted
  final DateTime? lastSeen; // Timestamp of the last seen
  final List<String>? members; // List of members in the chat

  // Constructor for the Chat class
  const Chat({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.profileImage,
    required this.time,
    this.unreadCount = 0, // Default value for unreadCount
    this.isOnline = false, // Default value for isOnline
    this.isGroup = false, // Default value for isGroup
    this.isAI = false, // Default value for isAI
    this.isPinned = false, // Default value for isPinned
    this.lastMessageType = MessageType.text, // Default value for lastMessageType
    this.lastMessageSender,
    this.isMuted = false, // Default value for isMuted
    this.lastSeen,
    this.members,
  });

  // Factory method to create a Chat instance from JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id']?.toString() ?? '', // Convert id to string or default to empty
      name: json['name'] ?? json['username'] ?? 'Unknown User', // Fallback to 'Unknown User'
      lastMessage: json['last_message'] ?? '', // Default to empty if last_message is null
      profileImage: json['profile_image'] ?? json['avatar'] ?? '', // Fallback to avatar if profile_image is null
      time: _parseTime(json), // Parse the time from JSON
      unreadCount: json['unread_count'] ?? 0, // Default to 0 if unread_count is null
      isOnline: json['is_online'] ?? false, // Default to false if is_online is null
      isGroup: json['is_group'] ?? false, // Default to false if is_group is null
      isAI: json['is_ai'] ?? false, // Default to false if is_ai is null
      isPinned: json['is_pinned'] ?? false, // Default to false if is_pinned is null
      lastMessageType: _parseMessageType(json['last_message_type']), // Parse the last message type
      lastMessageSender: json['last_message_sender'], // Get the last message sender
      isMuted: json['is_muted'] ?? false, // Default to false if is_muted is null
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null, // Parse last seen date
      members: json['members'] != null ? List<String>.from(json['members']) : null, // Convert members to list
    );
  }

  // Private method to parse time from JSON
  static DateTime _parseTime(Map<String, dynamic> json) {
    return json['last_message_time'] != null
        ? DateTime.parse(json['last_message_time']) // Parse last message time
        : json['updated_at'] != null
            ? DateTime.parse(json['updated_at']) // Parse updated time if last message time is null
            : DateTime.now(); // Default to current time
  }

  // Method to convert Chat instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Chat ID
      'name': name, // Chat name
      'last_message': lastMessage, // Last message text
      'profile_image': profileImage, // Profile image URL
      'last_message_time': time.toIso8601String(), // Last message time in ISO format
      'unread_count': unreadCount, // Unread message count
      'is_online': isOnline, // Online status
      'is_group': isGroup, // Group chat status
      'is_ai': isAI, // AI chat status
      'is_pinned': isPinned, // Pinned status
      'last_message_type': lastMessageType.name, // Last message type as string
      'last_message_sender': lastMessageSender, // Last message sender
      'is_muted': isMuted, // Muted status
      'last_seen': lastSeen?.toIso8601String(), // Last seen time in ISO format
      'members': members, // List of members
    };
  }

  // Method to create a copy of the Chat instance with optional new values
  Chat copyWith({
    String? id,
    String? name,
    String? lastMessage,
    String? profileImage,
    DateTime? time,
    int? unreadCount,
    bool? isOnline,
    bool? isGroup,
    bool? isAI,
    bool? isPinned,
    MessageType? lastMessageType,
    String? lastMessageSender,
    bool? isMuted,
    DateTime? lastSeen,
    List<String>? members,
  }) {
    return Chat(
      id: id ?? this.id, // Use new id or current id
      name: name ?? this.name, // Use new name or current name
      lastMessage: lastMessage ?? this.lastMessage, // Use new last message or current last message
      profileImage: profileImage ?? this.profileImage, // Use new profile image or current profile image
      time: time ?? this.time, // Use new time or current time
      unreadCount: unreadCount ?? this.unreadCount, // Use new unread count or current unread count
      isOnline: isOnline ?? this.isOnline, // Use new online status or current online status
      isGroup: isGroup ?? this.isGroup, // Use new group status or current group status
      isAI: isAI ?? this.isAI, // Use new AI status or current AI status
      isPinned: isPinned ?? this.isPinned, // Use new pinned status or current pinned status
      lastMessageType: lastMessageType ?? this.lastMessageType, // Use new last message type or current last message type
      lastMessageSender: lastMessageSender ?? this.lastMessageSender, // Use new last message sender or current last message sender
      isMuted: isMuted ?? this.isMuted, // Use new muted status or current muted status
      lastSeen: lastSeen ?? this.lastSeen, // Use new last seen or current last seen
      members: members ?? this.members, // Use new members or current members
    );
  }

  // Overriding props for Equatable comparison
  @override
  List<Object?> get props => [
        id,
        name,
        lastMessage,
        profileImage,
        time,
        unreadCount,
        isOnline,
        isGroup,
        isAI,
        isPinned,
        lastMessageType,
        lastMessageSender,
        isMuted,
        lastSeen,
        members,
      ];

  // Private method to parse message type from string
  static MessageType _parseMessageType(String? typeString) {
    if (typeString == null) return MessageType.text; // Default to text if typeString is null
    switch (typeString.toLowerCase()) {
      case 'photo':
      case 'image':
        return MessageType.photo; // Return photo type
      case 'voice':
      case 'audio':
        return MessageType.voice; // Return voice type
      case 'sticker':
        return MessageType.sticker; // Return sticker type
      case 'video':
        return MessageType.video; // Return video type
      case 'file':
        return MessageType.file; // Return file type
      case 'location':
        return MessageType.location; // Return location type
      default:
        return MessageType.text; // Default to text type
    }
  }
}

// ==================== MESSAGE MODEL ====================
// Message model class that extends Equatable for value comparison
class Message extends Equatable {
  final String id; // Unique identifier for the message
  final String text; // Content of the message
  final bool isMe; // Indicates if the message is sent by the current user
  final DateTime time; // Timestamp of the message
  final MessageStatus? status; // Status of the message
  final String senderName; // Name of the sender
  final String senderAvatar; // Avatar of the sender
  final MessageType type; // Type of the message
  final String? mediaUrl; // URL of the media (if any)
  final String? thumbnailUrl; // URL of the thumbnail (if any)
  final double? mediaDuration; // Duration of the media (if any)
  final String? chatId; // ID of the chat the message belongs to
  final bool isDeleted; // Indicates if the message is deleted
  final List<String>? readBy; // List of users who have read the message
  final Map<String, dynamic>? metadata; // Additional metadata for the message

  // Constructor for the Message class
  const Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.status,
    required this.senderName,
    required this.senderAvatar,
    this.type = MessageType.text, // Default value for type
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaDuration,
    this.chatId,
    this.isDeleted = false, // Default value for isDeleted
    this.readBy,
    this.metadata,
  });

  // Factory method to create a Message instance from JSON
  factory Message.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
    final senderId = json['sender_id']?.toString(); // Get sender ID from JSON
    final isMe = senderId == currentUserId; // Check if the message is sent by the current user

    return Message(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(), // Generate ID if null
      text: json['content'] ?? json['text'] ?? '', // Fallback to empty if content is null
      isMe: isMe, // Set isMe based on sender ID
      time: _parseTime(json), // Parse the time from JSON
      status: isMe ? _parseMessageStatus(json['status']) : null, // Parse status if the message is sent by the current user
      senderName: json['sender_name'] ?? (isMe ? 'You' : 'User'), // Fallback to 'You' if the message is sent by the current user
      senderAvatar: json['sender_avatar'] ?? '', // Get sender avatar
      type: _parseMessageType(json['type']), // Parse message type
      mediaUrl: json['media_url'], // Get media URL
      thumbnailUrl: json['thumbnail_url'], // Get thumbnail URL
      mediaDuration: json['media_duration']?.toDouble(), // Convert media duration to double
      chatId: json['chat_id']?.toString(), // Get chat ID
      isDeleted: json['is_deleted'] ?? false, // Default to false if is_deleted is null
      readBy: json['read_by'] != null ? List<String>.from(json['read_by']) : null, // Convert readBy to list
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null, // Convert metadata to map
    );
  }

  // Private method to parse time from JSON
  static DateTime _parseTime(Map<String, dynamic> json) {
    return json['created_at'] != null
        ? DateTime.parse(json['created_at']) // Parse created_at time
        : DateTime.now(); // Default to current time
  }

  // Method to convert Message instance to JSON
  Map<String, dynamic> toJson({required String currentUserId}) {
    return {
      'id': id, // Message ID
      'content': text, // Message content
      'sender_id': isMe ? currentUserId : null, // Include sender ID if the message is sent by the current user
      'created_at': time.toIso8601String(), // Message time in ISO format
      'status': status?.name, // Message status as string
      'sender_name': senderName, // Sender name
      'sender_avatar': senderAvatar, // Sender avatar
      'type': type.name, // Message type as string
      'media_url': mediaUrl, // Media URL
      'thumbnail_url': thumbnailUrl, // Thumbnail URL
      'media_duration': mediaDuration, // Media duration
      'chat_id': chatId, // Chat ID
      'is_deleted': isDeleted, // Deleted status
      'read_by': readBy, // List of users who read the message
      'metadata': metadata, // Additional metadata
    };
  }

  // Method to create a copy of the Message instance with optional new values
  Message copyWith({
    String? id,
    String? text,
    bool? isMe,
    DateTime? time,
    MessageStatus? status,
    String? senderName,
    String? senderAvatar,
    MessageType? type,
    String? mediaUrl,
    String? thumbnailUrl,
    double? mediaDuration,
    String? chatId,
    bool? isDeleted,
    List<String>? readBy,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id, // Use new id or current id
      text: text ?? this.text, // Use new text or current text
      isMe: isMe ?? this.isMe, // Use new isMe or current isMe
      time: time ?? this.time, // Use new time or current time
      status: status ?? this.status, // Use new status or current status
      senderName: senderName ?? this.senderName, // Use new sender name or current sender name
      senderAvatar: senderAvatar ?? this.senderAvatar, // Use new sender avatar or current sender avatar
      type: type ?? this.type, // Use new type or current type
      mediaUrl: mediaUrl ?? this.mediaUrl, // Use new media URL or current media URL
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl, // Use new thumbnail URL or current thumbnail URL
      mediaDuration: mediaDuration ?? this.mediaDuration, // Use new media duration or current media duration
      chatId: chatId ?? this.chatId, // Use new chat ID or current chat ID
      isDeleted: isDeleted ?? this.isDeleted, // Use new deleted status or current deleted status
      readBy: readBy ?? this.readBy, // Use new readBy or current readBy
      metadata: metadata ?? this.metadata, // Use new metadata or current metadata
    );
  }

  // Overriding props for Equatable comparison
  @override
  List<Object?> get props => [
        id,
        text,
        isMe,
        time,
        status,
        senderName,
        senderAvatar,
        type,
        mediaUrl,
        thumbnailUrl,
        mediaDuration,
        chatId,
        isDeleted,
        readBy,
        metadata,
      ];

  // Private method to parse message status from string
  static MessageStatus _parseMessageStatus(String? statusString) {
    if (statusString == null) return MessageStatus.sent; // Default to sent if statusString is null
    switch (statusString.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending; // Return sending status
      case 'sent':
        return MessageStatus.sent; // Return sent status
      case 'delivered':
        return MessageStatus.delivered; // Return delivered status
      case 'read':
        return MessageStatus.read; // Return read status
      default:
        return MessageStatus.sent; // Default to sent status
    }
  }

  // Private method to parse message type from string
  static MessageType _parseMessageType(String? typeString) {
    if (typeString == null) return MessageType.text; // Default to text if typeString is null
    switch (typeString.toLowerCase()) {
      case 'photo':
      case 'image':
        return MessageType.photo; // Return photo type
      case 'voice':
      case 'audio':
        return MessageType.voice; // Return voice type
      case 'sticker':
        return MessageType.sticker; // Return sticker type
      case 'video':
        return MessageType.video; // Return video type
      case 'file':
        return MessageType.file; // Return file type
      case 'location':
        return MessageType.location; // Return location type
      default:
        return MessageType.text; // Default to text type
    }
  }
}

// ==================== USER MODEL ====================
// User model class that extends Equatable for value comparison
class User extends Equatable {
  final String id; // Unique identifier for the user
  final String name; // Name of the user
  final String username; // Username of the user
  final String email; // Email of the user
  final String profileImage; // URL of the user's profile image
  final bool isOnline; // Indicates if the user is online
  final DateTime? lastSeen; // Timestamp of the last seen
  final String? bio; // User's bio
  final String? phoneNumber; // User's phone number
  final DateTime? dateOfBirth; // User's date of birth
  final String? gender; // User's gender
  final bool isVerified; // Indicates if the user is verified
  final bool isBlocked; // Indicates if the user is blocked
  final bool isFriend; // Indicates if the user is a friend
  final DateTime? createdAt; // Timestamp of when the user was created

  // Constructor for the User class
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.profileImage = '', // Default value for profileImage
    this.isOnline = false, // Default value for isOnline
    this.lastSeen,
    this.bio,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.isVerified = false, // Default value for isVerified
    this.isBlocked = false, // Default value for isBlocked
    this.isFriend = false, // Default value for isFriend
    this.createdAt,
  });

  // Factory method to create a User instance from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '', // Convert id to string or default to empty
      name: json['name'] ?? 'Unknown User', // Fallback to 'Unknown User'
      username: json['username'] ?? '', // Get username
      email: json['email'] ?? '', // Get email
      profileImage: json['profile_image'] ?? json['avatar'] ?? '', // Fallback to avatar if profile_image is null
      isOnline: json['is_online'] ?? false, // Default to false if is_online is null
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null, // Parse last seen date
      bio: json['bio'], // Get bio
      phoneNumber: json['phone_number'], // Get phone number
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null, // Parse date of birth
      gender: json['gender'], // Get gender
      isVerified: json['is_verified'] ?? false, // Default to false if is_verified is null
      isBlocked: json['is_blocked'] ?? false, // Default to false if is_blocked is null
      isFriend: json['is_friend'] ?? false, // Default to false if is_friend is null
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null, // Parse created_at date
    );
  }

  // Method to convert User instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id, // User ID
      'name': name, // User name
      'username': username, // User username
      'email': email, // User email
      'profile_image': profileImage, // User profile image URL
      'is_online': isOnline, // Online status
      'last_seen': lastSeen?.toIso8601String(), // Last seen time in ISO format
      'bio': bio, // User bio
      'phone_number': phoneNumber, // User phone number
      'date_of_birth': dateOfBirth?.toIso8601String(), // Date of birth in ISO format
      'gender': gender, // User gender
      'is_verified': isVerified, // Verified status
      'is_blocked': isBlocked, // Blocked status
      'is_friend': isFriend, // Friend status
      'created_at': createdAt?.toIso8601String(), // Created at time in ISO format
    };
  }

  // Method to create a copy of the User instance with optional new values
  User copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? profileImage,
    bool? isOnline,
    DateTime? lastSeen,
    String? bio,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    bool? isVerified,
    bool? isBlocked,
    bool? isFriend,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id, // Use new id or current id
      name: name ?? this.name, // Use new name or current name
      username: username ?? this.username, // Use new username or current username
      email: email ?? this.email, // Use new email or current email
      profileImage: profileImage ?? this.profileImage, // Use new profile image or current profile image
      isOnline: isOnline ?? this.isOnline, // Use new online status or current online status
      lastSeen: lastSeen ?? this.lastSeen, // Use new last seen or current last seen
      bio: bio ?? this.bio, // Use new bio or current bio
      phoneNumber: phoneNumber ?? this.phoneNumber, // Use new phone number or current phone number
      dateOfBirth: dateOfBirth ?? this.dateOfBirth, // Use new date of birth or current date of birth
      gender: gender ?? this.gender, // Use new gender or current gender
      isVerified: isVerified ?? this.isVerified, // Use new verified status or current verified status
      isBlocked: isBlocked ?? this.isBlocked, // Use new blocked status or current blocked status
      isFriend: isFriend ?? this.isFriend, // Use new friend status or current friend status
      createdAt: createdAt ?? this.createdAt, // Use new created at or current created at
    );
  }

  // Overriding props for Equatable comparison
  @override
  List<Object?> get props => [
        id,
        name,
        username,
        email,
        profileImage,
        isOnline,
        lastSeen,
        bio,
        phoneNumber,
        dateOfBirth,
        gender,
        isVerified,
        isBlocked,
        isFriend,
        createdAt,
      ];
}

// ==================== API RESPONSE MODELS ====================
// Generic API response model
class ApiResponse<T> {
  final bool success; // Indicates if the API call was successful
  final String? message; // Message returned from the API
  final T? data; // Data returned from the API
  final Map<String, dynamic>? errors; // Errors returned from the API
  final int? statusCode; // HTTP status code

  // Constructor for the ApiResponse class
  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  // Factory method to create an ApiResponse instance from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    return ApiResponse(
      success: json['success'] ?? false, // Default to false if success is null
      message: json['message'], // Get message
      data: fromJson != null && json['data'] != null ? fromJson(json['data']) : null, // Parse data if available
      errors: json['errors'] != null ? Map<String, dynamic>.from(json['errors']) : null, // Convert errors to map
      statusCode: json['status_code'], // Get status code
    );
  }
}

// ==================== PAGINATION MODEL ====================
// Generic pagination response model
class PaginatedResponse<T> {
  final List<T> items; // List of items in the current page
  final int currentPage; // Current page number
  final int totalPages; // Total number of pages
  final int totalItems; // Total number of items
  final bool hasNextPage; // Indicates if there is a next page

  // Constructor for the PaginatedResponse class
  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
  });

  // Factory method to create a PaginatedResponse instance from JSON
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = (json['items'] ?? json['data'] ?? []) // Get items from JSON
        .map<T>((item) => fromJson(item)) // Map each item to the generic type
        .toList();

    return PaginatedResponse(
      items: items, // Set items
      currentPage: json['current_page'] ?? 1, // Default to 1 if current_page is null
      totalPages: json['total_pages'] ?? 1, // Default to 1 if total_pages is null
      totalItems: json['total_items'] ?? items.length, // Default to length of items if total_items is null
      hasNextPage: json['has_next_page'] ?? (json['current_page'] ?? 1) < (json['total_pages'] ?? 1), // Determine if there is a next page
    );
  }
}