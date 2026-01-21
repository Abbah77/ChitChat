import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chitchat/models/post.dart';
import 'package:chitchat/models/user.dart';  
import '../logic/dashboard_cubit.dart'; 
import 'package:chitchat/widgets/post_widgets/comments_section.dart';

class PostCardWidget extends StatefulWidget {
  final Post post;

  const PostCardWidget({
    super.key,
    required this.post,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> 
    with SingleTickerProviderStateMixin {
  bool _showComments = false;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 0;
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _likeOpacityAnimation;
  late AnimationController _saveAnimationController;
  late Animation<double> _saveScaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _isSaved = widget.post.isSaved;
    _likeCount = widget.post.likeCount;
    
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 0.4),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 0.6),
    ]).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _likeOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 0.3),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 0.7),
    ]).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _saveScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 0.5),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 0.5),
    ]).animate(CurvedAnimation(
      parent: _saveAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _saveAnimationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    if (_isLiked) {
      _likeAnimationController.forward(from: 0);
    }

    context.read<DashboardCubit>().likePost(widget.post.id, context);
  }

  void _handleSave() {
    setState(() => _isSaved = !_isSaved);
    
    _saveAnimationController.forward(from: 0);
    context.read<DashboardCubit>().savePost(widget.post.id);
  }

  void _handleComment() {
    setState(() => _showComments = !_showComments);
  }

  void _handleShare() {
    context.read<DashboardCubit>().sharePost(widget.post.id);
    _showShareOptions();
  }

  void _showShareOptions() {
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
              leading: const Icon(Icons.send, color: Colors.blueAccent),
              title: const Text('Send to Friends'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.blueAccent),
              title: const Text('Copy Link'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blueAccent),
              title: const Text('Share Externally'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(widget.post.author.profileImage),
                ),
                title: Text(
                  widget.post.author.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_timeAgoFormatter(widget.post.timestamp)),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => _showPostOptions(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.post.content,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              if (widget.post.mediaUrls.isNotEmpty)
                Container(
                  height: 300,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: widget.post.mediaUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onDoubleTap: _handleLike,
                            child: CachedNetworkImage(
                              imageUrl: widget.post.mediaUrls[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(child: Icon(Icons.error)),
                              ),
                            ),
                          );
                        },
                      ),
                      if (widget.post.mediaUrls.length > 1)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '1/${widget.post.mediaUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '$_likeCount ${_likeCount == 1 ? 'like' : 'likes'}',
                        key: ValueKey(_likeCount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.post.commentCount} comments',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.post.shareCount} shares',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      Icons.thumb_up,
                      _isLiked ? 'Liked' : 'Like',
                      _handleLike,
                      _isLiked ? Colors.blueAccent : Colors.grey,
                    ),
                    _buildActionButton(
                      Icons.comment_outlined,
                      'Comment',
                      _handleComment,
                      _showComments ? Colors.blueAccent : Colors.grey,
                    ),
                    _buildActionButton(
                      Icons.share_outlined,
                      'Share',
                      _handleShare,
                      Colors.grey,
                    ),
                    AnimatedBuilder(
                      animation: _saveAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _saveScaleAnimation.value,
                          child: _buildActionButton(
                            _isSaved ? Icons.bookmark : Icons.bookmark_border,
                            'Save',
                            _handleSave,
                            _isSaved ? Colors.blueAccent : Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_showComments) CommentsSection(
                postId: widget.post.id,
                initialCommentCount: widget.post.commentCount,
              ),
            ],
          ),
          
          if (_likeAnimationController.isAnimating)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _likeAnimationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _likeOpacityAnimation.value,
                      child: Center(
                        child: Transform.scale(
                          scale: _likeScaleAnimation.value,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 80,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.pink,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions() {
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
              leading: const Icon(Icons.flag_outlined, color: Colors.red),
              title: const Text('Report Post'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('Copy Link'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.grey),
              title: const Text('Share to...'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgoFormatter(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
