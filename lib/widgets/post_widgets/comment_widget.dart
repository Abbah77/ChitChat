import 'package:flutter/material.dart';
import 'package:chitchat/models/comment.dart';
import 'package:chitchat/models/user.dart';  // ADD THIS IMPORT
import 'package:chitchat/profile.dart';  // KEEP THIS IMPORT

class CommentWidget extends StatefulWidget {
  final Comment comment;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onViewReplies;
  
  const CommentWidget({
    super.key,
    required this.comment,
    required this.onLike,
    required this.onReply,
    required this.onViewReplies,
  });
  
  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  bool _showReplies = false;
  bool _isLiked = false;
  int _likeCount = 0;
  
  @override
  void initState() {
    super.initState();
    _isLiked = widget.comment.isLiked;
    _likeCount = widget.comment.likeCount;
  }
  
  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });
    widget.onLike();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Profile(userProfile: {
                        'id': widget.comment.author.id,
                        'name': widget.comment.author.name,
                        'profileImage': widget.comment.author.profileImage,
                      }),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(widget.comment.author.profileImage),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Profile(userProfile: {
                                    'id': widget.comment.author.id,
                                    'name': widget.comment.author.name,
                                    'profileImage': widget.comment.author.profileImage,
                                  }),
                                ),
                              );
                            },
                            child: Text(
                              widget.comment.author.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.comment.content,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        children: [
                          Text(
                            _formatTimeAgo(widget.comment.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: _handleLike,
                            child: Text(
                              '$_likeCount ${_likeCount == 1 ? 'Like' : 'Likes'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isLiked ? Colors.blueAccent : Colors.grey.shade600,
                                fontWeight: _isLiked ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: widget.onReply,
                            child: Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (widget.comment.replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _showReplies = !_showReplies);
                    },
                    child: Row(
                      children: [
                        Container(
                          height: 1,
                          width: 24,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showReplies
                              ? 'Hide ${widget.comment.replies.length} replies'
                              : 'View ${widget.comment.replies.length} replies',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (_showReplies) ...[
                    const SizedBox(height: 12),
                    ...widget.comment.replies.map((reply) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CommentWidget(
                          comment: reply,
                          onLike: () => _likeComment(reply.id),
                          onReply: () => widget.onReply(),
                          onViewReplies: () {},
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'Just now';
  }
  
  void _likeComment(String commentId) {
    // Handle like for reply
  }
}