class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String profileImage;
  final String coverImage;
  final String bio;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isVerified;
  final bool isOnline;
  final DateTime lastSeen;
  
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.profileImage,
    required this.coverImage,
    required this.bio,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.isVerified,
    required this.isOnline,
    required this.lastSeen,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseString(json['id'], '0'),
      name: _parseString(json['name'], ''),
      email: _parseString(json['email'], ''),
      username: _parseString(json['username'], ''),
      profileImage: _parseString(
        json['profile_image'] ?? json['avatar'] ?? json['profileImage'],
        '',
      ),
      coverImage: _parseString(
        json['cover_image'] ?? json['coverImage'],
        '',
      ),
      bio: _parseString(json['bio'], ''),
      postsCount: _parseInt(json['posts_count'] ?? json['postsCount'], 0),
      followersCount: _parseInt(
        json['followers_count'] ?? json['followersCount'],
        0,
      ),
      followingCount: _parseInt(
        json['following_count'] ?? json['followingCount'],
        0,
      ),
      isVerified: _parseBool(json['is_verified'] ?? json['isVerified'], false),
      isOnline: _parseBool(json['is_online'] ?? json['isOnline'], false),
      lastSeen: _parseDateTime(json['last_seen'] ?? json['lastSeen']),
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
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'profile_image': profileImage,
      'cover_image': coverImage,
      'bio': bio,
      'posts_count': postsCount,
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_verified': isVerified,
      'is_online': isOnline,
      'last_seen': lastSeen.toIso8601String(),
    };
  }
  
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? profileImage,
    String? coverImage,
    String? bio,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      bio: bio ?? this.bio,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
  
  User.empty()
      : id = '0',
        name = '',
        email = '',
        username = '',
        profileImage = '',
        coverImage = '',
        bio = '',
        postsCount = 0,
        followersCount = 0,
        followingCount = 0,
        isVerified = false,
        isOnline = false,
        lastSeen = DateTime.now();
  
  bool get isEmpty => id == '0' || id.isEmpty;
  bool get isNotEmpty => !isEmpty;
  
  @override
  String toString() {
    return 'User(id: $id, name: $name, username: $username, email: $email)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}hfy
