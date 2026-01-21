import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:chitchat/logic/chat_cubit.dart';
import 'package:chitchat/models/chat_models.dart';
import 'package:chitchat/screens/chat/chat_room_screen.dart';
import 'package:chitchat/screens/profile.dart';
import 'package:chitchat/widgets/chat_widgets/chat_list_item.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubit(),
      child: const _ChatPageContent(),
    );
  }
}

class _ChatPageContent extends StatefulWidget {
  const _ChatPageContent();

  @override
  State<_ChatPageContent> createState() => __ChatPageContentState();
}

class __ChatPageContentState extends State<_ChatPageContent> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<ChatCubit>().updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildSearchBar(),
              // NO STORIES SECTION HERE - JUST SEARCH AND CHAT LIST
              _buildChatList(context, state),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatModal(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Messages'),
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showNewChatModal(context),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, ChatState state) {
    if (state is ChatLoading) {
      return Expanded(
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) => _buildChatShimmer(),
        ),
      );
    }

    if (state is ChatError) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(state.message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<ChatCubit>().loadChats(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ChatLoaded) {
      if (state.filteredChats.isEmpty) {
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No conversations yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  state.searchQuery.isEmpty
                      ? 'Start a new conversation!'
                      : 'No results for "${state.searchQuery}"',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }

      return Expanded(
        child: ListView.builder(
          itemCount: state.filteredChats.length,
          itemBuilder: (context, index) {
            final chat = state.filteredChats[index];
            return ChatListItem(
              chat: chat,
              isTyping: state.typingStatus[chat.id] ?? false,
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<ChatCubit>().markAsRead(chat.id);
                _navigateToChatRoom(context, chat);
              },
              onPin: () => context.read<ChatCubit>().togglePin(chat.id),
              onDelete: () => _showDeleteDialog(context, chat),
              onMute: () => _showMuteSnackbar(context, chat),
              onViewProfile: () => _navigateToUserProfile(chat),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildChatShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChatRoom(BuildContext context, Chat chat) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatRoom(chat: chat),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showMuteSnackbar(BuildContext context, Chat chat) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${chat.name} muted'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Undo mute logic
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Chat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete chat with ${chat.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatCubit>().deleteChat(chat.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted chat with ${chat.name}')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToUserProfile(Chat chat) {
    final userData = {
      'id': chat.id,
      'name': chat.name,
      'username': chat.name.toLowerCase().replaceAll(' ', ''),
      'email': '${chat.name.toLowerCase().replaceAll(' ', '.')}@example.com',
      'profile_image': chat.profileImage,
      'is_online': chat.isOnline,
      'is_verified': chat.isAI,
      'bio': chat.isAI 
          ? 'Your AI assistant ready to help you with anything!'
          : 'Active on ChitChat. Let\'s connect!',
      'phone_number': '+1234567890',
      'gender': 'Prefer not to say',
      'is_friend': true,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Profile(userProfile: userData),
      ),
    );
  }

  void _showNewChatModal(BuildContext context) {
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
              leading: const Icon(Icons.person_add, color: Colors.blueAccent),
              title: const Text('New Chat'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to new chat screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: Colors.blueAccent),
              title: const Text('New Group'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to new group screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blueAccent),
              title: const Text('Scan QR Code'),
              onTap: () {
                Navigator.pop(context);
                // Open QR scanner
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context, Chat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${chat.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Blocked ${chat.name}')),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
