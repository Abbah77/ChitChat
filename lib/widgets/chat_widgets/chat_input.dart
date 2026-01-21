import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function() onVoiceRecordStart;
  final Function() onVoiceRecordStop;
  final Function(String) onAttachmentSelected;
  final Function() onShowEmojiPicker;
  final bool isRecording;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onVoiceRecordStart,
    required this.onVoiceRecordStop,
    required this.onAttachmentSelected,
    required this.onShowEmojiPicker,
    this.isRecording = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _recordingAnimationController;
  late Animation<double> _recordingScaleAnimation;
  Timer? _typingTimer;
  bool _showSendButton = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    
    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    
    _recordingScaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _recordingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _messageController.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _showSendButton) {
      setState(() {
        _showSendButton = hasText;
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    widget.onSendMessage(text);
    _messageController.clear();
    _showSendButton = false;
  }

  void _toggleVoiceRecording() {
    if (widget.isRecording) {
      widget.onVoiceRecordStop();
      _recordingAnimationController.stop();
    } else {
      widget.onVoiceRecordStart();
      _recordingAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Attachment button
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
            offset: const Offset(0, -200),
            onSelected: widget.onAttachmentSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'photo',
                child: Row(
                  children: [
                    Icon(Icons.photo, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Photo & Video'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'document',
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Document'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'camera',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Camera'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'location',
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Location'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.contact_phone, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Contact'),
                  ],
                ),
              ),
            ],
          ),
          
          // Message input field
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 5000,
                      buildCounter: (context,
                          {required currentLength,
                          required isFocused,
                          maxLength}) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '$currentLength/$maxLength',
                            style: TextStyle(
                              fontSize: 12,
                              color: currentLength > 4500
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                        );
                      },
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  
                  // Emoji button
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.amber),
                    onPressed: widget.onShowEmojiPicker,
                  ),
                ],
              ),
            ),
          ),
          
          // Voice/Send button
          GestureDetector(
            onLongPress: _showSendButton ? null : widget.onVoiceRecordStart,
            onLongPressEnd: _showSendButton ? null : (details) {
              if (widget.isRecording) {
                widget.onVoiceRecordStop();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showSendButton
                    ? _buildSendButton()
                    : _buildVoiceButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.send, color: Colors.white),
          onPressed: _sendMessage,
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    return AnimatedBuilder(
      animation: _recordingAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRecording ? _recordingScaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: Material(
        elevation: widget.isRecording ? 4 : 1,
        shape: const CircleBorder(),
        color: widget.isRecording ? Colors.red : Colors.blueAccent,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.isRecording ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChange);
    _messageController.dispose();
    _focusNode.dispose();
    _recordingAnimationController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }
}