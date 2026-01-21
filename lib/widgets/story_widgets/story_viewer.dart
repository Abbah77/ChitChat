import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:chitchat/models/story.dart';
import 'package:chitchat/profile.dart';
import 'package:chitchat/widgets/story_widgets/reaction_animation.dart';

enum StoryPlayState { playing, paused, ended }

class StoryViewer extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final Function(String)? onStoryViewed;

  const StoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.onStoryViewed,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _reactionController;
  int _currentStoryIndex = 0;
  int _currentSegmentIndex = 0;
  bool _isPaused = false;
  bool _showReplyInput = false;
  bool _showReactions = false;
  final int _totalSegments = 3;
  final List<Duration> _segmentTimes = [];
  late List<double> _segmentValues;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  StoryPlayState _playState = StoryPlayState.playing;
  
  // Video controllers for each story
  final Map<int, VideoPlayerController?> _videoControllers = {};
  final Map<int, ChewieController?> _chewieControllers = {};
  final Map<int, bool> _videoLoadingStates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _currentStoryIndex = widget.initialIndex;
    _segmentValues = List.filled(_totalSegments, 0.0);
    _segmentTimes.addAll(List.generate(_totalSegments, (i) => const Duration(seconds: 5)));
    
    _pageController = PageController(initialPage: _currentStoryIndex);
    
    _progressController = AnimationController(
      vsync: this,
      duration: _segmentTimes[0],
    )..addStatusListener(_handleAnimationStatus);
    
    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Preload current story
    _initializeStory(_currentStoryIndex);
    _markStoryAsViewed();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_isPaused) {
      _advanceSegment();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pauseStory();
        break;
      case AppLifecycleState.resumed:
        if (!_isPaused) _resumeStory();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeStory(int index) async {
    final story = widget.stories[index];
    
    // Preload video if needed
    if (story.videoUrl.isNotEmpty && !_videoControllers.containsKey(index)) {
      await _initializeVideo(story.videoUrl, index);
    }
    
    // Only start timer for current story
    if (index == _currentStoryIndex) {
      _startSegmentTimer();
    }
  }

  Future<void> _initializeVideo(String videoUrl, int index) async {
    try {
      if (!mounted) return;
      
      setState(() => _videoLoadingStates[index] = true);
      
      final videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );
      
      await videoController.initialize();
      
      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: false,
        looping: false,
        showControls: false,
        allowFullScreen: false,
        allowMuting: false,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.white,
          handleColor: Colors.white,
          backgroundColor: Colors.white38,
          bufferedColor: Colors.white54,
        ),
      );
      
      if (mounted) {
        setState(() {
          _videoControllers[index] = videoController;
          _chewieControllers[index] = chewieController;
          _videoLoadingStates[index] = false;
        });
        
        // Play only if this is the current story
        if (index == _currentStoryIndex && !_isPaused) {
          videoController.play();
          videoController.addListener(_videoListener);
        }
      }
      
    } catch (e) {
      debugPrint('Video initialization error: $e');
      if (mounted) {
        setState(() => _videoLoadingStates[index] = false);
      }
    }
  }

  void _videoListener() {
    final videoController = _videoControllers[_currentStoryIndex];
    if (videoController == null) return;
    
    if (videoController.value.isPlaying && _playState != StoryPlayState.playing) {
      setState(() => _playState = StoryPlayState.playing);
    } else if (!videoController.value.isPlaying && 
               _playState == StoryPlayState.playing &&
               videoController.value.position >= videoController.value.duration) {
      setState(() => _playState = StoryPlayState.ended);
      _nextStory();
    }
  }

  void _startSegmentTimer() {
    final story = widget.stories[_currentStoryIndex];
    
    _progressController.duration = _segmentTimes[_currentSegmentIndex];
    
    if (story.videoUrl.isNotEmpty) {
      // For videos, let video listener handle progress
      final videoController = _videoControllers[_currentStoryIndex];
      if (videoController != null && !_isPaused) {
        videoController.play();
        videoController.addListener(_videoListener);
      }
    } else {
      // For images, use animation controller
      if (_playState == StoryPlayState.playing && !_isPaused) {
        _progressController.forward(from: 0);
      }
    }
  }

  void _advanceSegment() {
    if (!mounted) return;
    
    setState(() {
      _segmentValues[_currentSegmentIndex] = 1.0;
      _currentSegmentIndex++;
      
      if (_currentSegmentIndex >= _totalSegments) {
        _nextStory();
      } else {
        _startSegmentTimer();
      }
    });
  }

  void _pauseStory() {
    if (!_isPaused) {
      setState(() {
        _isPaused = true;
        _playState = StoryPlayState.paused;
      });
      
      _progressController.stop();
      
      final videoController = _videoControllers[_currentStoryIndex];
      videoController?.pause();
    }
  }

  void _resumeStory() {
    if (_isPaused) {
      setState(() {
        _isPaused = false;
        _playState = StoryPlayState.playing;
      });
      
      final story = widget.stories[_currentStoryIndex];
      if (story.videoUrl.isNotEmpty) {
        final videoController = _videoControllers[_currentStoryIndex];
        videoController?.play();
      } else {
        _startSegmentTimer();
      }
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      _loadStoryAtIndex(_currentStoryIndex + 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      _loadStoryAtIndex(_currentStoryIndex - 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _loadStoryAtIndex(int index) async {
    if (index == _currentStoryIndex) return;
    
    // Clean up current story
    final currentVideoController = _videoControllers[_currentStoryIndex];
    currentVideoController?.removeListener(_videoListener);
    currentVideoController?.pause();
    
    // Reset progress
    _progressController.reset();
    
    setState(() {
      _currentStoryIndex = index;
      _currentSegmentIndex = 0;
      _segmentValues = List.filled(_totalSegments, 0.0);
      _isPaused = false;
      _playState = StoryPlayState.playing;
    });
    
    // Initialize new story if needed
    if (!_videoControllers.containsKey(index) && 
        widget.stories[index].videoUrl.isNotEmpty) {
      await _initializeStory(index);
    }
    
    _markStoryAsViewed();
    _startSegmentTimer();
    
    // Update page controller without triggering onPageChanged
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    });
  }

  void _onPageChanged(int index) {
    // Only load if it's a different story
    if (index != _currentStoryIndex) {
      _loadStoryAtIndex(index);
    }
  }

  void _markStoryAsViewed() {
    final story = widget.stories[_currentStoryIndex];
    if (story.status == StoryStatus.unviewed) {
      widget.onStoryViewed?.call(story.id);
    }
  }

  // ========== ADD THESE TWO MISSING METHODS HERE ==========
  
  void _sendReaction(String reaction) async {
    try {
      final story = widget.stories[_currentStoryIndex];
      _showReactionAnimation(reaction);
      
      // TODO: Implement actual reaction sending to backend
      debugPrint('Sending reaction $reaction to story ${story.id}');
      
    } catch (e) {
      debugPrint('Send reaction error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reaction: $e')),
      );
    }
  }

  void _sendReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty) return;
    
    try {
      final story = widget.stories[_currentStoryIndex];
      
      setState(() => _showReplyInput = false);
      _replyController.clear();
      _replyFocusNode.unfocus();
      
      // TODO: Implement actual reply sending to backend
      debugPrint('Sending reply "$reply" to story ${story.id}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply sent!')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reply: $e')),
      );
    }
  }

  // ========== END OF MISSING METHODS ==========

  @override
  Widget build(BuildContext context) {
    final currentStory = widget.stories[_currentStoryIndex];
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildStoryContent(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildProgressBars(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: 16,
            right: 16,
            child: _buildHeader(currentStory),
          ),
          Positioned.fill(
            child: _buildControlsOverlay(),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildBottomActions(),
          ),
          if (_showReplyInput) _buildReplyInput(),
          if (_videoLoadingStates[_currentStoryIndex] == true) _buildVideoLoader(),
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.stories.length,
      itemBuilder: (context, index) {
        final story = widget.stories[index];
        
        // Show loading or content
        if (story.videoUrl.isNotEmpty) {
          final chewieController = _chewieControllers[index];
          final isLoading = _videoLoadingStates[index] == true;
          
          if (isLoading || chewieController == null) {
            return Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }
          
          return Chewie(controller: chewieController);
        }
        
        return Hero(
          tag: 'story_${story.id}',
          child: CachedNetworkImage(
            imageUrl: story.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.error, color: Colors.white54, size: 48),
              ),
            ),
          ),
        );
      },
    );
  }
 
  Widget _buildProgressBars() {
    return Row(
      children: List.generate(_totalSegments, (index) {
        return Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                if (index < _currentSegmentIndex)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                if (index == _currentSegmentIndex && !_isPaused)
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(1),
                        ),
                        width: MediaQuery.of(context).size.width *
                            _progressController.value /
                            _totalSegments,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(Story story) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Profile(userProfile: {
                  'id': story.userId,
                  'name': story.userName,
                  'profileImage': story.userAvatar,
                }),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(story.userAvatar),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _formatTimeAgo(story.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildControlsOverlay() {
    return GestureDetector(
      onTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final tapX = details.globalPosition.dx;
        
        if (tapX < screenWidth * 0.33) {
          _previousStory();
        } else if (tapX > screenWidth * 0.66) {
          _nextStory();
        } else {
          if (_isPaused) {
            _resumeStory();
          } else {
            _pauseStory();
          }
        }
      },
      onLongPressStart: (_) => _pauseStory(),
      onLongPressEnd: (_) => _resumeStory(),
      onDoubleTap: () {
        _sendReaction('heart');
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 100) {
          Navigator.pop(context);
        }
      },
      child: Container(
        color: Colors.transparent,
        child: _isPaused
            ? Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildReactionButton(Icons.favorite, 'heart'),
            const SizedBox(width: 24),
            _buildReactionButton(Icons.emoji_emotions, 'emoji'),
            const SizedBox(width: 24),
            _buildReactionButton(Icons.message, 'reply'),
          ],
        ),
        const SizedBox(height: 20),
        if (!_showReplyInput)
          GestureDetector(
            onTap: () => setState(() {
              _showReplyInput = true;
              _replyFocusNode.requestFocus();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const Icon(Icons.message, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Send message',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReactionButton(IconData icon, String reaction) {
    return GestureDetector(
      onTap: () => _sendReaction(reaction),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildReplyInput() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    widget.stories[_currentStoryIndex].userAvatar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    focusNode: _replyFocusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Send a reply...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendReply,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLoader() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildReactionsPanel() {
    return Container();
  }

  void _showReactionAnimation(String reaction) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2,
        left: MediaQuery.of(context).size.width / 2,
        child: ReactionAnimationWidget(reaction: reaction),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  String _formatTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

   @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressController.dispose();
    _reactionController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller?.dispose();
    }
    for (final controller in _chewieControllers.values) {
      controller?.dispose();
    }
    
    super.dispose();
  }
}