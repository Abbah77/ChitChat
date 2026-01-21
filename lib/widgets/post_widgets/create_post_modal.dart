import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:chitchat/models/post.dart';
import 'package:chitchat/models/user.dart';

class CreatePostModal extends StatefulWidget {
  final Function(Post)? onPostCreated;
  
  const CreatePostModal({super.key, this.onPostCreated});
  
  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final TextEditingController _postController = TextEditingController();
  final _mediaFiles = <File>[];
  final _mediaUrls = <String>[];
  bool _isPosting = false;
  bool _isUploadingMedia = false;
  PostPrivacy _privacy = PostPrivacy.public;
  String? _location;
  List<String> _taggedUsers = [];
  final _focusNode = FocusNode();
  double _uploadProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _postController.dispose();
    _focusNode.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        _showPermissionDenied();
        return;
      }

      final picker = ImagePicker();
      final pickedFile = isVideo
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source, imageQuality: 85);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        if (!isVideo && file.lengthSync() > 5 * 1024 * 1024) {
          final compressedFile = await _compressImage(file);
          if (compressedFile != null) {
            _mediaFiles.add(compressedFile);
          } else {
            _mediaFiles.add(file);
          }
        } else {
          _mediaFiles.add(file);
        }
        
        await _uploadMedia();
        
        setState(() {});
      }
    } on PlatformException catch (e) {
      debugPrint('Media picker error: $e');
      _showError('Failed to pick media: ${e.message}');
    } catch (e) {
      debugPrint('Media picker error: $e');
      _showError('Failed to pick media');
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.path;
      final lastSeparator = filePath.lastIndexOf(Platform.pathSeparator);
      final newPath = filePath.substring(0, lastSeparator + 1) +
          'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        newPath,
        quality: 60,
        minWidth: 1080,
        minHeight: 1080,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }

  Future<void> _uploadMedia() async {
    if (_mediaFiles.isEmpty || _isUploadingMedia) return;

    setState(() {
      _isUploadingMedia = true;
      _uploadProgress = 0.0;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _uploadProgress += 0.05;
        if (_uploadProgress >= 1.0) {
          timer.cancel();
          _uploadProgress = 1.0;
          _isUploadingMedia = false;
          _mediaUrls.add('https://picsum.photos/600/400?random=${_mediaUrls.length}');
        }
      });
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
      
      _progressTimer?.cancel();
      setState(() {
        _isUploadingMedia = false;
        _uploadProgress = 1.0;
      });

    } catch (e) {
      _progressTimer?.cancel();
      setState(() => _isUploadingMedia = false);
      _showError('Failed to upload media');
    }
  }

  Future<void> _createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty && _mediaUrls.isEmpty) {
      _showError('Please add some content or media');
      return;
    }

    setState(() => _isPosting = true);

    try {
      // Create post via API
      // final response = await APIService.createPost(
      //   content: content,
      //   image: _mediaUrls.isNotEmpty ? _mediaUrls.first : null,
      //   video: _mediaUrls.isNotEmpty && _mediaFiles.any((f) => f.path.endsWith('.mp4'))
      //       ? _mediaUrls.first
      //       : null,
      // );

      // Create post object
      final newPost = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
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
        timestamp: DateTime.now(),
        mediaUrls: _mediaUrls,
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        isLiked: false,
        isSaved: false,
        privacy: _privacy,
      );

      widget.onPostCreated?.call(newPost);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      debugPrint('Create post error: $e');
      _showError('Failed to create post: $e');
    } finally {
      setState(() => _isPosting = false);
    }
  }

  void _showPermissionDenied() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Please grant photo library access to pick media.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPrivacySelector() {
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
            const Text(
              'Select Privacy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...PostPrivacy.values.map((privacy) {
              return ListTile(
                leading: Icon(
                  privacy == PostPrivacy.public
                      ? Icons.public
                      : privacy == PostPrivacy.friends
                          ? Icons.people
                          : Icons.lock,
                  color: _privacy == privacy ? Colors.blueAccent : Colors.grey,
                ),
                title: Text(
                  privacy == PostPrivacy.public
                      ? 'Public'
                      : privacy == PostPrivacy.friends
                          ? 'Friends Only'
                          : 'Only Me',
                  style: TextStyle(
                    color: _privacy == privacy ? Colors.blueAccent : Colors.black,
                    fontWeight: _privacy == privacy ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: _privacy == privacy
                    ? const Icon(Icons.check, color: Colors.blueAccent)
                    : null,
                onTap: () {
                  setState(() => _privacy = privacy);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: GestureDetector(
            onTap: () {},
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Create Post',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _isPosting ? null : _createPost,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isPosting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Post'),
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 24,
                                    backgroundImage: NetworkImage(
                                      'https://i.pravatar.cc/150?img=1',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'You',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _showPrivacySelector,
                                        child: Row(
                                          children: [
                                            Icon(
                                              _privacy == PostPrivacy.public
                                                  ? Icons.public
                                                  : _privacy == PostPrivacy.friends
                                                      ? Icons.people
                                                      : Icons.lock,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _privacy == PostPrivacy.public
                                                  ? 'Public'
                                                  : _privacy == PostPrivacy.friends
                                                      ? 'Friends Only'
                                                      : 'Only Me',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              TextField(
                                controller: _postController,
                                focusNode: _focusNode,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  hintText: "What's on your mind?",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(fontSize: 18),
                                ),
                                style: const TextStyle(fontSize: 18),
                              ),
                              
                              if (_mediaUrls.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Media (${_mediaUrls.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _mediaUrls.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        width: 150,
                                        height: 150,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          image: DecorationImage(
                                            image: NetworkImage(_mediaUrls[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _mediaUrls.removeAt(index);
                                                    if (index < _mediaFiles.length) {
                                                      _mediaFiles.removeAt(index);
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              
                              if (_isUploadingMedia) ...[
                                const SizedBox(height: 20),
                                LinearProgressIndicator(
                                  value: _uploadProgress,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Uploading media... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 30),
                              Wrap(
                                spacing: 12,
                                children: [
                                  _buildAddOption(
                                    icon: Icons.photo_library,
                                    label: 'Photo/Video',
                                    onTap: () => _showMediaPicker(),
                                  ),
                                  _buildAddOption(
                                    icon: Icons.tag,
                                    label: 'Tag People',
                                    onTap: () {},
                                  ),
                                  _buildAddOption(
                                    icon: Icons.location_on,
                                    label: 'Location',
                                    onTap: () {},
                                  ),
                                  _buildAddOption(
                                    icon: Icons.emoji_emotions,
                                    label: 'Feeling/Activity',
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaPicker() {
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
            const Text(
              'Add Media',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMediaOption(
                  icon: Icons.photo_library,
                  label: 'Photo Library',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.gallery, false);
                  },
                ),
                _buildMediaOption(
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.camera, false);
                  },
                ),
                _buildMediaOption(
                  icon: Icons.video_library,
                  label: 'Video Library',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.gallery, true);
                  },
                ),
                _buildMediaOption(
                  icon: Icons.videocam,
                  label: 'Record Video',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.camera, true);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}