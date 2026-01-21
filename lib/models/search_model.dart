// models/search_model.dart
enum SearchResultType {
  user,
  hashtag,
  post,
}

class SearchResult {
  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final int? count;
  final bool? isFollowing;
  final dynamic data;
  
  SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.count,
    this.isFollowing,
    required this.data,
  });
  
  factory SearchResult.fromUser(Map<String, dynamic> json) {
    return SearchResult(
      type: SearchResultType.user,
      id: json['id'].toString(),
      title: json['name'] ?? '',
      subtitle: '@${json['username'] ?? ''}',
      imageUrl: json['profile_image'] ?? json['avatar'] ?? '',
      count: json['followers_count'] ?? 0,
      isFollowing: json['is_following'] ?? false,
      data: json,
    );
  }
  
  factory SearchResult.fromHashtag(Map<String, dynamic> json) {
    return SearchResult(
      type: SearchResultType.hashtag,
      id: json['name'],
      title: '#${json['name']}',
      subtitle: '${json['post_count'] ?? 0} posts',
      imageUrl: '',
      count: json['post_count'] ?? 0,
      data: json,
    );
  }
  
  factory SearchResult.fromPost(Map<String, dynamic> json) {
    return SearchResult(
      type: SearchResultType.post,
      id: json['id'].toString(),
      title: json['content']?.toString().split('\n').first ?? '',
      subtitle: json['author_name'] ?? '',
      imageUrl: json['image_url'] ?? json['author_avatar'] ?? '',
      data: json,
    );
  }
}

class SearchHistory {
  final String id;
  final String query;
  final DateTime searchedAt;
  
  SearchHistory({
    required this.id,
    required this.query,
    required this.searchedAt,
  });
  
  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'].toString(),
      query: json['query'],
      searchedAt: DateTime.parse(json['searched_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'searched_at': searchedAt.toIso8601String(),
    };
  }
}