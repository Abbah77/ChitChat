import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'models/chat_models.dart';
import 'services/api_service.dart';
import 'dashboard.dart';

// ==================== STATE MANAGEMENT ====================
class ProfileCubit extends Cubit<ProfileState> {
  final String? userId;
  final APIService _apiService = APIService();
  User? _profileUser;
  bool _isCurrentUser = false;

  ProfileCubit({this.userId}) : super(ProfileInitial()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      emit(ProfileLoading());
      
      // Check if viewing own profile or other user's profile
      _isCurrentUser = userId == null;
      
      if (_isCurrentUser) {
        // Load current user profile
        final response = await _apiService.getUserProfile();
        if (response['error'] != null) throw Exception(response['error']);
        _profileUser = User.fromJson(response);
      } else {
        // Load other user's profile (this would need a separate API endpoint)
        // For now, simulate with current user data
        final response = await _apiService.getUserProfile();
        if (response['error'] != null) throw Exception(response['error']);
        _profileUser = User.fromJson(response);
      }
      
      // Load additional data
      final results = await Future.wait([
        _loadUserPosts(),
        _loadFollowers(),
        _loadFollowing(),
        _loadMutualFriends(),
        _loadStories(),
      ]);
      
      emit(ProfileLoaded(
        user: _profileUser!,
        isCurrentUser: _isCurrentUser,
        posts: results[0] as List<Post>,
        followers: results[1] as List<User>,
        following: results[2] as List<User>,
        mutualFriends: results[3] as List<User>,
        stories: results[4] as List<Story>,
        isFollowing: !_isCurrentUser && Random().nextBool(), // Simulate follow state
        isBlocked: false,
      ));
    } catch (e, stackTrace) {
      debugPrint('Profile load error: $e\n$stackTrace');
      emit(ProfileError('Failed to load profile: ${e.toString()}'));
    }
  }

  Future<List<Post>> _loadUserPosts() async {
    try {
      final response = await _apiService.fetchPosts();
      if (response['error'] != null) return [];
      
      final postsData = response['posts'] ?? response['data'] ?? [];
      return postsData.take(20).map((postData) {
        return Post(
          id: postData['id'].toString(),
          content: postData['content'] ?? '',
          author: _profileUser!,
          timestamp: DateTime.parse(postData['created_at'] ?? DateTime.now().toString()),
          mediaUrls: postData['media_urls'] != null 
              ? List<String>.from(postData['media_urls'])
              : [],
          likeCount: postData['like_count'] ?? 0,
          commentCount: postData['comment_count'] ?? 0,
          shareCount: postData['share_count'] ?? 0,
          isLiked: postData['is_liked'] ?? false,
          isSaved: postData['is_saved'] ?? false,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> _loadFollowers() async {
    try {
      // This would call a specific API endpoint for followers
      await Future.delayed(const Duration(milliseconds: 300));
      return List.generate(12, (index) {
        return User(
          id: 'follower_$index',
          name: 'Follower $index',
          username: 'follower$index',
          email: 'follower$index@example.com',
          profileImage: 'https://picsum.photos/150/150?random=$index',
          isOnline: Random().nextBool(),
        );
      });
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> _loadFollowing() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return List.generate(8, (index) {
        return User(
          id: 'following_$index',
          name: 'Following $index',
          username: 'following$index',
          email: 'following$index@example.com',
          profileImage: 'https://picsum.photos/150/150?random=${index + 20}',
          isOnline: Random().nextBool(),
        );
      });
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> _loadMutualFriends() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return List.generate(5, (index) {
        return User(
          id: 'mutual_$index',
          name: 'Mutual Friend $index',
          username: 'mutual$index',
          email: 'mutual$index@example.com',
          profileImage: 'https://picsum.photos/150/150?random=${index + 40}',
          isOnline: Random().nextBool(),
        );
      });
    } catch (e) {
      return [];
    }
  }

  Future<List<Story>> _loadStories() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return List.generate(3, (index) {
        return Story(
          id: 'story_$index',
          imageUrl: 'https://picsum.photos/400/800?random=$index',
          videoUrl: '',
          userId: _profileUser?.id ?? '',
          userName: _profileUser?.name ?? 'User',
          userAvatar: _profileUser?.profileImage ?? '',
          timestamp: DateTime.now().subtract(Duration(hours: index)),
          viewers: [],
          hasReplies: Random().nextBool(),
          status: StoryStatus.unviewed,
        );
      });
    } catch (e) {
      return [];
    }
  }

  Future<void> followUser() async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;
    
    try {
      emit(currentState.copyWith(isFollowing: true));
      // Call API to follow
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      emit(currentState.copyWith(isFollowing: false));
    }
  }

  Future<void> unfollowUser() async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;
    
    try {
      emit(currentState.copyWith(isFollowing: false));
      // Call API to unfollow
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      emit(currentState.copyWith(isFollowing: true));
    }
  }

  Future<void> blockUser() async {
    final currentState = state;
    if (currentState is! ProfileLoaded || currentState.isCurrentUser) return;
    
    try {
      emit(currentState.copyWith(isBlocked: true));
      // Call API to block
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      emit(currentState.copyWith(isBlocked: false));
    }
  }

  Future<void> unblockUser() async {
    final currentState = state;
    if (currentState is! ProfileLoaded || currentState.isCurrentUser) return;
    
    try {
      emit(currentState.copyWith(isBlocked: false));
      // Call API to unblock
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      emit(currentState.copyWith(isBlocked: true));
    }
  }

  Future<void> editProfile(Map<String, dynamic> updates) async {
    final currentState = state;
    if (currentState is! ProfileLoaded || !currentState.isCurrentUser) return;
    
    try {
      final response = await _apiService.updateProfile(
        name: updates['name'] ?? currentState.user.name,
        username: updates['username'] ?? currentState.user.username,
        email: updates['email'] ?? currentState.user.email,
        dateOfBirth: updates['dateOfBirth'] ?? currentState.user.dateOfBirth?.toIso8601String().split('T').first,
        gender: updates['gender'] ?? currentState.user.gender,
      );
      
      if (response['error'] == null) {
        final updatedUser = currentState.user.copyWith(
          name: updates['name'] ?? currentState.user.name,
          username: updates['username'] ?? currentState.user.username,
          email: updates['email'] ?? currentState.user.email,
          bio: updates['bio'] ?? currentState.user.bio,
          phoneNumber: updates['phoneNumber'] ?? currentState.user.phoneNumber,
        );
        emit(currentState.copyWith(user: updatedUser));
      }
    } catch (e) {
      debugPrint('Edit profile error: $e');
    }
  }
}

abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;
  final bool isCurrentUser;
  final List<Post> posts;
  final List<User> followers;
  final List<User> following;
  final List<User> mutualFriends;
  final List<Story> stories;
  final bool isFollowing;
  final bool isBlocked;

  const ProfileLoaded({
    required this.user,
    required this.isCurrentUser,
    required this.posts,
    required this.followers,
    required this.following,
    required this.mutualFriends,
    required this.stories,
    required this.isFollowing,
    required this.isBlocked,
  });

  ProfileLoaded copyWith({
    User? user,
    bool? isCurrentUser,
    List<Post>? posts,
    List<User>? followers,
    List<User>? following,
    List<User>? mutualFriends,
    List<Story>? stories,
    bool? isFollowing,
    bool? isBlocked,
  }) {
    return ProfileLoaded(
      user: user ?? this.user,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      posts: posts ?? this.posts,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      mutualFriends: mutualFriends ?? this.mutualFriends,
      stories: stories ?? this.stories,
      isFollowing: isFollowing ?? this.isFollowing,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
}

// ==================== MAIN PROFILE WIDGET ====================
class Profile extends StatelessWidget {
  final Map<String, dynamic>? userProfile;
  final String? userId;

  const Profile({super.key, this.userProfile, this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(userId: userId),
      child: const ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildAppBar(context, state),
                if (state is ProfileLoaded) _buildProfileHeader(state),
                _buildTabBar(),
              ];
            },
            body: _buildTabContent(context, state),
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, ProfileState state) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: state is ProfileLoaded
          ? Text(
              state.user.name,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            )
          : const SizedBox.shrink(),
      actions: _buildAppBarActions(context, state),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, ProfileState state) {
    if (state is! ProfileLoaded) return [];
    
    return [
      IconButton(
        icon: const Icon(Icons.search, color: Colors.black87),
        onPressed: () {},
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.black87),
        onSelected: (value) => _handleMenuAction(context, value, state),
        itemBuilder: (context) => _buildMoreMenu(context, state),
      ),
    ];
  }

  List<PopupMenuEntry<String>> _buildMoreMenu(BuildContext context, ProfileLoaded state) {
    final items = <PopupMenuEntry<String>>[];
    
    if (state.isCurrentUser) {
      items.addAll([
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Profile'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
          ),
        ),
      ]);
    } else {
      items.addAll([
        PopupMenuItem<String>(
          value: 'message',
          child: ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Send Message'),
          ),
        ),
        PopupMenuItem<String>(
          value: state.isFollowing ? 'unfollow' : 'follow',
          child: ListTile(
            leading: Icon(state.isFollowing ? Icons.person_remove : Icons.person_add),
            title: Text(state.isFollowing ? 'Unfollow' : 'Follow'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: state.isBlocked ? 'unblock' : 'block',
          child: ListTile(
            leading: Icon(state.isBlocked ? Icons.lock_open : Icons.block),
            title: Text(state.isBlocked ? 'Unblock User' : 'Block User'),
            textColor: state.isBlocked ? null : Colors.red,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'report',
          child: ListTile(
            leading: Icon(Icons.flag, color: Colors.red),
            title: Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ),
      ]);
    }
    
    return items;
  }

  void _handleMenuAction(BuildContext context, String value, ProfileLoaded state) {
    final cubit = context.read<ProfileCubit>();
    
    switch (value) {
      case 'edit':
        _showEditProfileModal(context, state);
        break;
      case 'settings':
        // Navigate to settings
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
      case 'message':
        // Navigate to chat with this user
        break;
      case 'follow':
        cubit.followUser();
        break;
      case 'unfollow':
        cubit.unfollowUser();
        break;
      case 'block':
        _showBlockDialog(context, cubit);
        break;
      case 'unblock':
        cubit.unblockUser();
        break;
      case 'report':
        _showReportDialog(context);
        break;
    }
  }

  SliverToBoxAdapter _buildProfileHeader(ProfileLoaded state) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildCoverPhoto(state),
            _buildProfileInfo(state),
            _buildActionButtons(state),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

// ==============BUILD COVER PHOTO==============
  Widget _buildCoverPhoto(ProfileLoaded state) {
  return Stack(
    children: [
      // Parallax Cover Photo
      Container(
        height: 250,
        width: double.infinity,
        child: Hero(
          tag: 'cover_${state.user.id}',
          child: CachedNetworkImage(
            imageUrl: 'https://picsum.photos/1200/500?random=${state.user.id}',
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildCoverPlaceholder(),
            errorWidget: (context, url, error) => _buildCoverError(),
          ),
        ),
      ),
      
      // Gradient Overlay
      Container(
        height: 250,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
              Colors.black.withOpacity(0.2),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
      
      // Profile Picture with Animation
      Positioned(
        bottom: -60,
        left: 20,
        child: GestureDetector(
          onTap: () => _showProfilePictureModal(context, state),
          child: Hero(
            tag: 'avatar_${state.user.id}',
            child: Stack(
              children: [
                // Outer Glow Ring
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent,
                        Colors.purpleAccent,
                        Colors.pinkAccent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                
                // Profile Picture Container
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: state.user.profileImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildAvatarPlaceholder(state),
                        errorWidget: (context, url, error) => _buildAvatarError(state),
                      ),
                    ),
                  ),
                ),
                
                // Verified Badge
                if (state.user.isVerified)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                
                // Edit Badge (for current user)
                if (state.isCurrentUser)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showEditAvatarModal(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      
      // Cover Photo Edit Button (for current user)
      if (state.isCurrentUser)
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () => _showEditCoverPhotoModal(context),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 4,
            child: const Icon(Icons.camera_alt, size: 20),
          ),
        ),
    ],
  );
}

Widget _buildCoverPlaceholder() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      color: Colors.grey.shade300,
    ),
  );
}

