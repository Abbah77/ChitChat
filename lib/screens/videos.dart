import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatelessWidget {
  const VideoPage({super.key});

  final List<Map<String, String>> videoList = const [
    {
      'videoUrl': 'https://example.com/video1.mp4',
      'title': 'Video 1',
      'description': 'Description of Video 1',
      'userImageUrl': 'https://example.com/user1.jpg',
      'userName': 'User One',
    },
    {
      'videoUrl': 'https://example.com/video2.mp4',
      'title': 'Video 2',
      'description': 'Description of Video 2',
      'userImageUrl': 'https://example.com/user2.jpg',
      'userName': 'User Two',
    },
    {
      'videoUrl': 'https://example.com/video3.mp4',
      'title': 'Video 3',
      'description': 'Description of Video 3',
      'userImageUrl': 'https://example.com/user3.jpg',
      'userName': 'User Three',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIDEOS'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: videoList.length,
        itemBuilder: (context, index) {
          final video = videoList[index];
          return VideoCard(
            videoUrl: video['videoUrl']!,
            title: video['title']!,
            description: video['description']!,
            userImageUrl: video['userImageUrl']!,
            userName: video['userName']!,
          );
        },
      ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;
  final String userImageUrl;
  final String userName;

  const VideoCard({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.userImageUrl,
    required this.userName,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VideoHeader(userName: widget.userName, userImageUrl: widget.userImageUrl),
          _VideoPlayerSection(controller: _controller),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(widget.description, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ),
          _VideoActions(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// --- Reusable Widgets ---

class _VideoHeader extends StatelessWidget {
  final String userName;
  final String userImageUrl;

  const _VideoHeader({required this.userName, required this.userImageUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(userImageUrl)),
          const SizedBox(width: 8.0),
          Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _VideoPlayerSection extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoPlayerSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: controller.value.isInitialized ? controller.value.aspectRatio : 16 / 9,
          child: Container(
            color: Colors.black,
            child: controller.value.isInitialized ? VideoPlayer(controller) : const Center(child: CircularProgressIndicator()),
          ),
        ),
        IconButton(
          icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
          onPressed: () {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          },
        ),
      ],
    );
  }
}

class _VideoActions extends StatelessWidget {
  const _VideoActions();

  @override
  Widget build(BuildContext context) {
    return ButtonBar(
      alignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.thumb_up, color: Colors.blue, size: 18), label: const Text('Like')),
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.comment, color: Colors.blue, size: 18), label: const Text('Comment')),
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.share, color: Colors.blue, size: 18), label: const Text('Share')),
      ],
    );
  }
}