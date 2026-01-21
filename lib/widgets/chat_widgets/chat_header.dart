import 'package:flutter/material.dart';
import 'package:chitchat/models/chat_models.dart';

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final Chat chat;
  final VoidCallback onBack;
  final VoidCallback onContactInfo;
  final VoidCallback onVideoCall;
  final VoidCallback onVoiceCall;
  final VoidCallback onClearChat;
  final VoidCallback onBlockUser;
  final VoidCallback onMuteNotifications;
  final VoidCallback onShowMedia;

  const ChatHeader({
    super.key,
    required this.chat,
    required this.onBack,
    required this.onContactInfo,
    required this.onVideoCall,
    required this.onVoiceCall,
    required this.onClearChat,
    required this.onBlockUser,
    required this.onMuteNotifications,
    required this.onShowMedia,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
      ),
      title: GestureDetector(
        onTap: onContactInfo,
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${chat.id}',
              child: CircleAvatar(
                radius: 18,
                backgroundImage: chat.isGroup ? null : NetworkImage(chat.profileImage),
                backgroundColor: chat.isAI 
                    ? Colors.blueAccent 
                    : (chat.isGroup ? Colors.grey[400] : Colors.grey[300]),
                child: chat.isAI 
                    ? const Icon(Icons.psychology, size: 20, color: Colors.white)
                    : (chat.isGroup 
                        ? const Icon(Icons.people, color: Colors.white)
                        : (chat.profileImage.isEmpty
                            ? Text(
                                chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              )
                            : null)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.name, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  _buildStatusText(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (chat.isAI) ...[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart conversation',
            onPressed: onClearChat,
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.video_call),
            tooltip: 'Video call',
            onPressed: onVideoCall,
          ),
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Voice call',
            onPressed: onVoiceCall,
          ),
        ],
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleAppBarMenu(value, context),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Contact Info'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'media',
              child: Row(
                children: [
                  Icon(Icons.photo_library, size: 20),
                  SizedBox(width: 8),
                  Text('Media, links & docs'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.notifications_off, size: 20),
                  SizedBox(width: 8),
                  Text('Mute notifications'),
                ],
              ),
            ),
            if (!chat.isAI) const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Block', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusText() {
    if (chat.isAI) {
      return const Text(
        'AI Assistant • Online',
        style: TextStyle(fontSize: 12, color: Colors.green),
      );
    }
    
    if (chat.isOnline) {
      return const Text(
        'Online',
        style: TextStyle(fontSize: 12, color: Colors.green),
      );
    }
    
    return Text(
      'Last seen ${_formatStatusTime(chat.time)}',
      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    );
  }

  void _handleAppBarMenu(String value, BuildContext context) {
    switch (value) {
      case 'info':
        onContactInfo();
        break;
      case 'media':
        onShowMedia();
        break;
      case 'mute':
        onMuteNotifications();
        break;
      case 'block':
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
                  onBlockUser();
                },
                child: const Text('Block', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        break;
    }
  }

  String _formatStatusTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return 'today at ${_formatTime(time)}';
    if (difference.inDays == 1) return 'yesterday';
    return '${time.day}/${time.month}/${time.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
