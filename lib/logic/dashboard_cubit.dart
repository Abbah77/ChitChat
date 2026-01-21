import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/user.dart';
import 'models/post.dart';
import 'models/story.dart';
import 'models/post_privacy.dart';    // Add this
import 'models/story_status.dart';    // Add this
import 'services/api_service.dart';

// =================== Enums ===============================
enum PostPrivacy { public, friends, private }
enum StoryStatus { viewed, unviewed }

// ==================== DASHBOARD CUBIT ====================
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardInitial());

  final APIService _apiService = APIService();
  final List<Post> _posts = [];
  final List<Story> _stories = [];
  int _currentPage = 1;
  bool _hasMorePosts = true;
  bool _isLoadingMore = false;

  User? _currentUser;
  Map<String, dynamic>? _dashboardStats;
  List<Map<String, dynamic>> _notifications = [];

  Future<void> initializeDashboard({bool forceRefresh = false}) async {
    try {
      emit(DashboardLoading());

      if (forceRefresh) {
        _resetDashboard();
      }

      // Load data concurrently
      final results = await Future.wait([
        _loadCurrentUser(),
        _loadStories(),
        _loadPosts(page: 1, refresh: true),
        _loadNotifications(),
        _loadDashboardStats(),
      ]);

      // Assign loaded data
      _currentUser = results[0] as User? ?? _generateFallbackUser();
      _stories.clear();
      _stories.addAll(results[1] as List<Story>);
      _posts.clear();
      _posts.addAll(results[2] as List<Post>);
      _notifications = results[3] as List<Map<String, dynamic>>;
      _dashboardStats = results[4] as Map<String, dynamic>;

      _emitLoadedState();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace, 'Failed to load dashboard');
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) return;

    try {
      _isLoadingMore = true;
      emit(DashboardLoadingMore(posts: _posts));

      final newPosts = await _loadPosts(page: _currentPage + 1, refresh: false);
      _hasMorePosts = newPosts.isNotEmpty;

      if (newPosts.isNotEmpty) {
        _currentPage++;
        _posts.addAll(newPosts);
      }

      _emitLoadedState();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace, 'Failed to load more posts');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<User> _loadCurrentUser() async {
    try {
      final response = await _apiService.getUserProfile();
      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }
      return User.fromJson(response);
    } catch (e) {
      return _generateFallbackUser();
    }
  }

  Future<List<Story>> _loadStories() async {
    try {
      final response = await _apiService.fetchStories();
      if (response.containsKey('error')) {
        return _generateFallbackStories();
      }

      final storiesData = response['stories'] ?? response['data'] ?? [];
      return storiesData.map<Story>(_mapStoryData).toList();
    } catch (e) {
      return _generateFallbackStories();
    }
  }

  Future<List<Post>> _loadPosts({int page = 1, bool refresh = false}) async {
    try {
      final response = await _apiService.fetchPosts(page: page, limit: 10);
      if (response.containsKey('error')) {
        return _generateFallbackPosts();
      }

      final postsData = response['posts'] ?? response['data'] ?? [];
      return postsData.map<Post>(_mapPostData).toList();
    } catch (e) {
      debugPrint('Posts load error: $e');
      return _generateFallbackPosts();
    }
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    try {
      final response = await _apiService.fetchNotifications();
      return List<Map<String, dynamic>>.from(response['notifications'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _loadDashboardStats() async {
    try {
      final response = await _apiService.fetchDashboardData();
      return response['stats'] ?? _defaultStats();
    } catch (e) {
      return _defaultStats();
    }
  }

  Story _mapStoryData(Map<String, dynamic> storyData) {
    return Story(
      id: storyData['id'].toString(),
      imageUrl: storyData['image_url'] ?? storyData['media_url'] ?? '',
      videoUrl: storyData['video_url'] ?? '',
      userId: storyData['user_id'].toString(),
      userName: storyData['user_name'] ?? storyData['username'] ?? 'User',
      userAvatar: storyData['user_avatar'] ?? storyData['profile_image'] ?? '',
      timestamp: DateTime.parse(storyData['created_at'] ?? DateTime.now().toString()),
      viewers: List<String>.from(storyData['viewers'] ?? []),
      hasReplies: storyData['has_replies'] ?? false,
      status: storyData['is_viewed'] ?? false ? StoryStatus.viewed : StoryStatus.unviewed,
    );
  }

  Post _mapPostData(Map<String, dynamic> postData) {
    return Post(
      id: postData['id'].toString(),
      content: postData['content'] ?? '',
      author: User.fromJson(postData['author'] ?? {}),
      timestamp: DateTime.parse(postData['created_at'] ?? DateTime.now().toString()),
      mediaUrls: postData['media_urls'] != null ? List<String>.from(postData['media_urls']) : [],
      likeCount: postData['like_count'] ?? 0,
      commentCount: postData['comment_count'] ?? 0,
      shareCount: postData['share_count'] ?? 0,
      likes: postData['likes'] != null ? List<User>.from(postData['likes'].map((u) => User.fromJson(u))) : [],
      isLiked: postData['is_liked'] ?? false,
      isSaved: postData['is_saved'] ?? false,
      privacy: _parsePrivacy(postData['privacy']),
    );
  }

  List<Story> _generateFallbackStories() {
    return List.generate(5, (index) {
      return Story(
        id: 'fallback_story_$index',
        imageUrl: 'https://picsum.photos/400/600?random=$index',
        videoUrl: '',
        userId: 'user_$index',
        userName: ['Alex', 'Jamie', 'Taylor', 'Jordan', 'Casey'][index],
        userAvatar: 'https://i.pravatar.cc/150?img=${index + 1}',
        timestamp: DateTime.now().subtract(Duration(hours: index * 2)),
        viewers: [],
        hasReplies: index % 3 == 0,
        status: index % 2 == 0 ? StoryStatus.unviewed : StoryStatus.viewed,
      );
    });
  }

  List<Post> _generateFallbackPosts() {
    return List.generate(3, (index) {
      return Post(
        id: 'fallback_post_$index',
        content: 'This is a sample post for demonstration purposes.',
        author: User(
          id: 'user_$index',
          name: ['Alex Morgan', 'Jamie Smith', 'Taylor Jones'][index],
          email: '',
          username: ['alexm', 'jamies', 'taylorj'][index],
          profileImage: 'https://i.pravatar.cc/150?img=${index + 10}',
          coverImage: '',
          bio: 'Sample bio',
          postsCount: 10,
          followersCount: 100,
          followingCount: 50,
          isVerified: index == 0,
          isOnline: index % 2 == 0,
          lastSeen: DateTime.now(),
        ),
        timestamp: DateTime.now().subtract(Duration(hours: index * 3)),
        mediaUrls: index % 2 == 0 ? ['https://picsum.photos/600/400?random=$index'] : [],
        likeCount: 10 + index * 5,
        commentCount: 2 + index,
        shareCount: 1 + index,
        likes: [],
        isLiked: index % 3 == 0,
        isSaved: index % 4 == 0,
      );
    });
  }

  User _generateFallbackUser() {
    return User(
      id: 'fallback_user',
      name: 'Demo User',
      email: 'demo@example.com',
      username: 'demo_user',
      profileImage: 'https://i.pravatar.cc/150?img=50',
      coverImage: '',
      bio: 'Demo user for fallback',
      postsCount: 0,
      followersCount: 0,
      followingCount: 0,
      isVerified: false,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
  }

  Map<String, dynamic> _defaultStats() {
    return {
      'posts_today': 0,
      'interactions': 0,
      'new_followers': 0,
      'story_views': 0,
    };
  }

  PostPrivacy _parsePrivacy(String? privacy) {
    switch (privacy?.toLowerCase()) {
      case 'friends':
        return PostPrivacy.friends;
      case 'private':
        return PostPrivacy.private;
      default:
        return PostPrivacy.public;
    }
  }

  void _emitLoadedState() {
    if (_currentUser == null || _dashboardStats == null) {
      emit(DashboardError(
        message: 'Data not fully loaded',
        error: 'Missing user or stats data',
        retryCallback: () => loadDashboard(),
      ));
      return;
    }

    emit(DashboardLoaded(
      currentUser: _currentUser!,
      stories: _stories,
      posts: _posts,
      notifications: _notifications,
      stats: _dashboardStats!,
      hasMorePosts: _hasMorePosts,
      isLoadingMore: _isLoadingMore,
    ));
  }

  Future<void> likePost(String postId) async {
    try {
      final currentState = state;
      if (currentState is! DashboardLoaded) return;

      final updatedPosts = _optimisticUpdateLike(currentState.posts, postId);
      emit(currentState.copyWith(posts: updatedPosts));

      final post = _findPostById(currentState.posts, postId);
      if (post == null) return;

      final response = post.isLiked
          ? await _apiService.unlikePost(postId)
          : await _apiService.likePost(postId);

      if (response.containsKey('error')) {
        emit(currentState.copyWith(posts: List<Post>.from(currentState.posts)));
        debugPrint('Like failed: ${response['error']}');
      }
    } catch (e) {
      debugPrint('Like post error: $e');
    }
  }

  List<Post> _optimisticUpdateLike(List<Post> posts, String postId) {
    return posts.map((post) {
      if (post.id == postId) {
        final newLikeCount = post.isLiked ? post.likeCount - 1 : post.likeCount + 1;
        return post.copyWith(
          isLiked: !post.isLiked,
          likeCount: newLikeCount,
        );
      }
      return post;
    }).toList();
  }

  Post? _findPostById(List<Post> posts, String postId) {
    return posts.firstWhere((p) => p.id == postId, orElse: () => null);
  }

  Future<void> savePost(String postId) async {
    try {
      final response = await _apiService.savePost(postId);
      if (response.containsKey('error')) {
        debugPrint('Save post error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('Save post error: $e');
    }
  }

  Future<void> addComment(String postId, String comment) async {
    try {
      final response = await _apiService.addComment(postId, comment);
      if (response.containsKey('error')) {
        debugPrint('Add comment error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('Add comment error: $e');
    }
  }

  Future<void> sharePost(String postId) async {
    try {
      final response = await _apiService.sharePost(postId);
      if (response.containsKey('error')) {
        debugPrint('Share post error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('Share post error: $e');
    }
  }

  Future<void> markStoryAsViewed(String storyId) async {
    try {
      final currentState = state;
      if (currentState is! DashboardLoaded) return;

      final updatedStories = currentState.stories.map((story) {
        if (story.id == storyId) {
          return story.copyWith(status: StoryStatus.viewed);
        }
        return story;
      }).toList();

      emit(currentState.copyWith(stories: updatedStories));
      await _apiService.viewStory(storyId);
    } catch (e) {
      debugPrint('Mark story as viewed error: $e');
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboard(forceRefresh: true);
  }

  void _resetDashboard() {
    _currentPage = 1;
    _hasMorePosts = true;
    _posts.clear();
    _stories.clear();
  }

  void _handleError(dynamic e, StackTrace stackTrace, String message) {
    debugPrint('$message: $e\n$stackTrace');
    emit(DashboardError(
      message: message,
      error: e.toString(),
      retryCallback: () => initializeDashboard(forceRefresh: true),
    ));
  }
}

// ==================== DASHBOARD STATES ====================
abstract class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoadingMore extends DashboardState {
  final List<Post> posts;
  const DashboardLoadingMore({required this.posts});
}

class DashboardLoaded extends DashboardState {
  final User currentUser;
  final List<Story> stories;
  final List<Post> posts;
  final List<Map<String, dynamic>> notifications;
  final Map<String, dynamic> stats;
  final bool hasMorePosts;
  final bool isLoadingMore;

  const DashboardLoaded({
    required this.currentUser,
    required this.stories,
    required this.posts,
    required this.notifications,
    required this.stats,
    this.hasMorePosts = true,
    this.isLoadingMore = false,
  });

  DashboardLoaded copyWith({
    User? currentUser,
    List<Story>? stories,
    List<Post>? posts,
    List<Map<String, dynamic>>? notifications,
    Map<String, dynamic>? stats,
    bool? hasMorePosts,
    bool? isLoadingMore,
  }) {
    return DashboardLoaded(
      currentUser: currentUser ?? this.currentUser,
      stories: stories ?? this.stories,
      posts: posts ?? this.posts,
      notifications: notifications ?? this.notifications,
      stats: stats ?? this.stats,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class DashboardError extends DashboardState {
  final String message;
  final String error;
  final VoidCallback? retryCallback;

  const DashboardError({
    required this.message,
    required this.error,
    this.retryCallback,
  });
}