Widget _buildCoverError() {
  return Container(
    color: Colors.blueAccent.withOpacity(0.1),
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape, size: 60, color: Colors.blueAccent),
          SizedBox(height: 8),
          Text(
            'Cover Photo',
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildAvatarPlaceholder(ProfileLoaded state) {
  return Container(
    color: Colors.grey.shade200,
    child: Center(
      child: Text(
        state.user.name.isNotEmpty ? state.user.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    ),
  );
}

Widget _buildAvatarError(ProfileLoaded state) {
  return Container(
    color: Colors.blueAccent.withOpacity(0.1),
    child: Center(
      child: Text(
        state.user.name.isNotEmpty ? state.user.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    ),
  );
}

Widget _buildProfileInfo(ProfileLoaded state) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and Username with Animation
        _buildNameSection(state),
        const SizedBox(height: 12),
        
        // Bio with Expand/Collapse
        if (state.user.bio?.isNotEmpty == true)
          _buildBioSection(state),
        
        // Contact Info
        _buildContactInfoSection(state),
        const SizedBox(height: 16),
        
        // Statistics with Counting Animation
        _buildAnimatedStatsSection(state),
        
        // Mutual Friends Section
        if (!state.isCurrentUser && state.mutualFriends.isNotEmpty)
          _buildMutualFriendsSection(state),
      ],
    ),
  );
}

