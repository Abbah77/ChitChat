import 'user.dart';

enum PostPrivacy { public, friends, private }

class Post {
  final String id;
  final String content;
  final User author;
  final DateTime timestamp;
  final List<String> mediaUrls;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final List<User> likes;
  final bool isLiked;
  final bool isSaved;
  final PostPrivacy privacy;

  const Post({
    required this.id,
    required this.content,
    required this.author,
    required this.timestamp,
    this.mediaUrls = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.likes = const [],
    this.isLiked = false,
    this.isSaved = false,
    this.privacy = PostPrivacy.public,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: _parseString(json['id'], ''),
      content: _parseString(json['content'] ?? json['text'] ?? json['body'], ''),
      author: User.fromJson(json['author'] ?? {}),
      timestamp: _parseDateTime(json['created_at'] ?? json['timestamp']),
      mediaUrls: _parseStringList(json['media_urls'] ?? json['media']),
      likeCount: _parseInt(json['like_count'] ?? json['likesCount'], 0),
      commentCount: _parseInt(json['comment_count'] ?? json['commentsCount'], 0),
      shareCount: _parseInt(json['share_count'] ?? json['sharesCount'], 0),
      likes: _parseUsersList(json['likes'] ?? json['liked_by']),
      isLiked: _parseBool(json['is_liked'] ?? json['isLiked'], false),
      isSaved: _parseBool(json['is_saved'] ?? json['isSaved'], false),
      privacy: _parsePostPrivacy(json['privacy']),
    );
  }

  static String _parseString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return defaultValue;
  }

  static DateTime _parseDateTime(dynamic value) {
    try {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  static List<User> _parseUsersList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((userJson) => User.fromJson(userJson))
          .toList();
    }
    return [];
  }

  static PostPrivacy _parsePostPrivacy(dynamic value) {
    if (value == null) return PostPrivacy.public;
    if (value is PostPrivacy) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'friends':
          return PostPrivacy.friends;
        case 'private':
          return PostPrivacy.private;
        default:
          return PostPrivacy.public;
      }
    }
    return PostPrivacy.public;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': author.toJson(),
      'created_at': timestamp.toIso8601String(),
      'media_urls': mediaUrls,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'likes': likes.map((user) => user.toJson()).toList(),
      'is_liked': isLiked,
      'is_saved': isSaved,
      'privacy': privacy.name,
    };
  }

  Post copyWith({
    String? id,
    String? content,
    User? author,
    DateTime? timestamp,
    List<String>? mediaUrls,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    List<User>? likes,
    bool? isLiked,
    bool? isSaved,
    PostPrivacy? privacy,
  }) {
    return Post(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      timestamp: timestamp ?? this.timestamp,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      privacy: privacy ?? this.privacy,
    );
  }

  Post.empty()
      : id = '',
        content = '',
        author = User.empty(),
        timestamp = DateTime.now(),
        mediaUrls = const [],
        likeCount = 0,
        commentCount = 0,
        shareCount = 0,
        likes = const [],
        isLiked = false,
        isSaved = false,
        privacy = PostPrivacy.public;

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => !isEmpty;

  bool get hasMedia => mediaUrls.isNotEmpty;
  bool get hasMultipleMedia => mediaUrls.length > 1;
  bool get hasVideo => mediaUrls.any((url) => url.contains('.mp4') || url.contains('.mov'));
  bool get hasImages => mediaUrls.any((url) => 
      url.contains('.jpg') || url.contains('.jpeg') || 
      url.contains('.png') || url.contains('.gif'));

  Duration get age => DateTime.now().difference(timestamp);
  bool get isRecent => age.inHours < 24;

  @override
  String toString() {
    return 'Post(id: $id, author: ${author.name}, likes: $likeCount, hasMedia: $hasMedia)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Comment {
  final String id;
  final String postId;
  final User author;
  final String content;
  final DateTime timestamp;
  final int likeCount;
  final bool isLiked;
  final List<Comment> replies;
  final String? parentCommentId;
  
  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.timestamp,
    this.likeCount = 0,
    this.isLiked = false,
    this.replies = const [],
    this.parentCommentId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: _parseString(json['id'], ''),
      postId: _parseString(json['post_id'] ?? json['postId'], ''),
      author: User.fromJson(json['author'] ?? {}),
      content: _parseString(json['content'] ?? json['text'] ?? json['body'], ''),
      timestamp: _parseDateTime(json['created_at'] ?? json['timestamp']),
      likeCount: _parseInt(json['like_count'] ?? json['likesCount'], 0),
      isLiked: _parseBool(json['is_liked'] ?? json['isLiked'], false),
      replies: _parseCommentsList(json['replies']),
      parentCommentId: json['parent_comment_id'] ?? json['parentCommentId'],
    );
  }

  static List<Comment> _parseCommentsList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((commentJson) => Comment.fromJson(commentJson))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author': author.toJson(),
      'content': content,
      'created_at': timestamp.toIso8601String(),
      'like_count': likeCount,
      'is_liked': isLiked,
      'replies': replies.map((comment) => comment.toJson()).toList(),
      'parent_comment_id': parentCommentId,
    };
  }
  
  Comment copyWith({
    String? id,
    String? postId,
    User? author,
    String? content,
    DateTime? timestamp,
    int? likeCount,
    bool? isLiked,
    List<Comment>? replies,
    String? parentCommentId,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      author: author ?? this.author,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }

  Comment.empty()
      : id = '',
        postId = '',
        author = User.empty(),
        content = '',
        timestamp = DateTime.now(),
        likeCount = 0,
        isLiked = false,
        replies = const [],
        parentCommentId = null;

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => !isEmpty;
  bool get isReply => parentCommentId != null;
  bool get hasReplies => replies.isNotEmpty;

  Duration get age => DateTime.now().difference(timestamp);
  bool get isRecent => age.inHours < 24;

  @override
  String toString() {
    return 'Comment(id: $id, author: ${author.name}, postId: $postId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Reuse the same parsing helper methods from Post class
String _parseString(dynamic value, String defaultValue) {
  if (value == null) return defaultValue;
  return value.toString();
}

int _parseInt(dynamic value, int defaultValue) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  if (value is double) return value.toInt();
  return defaultValue;
}

bool _parseBool(dynamic value, bool defaultValue) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  if (value is int) return value == 1;
  return defaultValue;
}

DateTime _parseDateTime(dynamic value) {
  try {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  } catch (e) {
    return DateTime.now();
  }
}