import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chitchat/models/chat_models.dart';
import 'package:chitchat/widgets/chat_widgets/typing_indicator.dart';

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final bool isTyping;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback onMute;
  final VoidCallback onViewProfile;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.isTyping,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
    required this.onMute,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('chat_${chat.id}_${chat.time.millisecondsSinceEpoch}'),
      direction: DismissDirection.horizontal,
      background: _buildDismissBackground(Colors.orange, Icons.notifications_off, Alignment.centerLeft),
      secondaryBackground: _buildDismissBackground(Colors.red, Icons.delete, Alignment.centerRight),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          _showContextMenu(context);
          return false;
        } else {
          onMute();
          HapticFeedback.lightImpact();
          return false;
        }
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          color: chat.unreadCount > 0 ? Colors.blue.withOpacity(0.05) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: chat.isPinned 
                    ? Colors.blueAccent.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                width: chat.isPinned ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Profile Avatar
                _buildAnimatedAvatar(),
                
                const SizedBox(width: 12),
                
                // Chat Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: chat.unreadCount > 0 
                                    ? FontWeight.bold 
                                    : FontWeight.w600,
                                color: chat.isAI 
                                    ? Colors.blueAccent 
                                    : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.isPinned)
                            const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.push_pin_rounded, 
                                  size: 16, color: Colors.blueAccent),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Message Preview with Typing Indicator
                      isTyping 
                          ? _buildTypingIndicator()
                          : _buildMessagePreview(),
                    ],
                  ),
                ),
                
                // Time and Status Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTimeWidget(),
                    const SizedBox(height: 8),
                    _buildStatusWidget(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Stack(
        children: [
          // Avatar Container with Glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: chat.isAI 
                  ? const LinearGradient(
                      colors: [Colors.blueAccent, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : (chat.isOnline && !chat.isGroup)
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
                  color: chat.isOnline && !chat.isGroup
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: chat.profileImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: chat.profileImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: chat.isAI ? Colors.blueAccent : Colors.grey,
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            chat.isAI 
                                ? Icons.psychology 
                                : (chat.isGroup ? Icons.people : Icons.person),
                            color: chat.isAI ? Colors.blueAccent : Colors.grey,
                            size: 24,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: chat.isAI ? Colors.blueAccent : Colors.grey,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          
          // Online Indicator
          if (chat.isOnline && !chat.isGroup && !chat.isAI)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        const Icon(Icons.edit, size: 14, color: Colors.blueAccent),
        const SizedBox(width: 6),
        Text(
          'Typing',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blueAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        const TypingIndicator(),
      ],
    );
  }

  Widget _buildMessagePreview() {
    final messageText = _getMessagePreview();
    final hasUnread = chat.unreadCount > 0;
    
    return Row(
      children: [
        if (chat.lastMessageType != MessageType.text)
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Icon(
              chat.lastMessageType == MessageType.photo ? Icons.photo :
              chat.lastMessageType == MessageType.voice ? Icons.mic :
              chat.lastMessageType == MessageType.sticker ? Icons.emoji_emotions :
              chat.lastMessageType == MessageType.video ? Icons.videocam :
              Icons.chat,
              size: 16,
              color: hasUnread ? Colors.blueAccent : Colors.grey[600],
            ),
          ),
        
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              messageText,
              key: ValueKey(chat.lastMessage + chat.time.toString()),
              style: TextStyle(
                fontSize: 14,
                color: hasUnread ? Colors.blueAccent : Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  String _getMessagePreview() {
    switch (chat.lastMessageType) {
      case MessageType.photo:
        return 'Photo';
      case MessageType.voice:
        return 'Voice Note';
      case MessageType.sticker:
        return 'Sticker';
      case MessageType.video:
        return 'Video';
      case MessageType.text:
      default:
        return chat.lastMessage;
    }
  }

  Widget _buildTimeWidget() {
    final isRecent = DateTime.now().difference(chat.time).inHours < 1;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRecent 
            ? Colors.blueAccent.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatTime(),
        style: TextStyle(
          fontSize: 12,
          color: chat.unreadCount > 0 
              ? Colors.blueAccent 
              : (isRecent ? Colors.blueAccent : Colors.grey[600]),
          fontWeight: chat.unreadCount > 0 || isRecent 
              ? FontWeight.bold 
              : FontWeight.normal,
        ),
      ),
    );
  }

  String _formatTime() {
    final now = DateTime.now();
    final difference = now.difference(chat.time);
    
    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${chat.time.hour}:${chat.time.minute.toString().padLeft(2, '0')}';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d';
    
    return '${chat.time.day}/${chat.time.month}';
  }

  Widget _buildStatusWidget() {
    if (isTyping) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.edit,
            size: 14,
            color: Colors.blueAccent,
          ),
        ),
      );
    }
    
    if (chat.unreadCount > 0) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: chat.unreadCount > 9 ? 28 : 24,
        height: 24,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    return const Icon(
      Icons.done_all,
      size: 16,
      color: Colors.grey,
    );
  }

  Widget _buildDismissBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(chat.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
                title: Text(chat.isPinned ? 'Unpin Chat' : 'Pin Chat'),
                onTap: () {
                  Navigator.pop(ctx);
                  onPin();
                  HapticFeedback.lightImpact();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  onViewProfile();
                },
              ),
              if (!chat.isAI)
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Block User'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showBlockDialog(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBlockDialog(BuildContext context) {
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