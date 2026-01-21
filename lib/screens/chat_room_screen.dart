import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chitchat/models/chat_models.dart';
import 'package:chitchat/logic/conversation_cubit.dart';
import 'package:chitchat/widgets/chat_widgets/chat_header.dart';
import 'package:chitchat/widgets/chat_widgets/message_bubble.dart';
import 'package:chitchat/widgets/chat_widgets/chat_input.dart';
import 'package:chitchat/widgets/chat_widgets/typing_indicator.dart';

class ChatRoom extends StatefulWidget {
  final Chat chat;
  
  const ChatRoom({super.key, required this.chat});

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage(String text) {
    context.read<ConversationCubit>().sendMessage(text: text);
    _scrollToBottom();
  }

  void _handleAttachment(String value) {
    // Handle different attachment types
    switch (value) {
      case 'photo':
        _pickPhoto();
        break;
      case 'document':
        _pickDocument();
        break;
      case 'camera':
        _openCamera();
        break;
      case 'location':
        _shareLocation();
        break;
      case 'contact':
        _shareContact();
        break;
    }
  }

  void _pickPhoto() {
    debugPrint('Picking photo/video');
    // TODO: Implement photo picker
  }

  void _pickDocument() {
    debugPrint('Picking document');
    // TODO: Implement document picker
  }

  void _openCamera() {
    debugPrint('Opening camera');
    // TODO: Implement camera
  }

  void _shareLocation() {
    debugPrint('Sharing location');
    // TODO: Implement location sharing
  }

  void _shareContact() {
    debugPrint('Sharing contact');
    // TODO: Implement contact sharing
  }

  void _showEmojiPicker() {
    debugPrint('Showing emoji picker');
    // TODO: Implement emoji picker
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear conversation?'),
        content: const Text('This will delete all messages in this chat. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ConversationCubit>().clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _startVideoCall() {
    debugPrint('Starting video call with ${widget.chat.name}');
    // TODO: Implement video call
  }

  void _startVoiceCall() {
    debugPrint('Starting voice call with ${widget.chat.name}');
    // TODO: Implement voice call
  }

  void _showContactInfo() {
    debugPrint('Show contact info for ${widget.chat.name}');
    // TODO: Navigate to contact info
  }

  void _showMediaGallery() {
    debugPrint('Opening media gallery');
    // TODO: Implement media gallery
  }

  void _toggleMuteNotifications() {
    debugPrint('Toggling mute notifications');
    // TODO: Implement mute notifications
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${widget.chat.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to chat list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.chat.name} has been blocked'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConversationCubit(chatId: widget.chat.id),
      child: Scaffold(
        appBar: ChatHeader(
          chat: widget.chat,
          onBack: () => Navigator.pop(context),
          onContactInfo: _showContactInfo,
          onVideoCall: _startVideoCall,
          onVoiceCall: _startVoiceCall,
          onClearChat: _clearChat,
          onBlockUser: _blockUser,
          onMuteNotifications: _toggleMuteNotifications,
          onShowMedia: _showMediaGallery,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: BlocBuilder<ConversationCubit, ConversationState>(
            builder: (context, state) {
              return Column(
                children: [
                  // Messages list
                  Expanded(
                    child: _buildMessageList(context, state),
                  ),
                  
                  // Typing indicator
                  if (state is ConversationLoaded && state.isOtherTyping)
                    _buildTypingIndicator(),
                  
                  // Voice recording overlay
                  if (_isRecording)
                    _buildRecordingOverlay(),
                  
                  // Message input
                  ChatInput(
                    onSendMessage: _handleSendMessage,
                    onVoiceRecordStart: () => setState(() => _isRecording = true),
                    onVoiceRecordStop: () => setState(() => _isRecording = false),
                    onAttachmentSelected: _handleAttachment,
                    onShowEmojiPicker: _showEmojiPicker,
                    isRecording: _isRecording,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, ConversationState state) {
    if (state is ConversationLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ConversationError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ConversationCubit>()._loadMessages(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is ConversationLoaded) {
      if (state.messages.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No messages yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Start the conversation!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        reverse: true,
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];
          final isFirst = index == state.messages.length - 1;
          final isLast = index == 0;
          final showAvatar = !message.isMe && !widget.chat.isAI && isFirst;

          return MessageBubble(
            message: message,
            chat: widget.chat,
            showAvatar: showAvatar,
            isFirst: isFirst,
            isLast: isLast,
            onReply: () {
              // TODO: Implement reply
            },
            onReact: () {
              // TODO: Implement reaction
            },
            onDelete: () {
              // TODO: Implement delete
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 14, color: Colors.blueAccent),
          const SizedBox(width: 6),
          Text(
            '${widget.chat.name} is typing',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blueAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const TypingIndicator(),
        ],
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Container(
      height: 60,
      color: Colors.red.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Recording...',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Slide up to cancel, release to send',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.delete_outline, color: Colors.grey),
        ],
      ),
    );
  }
}