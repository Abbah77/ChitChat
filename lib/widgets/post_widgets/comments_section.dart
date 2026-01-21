import 'package:flutter/material.dart';
import 'package:chitchat/models/comment.dart';
import 'package:chitchat/widgets/post_widgets/comment_widget.dart';
import 'package:chitchat/models/user.dart';

class CommentsSection extends StatefulWidget {
  final String postId;
  final int initialCommentCount;
  
  const CommentsSection({
    super.key,
    required this.postId,
    required this.initialCommentCount,
  });
  
  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final List<Comment> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _hasMoreComments = true;
  int _currentPage = 1;
  final int _commentsPerPage = 10;
  bool _isPostingComment = false;
  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    
    setState(() => _isLoading = true);
    
    if (refresh) {
      _currentPage = 1;
      _comments.clear();
      _hasMoreComments = true;
    }
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newComments = List.generate(
        _commentsPerPage,
        (index) => Comment(
          id: 'comment_${_comments.length + index}',
          postId: widget.postId,
          author: User(
            id: 'user_${index + 1}',
            name: ['Alex', 'Jamie', 'Taylor', 'Jordan'][index % 4],
            email: '',
            username: ['alex', 'jamie', 'taylor', 'jordan'][index % 4],
            profileImage: 'https://i.pravatar.cc/150?img=${index + 20}',
            coverImage: '',
            bio: '',
            postsCount: 10,
            followersCount: 100,
            followingCount: 50,
            isVerified: index % 5 == 0,
            isOnline: index % 2 == 0,
            lastSeen: DateTime.now(),
          ),
          content: 'This is comment number ${_comments.length + index + 1}. Great post!',
          timestamp: DateTime.now().subtract(Duration(minutes: index * 5)),
          likeCount: index * 2,
          isLiked: index % 3 == 0,
          replies: index % 4 == 0
              ? List.generate(
                  2,
                  (replyIndex) => Comment(
                    id: 'reply_${index}_$replyIndex',
                    postId: widget.postId,
                    author: User(
                      id: 'user_${replyIndex + 5}',
                      name: ['Casey', 'Riley'][replyIndex],
                      email: '',
                      username: ['casey', 'riley'][replyIndex],
                      profileImage: 'https://i.pravatar.cc/150?img=${replyIndex + 30}',
                      coverImage: '',
                      bio: '',
                      postsCount: 5,
                      followersCount: 50,
                      followingCount: 25,
                      isVerified: false,
                      isOnline: true,
                      lastSeen: DateTime.now(),
                    ),
                    content: 'Reply to comment ${index + 1}',
                    timestamp: DateTime.now().subtract(Duration(minutes: index * 5 + replyIndex)),
                    likeCount: replyIndex,
                    isLiked: false,
                    replies: [],
                    parentCommentId: 'comment_${_comments.length + index}',
                  ),
                )
              : [],
        ),
      );
      
      if (newComments.length < _commentsPerPage) {
        _hasMoreComments = false;
      }
      
      setState(() {
        _comments.addAll(newComments);
        _currentPage++;
      });
      
    } catch (e) {
      debugPrint('Load comments error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load comments'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    setState(() => _isPostingComment = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final newComment = Comment(
        id: 'new_comment_${DateTime.now().millisecondsSinceEpoch}',
        postId: widget.postId,
        author: User(
          id: 'current_user',
          name: 'You',
          email: '',
          username: 'you',
          profileImage: 'https://i.pravatar.cc/150?img=1',
          coverImage: '',
          bio: '',
          postsCount: 0,
          followersCount: 0,
          followingCount: 0,
          isVerified: false,
          isOnline: true,
          lastSeen: DateTime.now(),
        ),
        content: content,
        timestamp: DateTime.now(),
        likeCount: 0,
        isLiked: false,
        replies: [],
        parentCommentId: _replyingToCommentId,
      );
      
      setState(() {
        if (_replyingToCommentId != null) {
          final parentIndex = _comments.indexWhere((c) => c.id == _replyingToCommentId);
          if (parentIndex != -1) {
            _comments[parentIndex].replies.add(newComment);
          }
        } else {
          _comments.insert(0, newComment);
        }
        
        _commentController.clear();
        _replyingToCommentId = null;
        _replyingToUsername = null;
      });
      
    } catch (e) {
      debugPrint('Post comment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isPostingComment = false);
    }
  }

  Future<void> _likeComment(String commentId) async {
    try {
      Comment? targetComment;
      int? commentIndex;
      
      for (var i = 0; i < _comments.length; i++) {
        if (_comments[i].id == commentId) {
          targetComment = _comments[i];
          commentIndex = i;
          break;
        }
        
        for (var j = 0; j < _comments[i].replies.length; j++) {
          if (_comments[i].replies[j].id == commentId) {
            targetComment = _comments[i].replies[j];
            break;
          }
        }
      }
      
      if (targetComment == null) return;
      
      setState(() {
        if (targetComment!.isLiked) {
          targetComment = targetComment!.copyWith(
            isLiked: false,
            likeCount: targetComment!.likeCount - 1,
          );
        } else {
          targetComment = targetComment!.copyWith(
            isLiked: true,
            likeCount: targetComment!.likeCount + 1,
          );
        }
        
        if (commentIndex != null) {
          _comments[commentIndex] = targetComment!;
        }
      });
      
    } catch (e) {
      debugPrint('Like comment error: $e');
    }
  }

  void _setReplyTarget(String? commentId, String? username) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
    });
    
    _commentController.text = username != null ? '@$username ' : '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
      FocusScope.of(context).requestFocus(_commentController as FocusNode?);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments (${_comments.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_replyingToUsername != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              'Replying to @$_replyingToUsername',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _setReplyTarget(null, null),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _commentController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: _isPostingComment
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send, color: Colors.blueAccent),
                                onPressed: _postComment,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          if (_comments.isEmpty && !_isLoading)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.comment, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No comments yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Be the first to comment!',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length + (_hasMoreComments ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _comments.length) {
                  return _buildLoadMoreButton();
                }
                
                final comment = _comments[index];
                return CommentWidget(
                  comment: comment,
                  onLike: () => _likeComment(comment.id),
                  onReply: () => _setReplyTarget(comment.id, comment.author.username),
                  onViewReplies: () {},
                );
              },
            ),
          
          if (_isLoading && _comments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: () => _loadComments(),
                child: const Text('Load more comments'),
              ),
      ),
    );
  }
}