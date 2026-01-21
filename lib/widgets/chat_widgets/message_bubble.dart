import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chitchat/models/chat_models.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final Chat chat;
  final bool showAvatar;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onReply;
  final VoidCallback? onReact;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.chat,
    this.showAvatar = false,
    this.isFirst = false,
    this.isLast = false,
    this.onReply,
    this.onReact,
    this.onDelete,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

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
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    _showMessageOptions();
  }

  void _onDoubleTap() {
    if (!widget.message.isMe) {
      HapticFeedback.lightImpact();
      widget.onReact?.call();
    }
  }

  void _showMessageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MessageOptionsSheet(
        messageType: widget.message.type,
        isMyMessage: widget.message.isMe,
        onReply: widget.onReply,
        onReact: widget.onReact,
        onDelete: widget.onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVoiceMessage = widget.message.type == MessageType.voice;
    final isMediaMessage = widget.message.type == MessageType.photo || 
                          widget.message.type == MessageType.video;
    final isTextMessage = widget.message.type == MessageType.text;

    return GestureDetector(
      onLongPress: _onLongPress,
      onDoubleTap: _onDoubleTap,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            margin: EdgeInsets.only(
              top: widget.isFirst ? 8 : 2,
              bottom: widget.isLast ? 8 : 2,
              left: widget.message.isMe ? 60 : 4,
              right: widget.message.isMe ? 4 : 60,
            ),
            child: Row(
              mainAxisAlignment: widget.message.isMe 
                  ? MainAxisAlignment.end 
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar for received messages
                if (widget.showAvatar && !widget.message.isMe)
                  _buildSenderAvatar(),
                
                if (!widget.message.isMe && !widget.showAvatar)
                  const SizedBox(width: 38),
                
                // Message bubble
                Flexible(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: widget.message.isMe 
                          ? _getBubbleColor()
                          : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(widget.message.isMe ? 20 : 6),
                        bottomRight: Radius.circular(widget.message.isMe ? 6 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_isHovered ? 0.1 : 0.05),
                          blurRadius: _isHovered ? 8 : 4,
                          spreadRadius: _isHovered ? 1 : 0,
                          offset: Offset(0, _isHovered ? 2 : 1),
                        ),
                      ],
                      border: Border.all(
                        color: widget.message.isMe
                            ? Colors.blueAccent.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Message content based on type
                        if (isVoiceMessage)
                          _buildVoiceMessageContent()
                        else if (isMediaMessage)
                          _buildMediaMessageContent()
                        else
                          _buildTextMessageContent(),
                        
                        const SizedBox(height: 6),
                        
                        // Time and status row
                        _buildMessageFooter(),
                      ],
                    ),
                  ),
                ),
                
                // Reaction indicator (if any)
                if (widget.message.reactions?.isNotEmpty ?? false)
                  _buildReactionIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSenderAvatar() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(widget.message.senderAvatar),
        backgroundColor: Colors.grey[300],
        child: widget.message.senderAvatar.isEmpty
            ? Text(
                widget.message.senderName.isNotEmpty 
                    ? widget.message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildTextMessageContent() {
    return SelectableText(
      widget.message.text,
      style: TextStyle(
        color: widget.message.isMe ? Colors.white : Colors.black87,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildVoiceMessageContent() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Play button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.message.isMe 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.blueAccent.withOpacity(0.2),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 16,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Waveform visualization
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(20, (index) {
                    final height = (10 + (index % 5) * 3).toDouble();
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 200 + (index * 50)),
                      width: 2,
                      height: height,
                      decoration: BoxDecoration(
                        color: widget.message.isMe 
                            ? Colors.white.withOpacity(0.8)
                            : Colors.blueAccent.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 4),
                
                // Duration
                Text(
                  '0:05',
                  style: TextStyle(
                    color: widget.message.isMe 
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaMessageContent() {
    final isPhoto = widget.message.type == MessageType.photo;
    final icon = isPhoto ? Icons.photo : Icons.videocam;
    final label = isPhoto ? 'Photo' : 'Video';
    
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.message.isMe 
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: widget.message.isMe ? Colors.white : Colors.blueAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: widget.message.isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Thumbnail preview
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.message.isMe 
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              border: Border.all(
                color: widget.message.isMe 
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Icon(
                isPhoto ? Icons.photo_size_select_actual : Icons.play_circle_filled,
                color: widget.message.isMe ? Colors.white : Colors.grey,
                size: 40,
              ),
            ),
          ),
          
          if (!isPhoto) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.play_circle_filled,
                  color: widget.message.isMe ? Colors.white : Colors.blueAccent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Play video',
                  style: TextStyle(
                    color: widget.message.isMe ? Colors.white : Colors.blueAccent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time
        Text(
          _formatMessageTime(widget.message.time),
          style: TextStyle(
            color: widget.message.isMe 
                ? Colors.white.withOpacity(0.8)
                : Colors.grey[600],
            fontSize: 11,
          ),
        ),
        
        // Status indicator for sent messages
        if (widget.message.isMe && widget.message.status != null) ...[
          const SizedBox(width: 6),
          _buildMessageStatusIndicator(widget.message.status!),
        ],
      ],
    );
  }

  Widget _buildMessageStatusIndicator(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withOpacity(0.8),
          ),
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.done,
          size: 12,
          color: Colors.white70,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.white70,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.greenAccent,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildReactionIndicator() {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('❤️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 2),
          const Text(
            '1',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBubbleColor() {
    if (widget.chat.isAI) {
      return Colors.purpleAccent;
    }
    
    final hour = DateTime.now().hour;
    if (hour < 6) return Colors.deepPurple; // Night
    if (hour < 12) return Colors.blueAccent; // Morning
    if (hour < 18) return Colors.lightBlue; // Afternoon
    return Colors.blue[800]!; // Evening
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(time).inDays == 1) {
      return 'Yesterday ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(time).inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[time.weekday - 1]} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== MESSAGE OPTIONS SHEET ====================
class MessageOptionsSheet extends StatelessWidget {
  final MessageType messageType;
  final bool isMyMessage;
  final VoidCallback? onReply;
  final VoidCallback? onReact;
  final VoidCallback? onDelete;

  const MessageOptionsSheet({
    super.key,
    required this.messageType,
    required this.isMyMessage,
    this.onReply,
    this.onReact,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick reactions
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReactionButton('❤️'),
                _buildReactionButton('😂'),
                _buildReactionButton('😮'),
                _buildReactionButton('😢'),
                _buildReactionButton('😡'),
                _buildReactionButton('👍'),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Action buttons
          ListTile(
            leading: const Icon(Icons.reply, color: Colors.blueAccent),
            title: const Text('Reply'),
            onTap: () {
              Navigator.pop(context);
              onReply?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward, color: Colors.blueAccent),
            title: const Text('Forward'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.copy, color: Colors.blueAccent),
            title: const Text('Copy'),
            onTap: () => Navigator.pop(context),
          ),
          
          if (messageType == MessageType.voice)
            ListTile(
              leading: const Icon(Icons.save_alt, color: Colors.blueAccent),
              title: const Text('Save'),
              onTap: () => Navigator.pop(context),
            ),
          
          if (isMyMessage)
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueAccent),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context),
            ),
          
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(String emoji) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        onReact?.call();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.1),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}