Widget _buildNameSection(ProfileLoaded state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Name with Verification Badge
      Row(
        children: [
          Expanded(
            child: TweenAnimationBuilder<int>(
              duration: const Duration(seconds: 2),
              tween: IntTween(begin: 0, end: state.user.name.length),
              builder: (context, value, child) {
                return Text(
                  state.user.name.substring(0, value),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                );
              },
            ),
          ),
          if (state.user.isVerified)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 14, color: Colors.blueAccent),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      
      const SizedBox(height: 4),
      
      // Username
      TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Text(
          '@${state.user.username}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    ],
  );
}

Widget _buildBioSection(ProfileLoaded state) {
  return StatefulBuilder(
    builder: (context, setState) {
      bool isExpanded = false;
      final maxLines = 2;
      final bio = state.user.bio!;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              bio.length > 100 && !isExpanded
                  ? '${bio.substring(0, 100)}...'
                  : bio,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              maxLines: isExpanded ? null : maxLines,
              overflow: isExpanded ? null : TextOverflow.ellipsis,
            ),
            secondChild: Text(
              bio,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
            ),
          ),
          if (bio.length > 100)
            GestureDetector(
              onTap: () => setState(() => isExpanded = !isExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isExpanded ? 'Show less' : 'Show more',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

Widget _buildContactInfoSection(ProfileLoaded state) {
  final contactItems = <Widget>[];
  
  if (state.user.phoneNumber?.isNotEmpty == true) {
    contactItems.add(
      _buildContactItem(
        icon: Icons.phone,
        text: state.user.phoneNumber!,
        onTap: () => _launchPhoneCall(state.user.phoneNumber!),
      ),
    );
  }
  
  if (state.user.dateOfBirth != null) {
    contactItems.add(
      _buildContactItem(
        icon: Icons.cake,
        text: 'Born ${_formatDate(state.user.dateOfBirth!)}',
      ),
    );
  }
  
  if (state.user.gender?.isNotEmpty == true) {
    contactItems.add(
      _buildContactItem(
        icon: Icons.transgender,
        text: state.user.gender!,
      ),
    );
  }
  
  if (state.user.createdAt != null) {
    contactItems.add(
      _buildContactItem(
        icon: Icons.calendar_today,
        text: 'Joined ${_formatDate(state.user.createdAt!)}',
      ),
    );
  }
  
  return Column(
    children: contactItems,
  );
}

Widget _buildContactItem({
  required IconData icon,
  required String text,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    ),
  );
}

Widget _buildAnimatedStatsSection(ProfileLoaded state) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Colors.grey.shade300),
        bottom: BorderSide(color: Colors.grey.shade300),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _AnimatedStatItem(
          count: state.posts.length,
          label: 'Posts',
          onTap: () => _tabController.animateTo(0),
          color: Colors.blueAccent,
        ),
        _AnimatedStatItem(
          count: state.followers.length,
          label: 'Followers',
          onTap: () => _showFollowersModal(context, state),
          color: Colors.green,
        ),
        _AnimatedStatItem(
          count: state.following.length,
          label: 'Following',
          onTap: () => _showFollowingModal(context, state),
          color: Colors.purpleAccent,
        ),
        _AnimatedStatItem(
          count: state.stories.length,
          label: 'Stories',
          onTap: () => _showStoriesModal(context, state),
          color: Colors.orangeAccent,
        ),
      ],
    ),
  );
}

