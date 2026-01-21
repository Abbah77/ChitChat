import 'user.dart';

enum StoryStatus { unviewed, viewed, yourStory }
enum StoryPlayState { playing, paused, ended }

class Story {
  final String id;
  final String imageUrl;
  final String videoUrl;
  final String userId;
  final String userName;
  final String userAvatar;
  final DateTime timestamp;
  final List<String> viewers;
  final bool hasReplies;
  StoryStatus status;

  const Story({
    required this.id,
    required this.imageUrl,
    required this.videoUrl,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.timestamp,
    required this.viewers,
    required this.hasReplies,
    this.status = StoryStatus.unviewed,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: _parseString(json['id'], ''),
      imageUrl: _parseString(
        json['image_url'] ?? json['imageUrl'] ?? json['media_url'],
        '',
      ),
      videoUrl: _parseString(
        json['video_url'] ?? json['videoUrl'] ?? json['media_url'],
        '',
      ),
      userId: _parseString(json['user_id'] ?? json['userId'], ''),
      userName: _parseString(
        json['user_name'] ?? json['userName'] ?? json['username'],
        'User',
      ),
      userAvatar: _parseString(
        json['user_avatar'] ?? json['userAvatar'] ?? json['profile_image'],
        '',
      ),
      timestamp: _parseDateTime(json['created_at'] ?? json['timestamp']),
      viewers: _parseStringList(json['viewers'] ?? json['viewer_ids']),
      hasReplies: _parseBool(json['has_replies'] ?? json['hasReplies'], false),
      status: _parseStoryStatus(
        json['status'] ?? json['is_viewed'] ?? json['viewed'],
      ),
    );
  }

  static String _parseString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
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

  static StoryStatus _parseStoryStatus(dynamic value) {
    if (value == null) return StoryStatus.unviewed;
    if (value is StoryStatus) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'viewed':
          return StoryStatus.viewed;
        case 'yourstory':
        case 'your_story':
          return StoryStatus.yourStory;
        default:
          return StoryStatus.unviewed;
      }
    }
    if (value is bool) {
      return value ? StoryStatus.viewed : StoryStatus.unviewed;
    }
    return StoryStatus.unviewed;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'created_at': timestamp.toIso8601String(),
      'viewers': viewers,
      'has_replies': hasReplies,
      'status': status.name,
    };
  }

  Story copyWith({
    String? id,
    String? imageUrl,
    String? videoUrl,
    String? userId,
    String? userName,
    String? userAvatar,
    DateTime? timestamp,
    List<String>? viewers,
    bool? hasReplies,
    StoryStatus? status,
  }) {
    return Story(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      timestamp: timestamp ?? this.timestamp,
      viewers: viewers ?? this.viewers,
      hasReplies: hasReplies ?? this.hasReplies,
      status: status ?? this.status,
    );
  }

  Story.empty()
      : id = '',
        imageUrl = '',
        videoUrl = '',
        userId = '',
        userName = '',
        userAvatar = '',
        timestamp = DateTime.now(),
        viewers = [],
        hasReplies = false,
        status = StoryStatus.unviewed;

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => !isEmpty;

  bool get hasMedia => imageUrl.isNotEmpty || videoUrl.isNotEmpty;
  bool get isVideo => videoUrl.isNotEmpty;
  bool get isImage => imageUrl.isNotEmpty && videoUrl.isEmpty;

  Duration get age => DateTime.now().difference(timestamp);

  @override
  String toString() {
    return 'Story(id: $id, user: $userName, hasMedia: $hasMedia, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Story && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}