class _AnimatedStatItem extends StatefulWidget {
  final int count;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _AnimatedStatItem({
    required this.count,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  State<_AnimatedStatItem> createState() => __AnimatedStatItemState();
}

class __AnimatedStatItemState extends State<_AnimatedStatItem> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _countAnimation;
  int _animatedCount = 0;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 0.3),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 0.7),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    
    _countAnimation = Tween<double>(
      begin: 0,
      end: widget.count.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    )..addListener(() {
        setState(() {
          _animatedCount = _countAnimation.value.toInt();
        });
      });
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.reset();
        _controller.forward();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Column(
          children: [
            Text(
              _animatedCount.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.color,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: widget.color.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildMutualFriendsSection(ProfileLoaded state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.people, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              '${state.mutualFriends.length} mutual friends',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: state.mutualFriends.length,
          itemBuilder: (context, index) {
            final friend = state.mutualFriends[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _MutualFriendCircle(friend: friend),
            );
          },
        ),
      ),
    ],
  );
}

class _MutualFriendCircle extends StatefulWidget {
  final User friend;

  const _MutualFriendCircle({required this.friend});

  @override
  State<_MutualFriendCircle> createState() => __MutualFriendCircleState();
}

class __MutualFriendCircleState extends State<_MutualFriendCircle> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.reset();
        _controller.forward();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Profile(userId: widget.friend.id),
          ),
        );
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.friend.isOnline
                    ? const LinearGradient(
                        colors: [Colors.green, Colors.lightGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade400],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.friend.profileImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 50,
              child: Text(
                widget.friend.name.split(' ').first,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Methods
String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

void _launchPhoneCall(String phoneNumber) {
  // Implement phone call functionality
}

void _showProfilePictureModal(BuildContext context, ProfileLoaded state) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Hero(
          tag: 'avatar_${state.user.id}',
          child: Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(state.user.profileImage),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _showEditAvatarModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
            title: const Text('Take Photo'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
            title: const Text('Choose from Gallery'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Remove Profile Picture', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    ),
  );
}

  Widget _buildActionButtons(ProfileLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          if (state.isCurrentUser)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showEditProfileModal(context, state),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (state.isFollowing) {
                          context.read<ProfileCubit>().unfollowUser();
                        } else {
                          context.read<ProfileCubit>().followUser();
                        }
                      },
                      icon: Icon(
                        state.isFollowing ? Icons.person_remove : Icons.person_add,
                        size: 18,
                      ),
                      label: Text(state.isFollowing ? 'Following' : 'Follow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isFollowing ? Colors.grey.shade200 : Colors.blueAccent,
                        foregroundColor: state.isFollowing ? Colors.black87 : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to chat with this user
                      },
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: () {},
            backgroundColor: Colors.grey.shade100,
            child: const Icon(Icons.more_horiz, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        tabController: _tabController,
        selectedIndex: _selectedTabIndex,
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, ProfileState state) {
    if (state is ProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ProfileError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ProfileCubit>().loadProfile(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is ProfileLoaded) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(state),
          _buildPhotosTab(state),
          _buildAboutTab(state),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPostsTab(ProfileLoaded state) {
    if (state.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.post_add, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.isCurrentUser ? 'No posts yet' : 'No posts',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              state.isCurrentUser 
                  ? 'Share your first post!' 
                  : 'This user hasn\'t posted anything yet',
              style: const TextStyle(color: Colors.grey),
            ),
            if (state.isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to dashboard to create post
                  },
                  child: const Text('Create Post'),
                ),
              ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: state.posts.length,
      itemBuilder: (context, index) {
        final post = state.posts[index];
        return GestureDetector(
          onTap: () => _showPostDetail(context, post),
          child: Container(
            color: Colors.grey.shade200,
            child: post.mediaUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: post.mediaUrls.first,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      post.content.length > 30
                          ? '${post.content.substring(0, 30)}...'
                          : post.content,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildPhotosTab(ProfileLoaded state) {
    final photos = state.posts
        .where((post) => post.mediaUrls.isNotEmpty)
        .expand((post) => post.mediaUrls)
        .toList();

    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No photos',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showPhotoViewer(context, photos, index),
          child: CachedNetworkImage(
            imageUrl: photos[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey.shade200),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab(ProfileLoaded state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAboutSection(
          icon: Icons.info_outline,
          title: 'About',
          children: [
            if (state.user.bio?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.short_text),
                title: const Text('Bio'),
                subtitle: Text(state.user.bio!),
              ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(state.user.email),
            ),
            if (state.user.phoneNumber?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Phone'),
                subtitle: Text(state.user.phoneNumber!),
              ),
            if (state.user.dateOfBirth != null)
              ListTile(
                leading: const Icon(Icons.cake),
                title: const Text('Birthday'),
                subtitle: Text(
                  '${state.user.dateOfBirth!.day}/${state.user.dateOfBirth!.month}/${state.user.dateOfBirth!.year}',
                ),
              ),
            if (state.user.gender?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.transgender),
                title: const Text('Gender'),
                subtitle: Text(state.user.gender!),
              ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Joined'),
              subtitle: Text(
                state.user.createdAt != null
                    ? '${state.user.createdAt!.day}/${state.user.createdAt!.month}/${state.user.createdAt!.year}'
                    : 'Unknown',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildAboutSection(
          icon: Icons.people,
          title: 'Connections',
          children: [
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Followers'),
              trailing: Text('${state.followers.length}'),
              onTap: () => _showFollowersModal(context, state),
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Following'),
              trailing: Text('${state.following.length}'),
              onTap: () => _showFollowingModal(context, state),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // ==================== MODAL DIALOGS ====================
  void _showEditProfileModal(BuildContext context, ProfileLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditProfileModal(
        user: state.user,
        onSave: (updates) => context.read<ProfileCubit>().editProfile(updates),
      ),
    );
  }

  void _showEditCoverPhotoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle),
              title: const Text('Remove Cover Photo'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showFollowersModal(BuildContext context, ProfileLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => UsersListModal(
        title: 'Followers',
        users: state.followers,
      ),
    );
  }

  void _showFollowingModal(BuildContext context, ProfileLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => UsersListModal(
        title: 'Following',
        users: state.following,
      ),
    );
  }

  void _showStoriesModal(BuildContext context, ProfileLoaded state) {
    if (state.stories.isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewer(
          stories: state.stories,
          initialIndex: 0,
        ),
      ),
    );
  }

  void _showPostDetail(BuildContext context, Post post) {
    // Implement post detail view
  }

  void _showPhotoViewer(BuildContext context, List<String> photos, int index) {
    // Implement photo viewer
  }

  void _showBlockDialog(BuildContext context, ProfileCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cubit.blockUser();
              Navigator.pop(context);
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text('Please select a reason for reporting this user.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement logout
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Dashboard()),
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================
class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;

  const _StatItem({
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final int selectedIndex;

  _TabBarDelegate({
    required this.tabController,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        indicatorColor: Colors.blueAccent,
        labelColor: Colors.blueAccent,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
          Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
          Tab(icon: Icon(Icons.info_outline), text: 'About'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

// ==================== MODAL WIDGETS ====================
class EditProfileModal extends StatefulWidget {
  final User user;
  final Function(Map<String, dynamic>) onSave;

  const EditProfileModal({
    super.key,
    required this.user,
    required this.onSave,
  });

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _usernameController.text = widget.user.username;
    _emailController.text = widget.user.email;
    _bioController.text = widget.user.bio ?? '';
    _phoneController.text = widget.user.phoneNumber ?? '';
    _selectedGender = widget.user.gender;
    _selectedDate = widget.user.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final updates = {
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'bio': _bioController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'gender': _selectedGender,
      'dateOfBirth': _selectedDate?.toIso8601String().split('T').first,
    };
    
    widget.onSave(updates);
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a username';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : '',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
                DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
              ],
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class UsersListModal extends StatelessWidget {
  final String title;
  final List<User> users;

  const UsersListModal({
    super.key,
    required this.title,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title, // Fixed: Now uses the actual title variable
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(user.profileImage),
                  ),
                  title: Text(user.name),
                  subtitle: Text('@${user.username}'),
                  trailing: user.isOnline
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Profile(userId: user.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} // This is the final closing bracket for the class and the file.
