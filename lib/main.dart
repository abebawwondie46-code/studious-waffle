import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const KuanyngneApp());
}

class KuanyngneApp extends StatelessWidget {
  const KuanyngneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kuanyngne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121216),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF18181C),
          selectedItemColor: Color(0xFFFE2C55),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const VideoFeedScreen(),
    const Center(child: Text('Explore Screen', style: TextStyle(color: Colors.white, fontSize: 18))),
    const Center(child: Text('Upload Screen', style: TextStyle(color: Colors.white, fontSize: 18))),
    const Center(child: Text('Activity Screen', style: TextStyle(color: Colors.white, fontSize: 18))),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFE2C55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            label: 'Upload',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Activity'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  late VideoPlayerController _controller;
  bool _isLiked = false;
  int _likeCount = 12500;

  final String sampleVideoUrl =
      'https://assets.mixkit.co/videos/preview/mixkit-tree-branches-in-the-breeze-1187-large.mp4';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(sampleVideoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Player Core
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.movie_creation_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Video Playing...', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    ),
            ),
          ),

          // Right Side Interactive Buttons
          Positioned(
            right: 12,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLiked = !_isLiked;
                      _isLiked ? _likeCount++ : _likeCount--;
                    });
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: _isLiked ? const Color(0xFFFE2C55) : Colors.white,
                        size: 38,
                      ),
                      const SizedBox(height: 4),
                      Text('$_likeCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: const [
                    Icon(Icons.message, color: Colors.white, size: 34),
                    SizedBox(height: 4),
                    Text('343', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  children: const [
                    Icon(Icons.share, color: Colors.white, size: 34),
                    SizedBox(height: 4),
                    Text('93', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Left Creator Info & Music Bar
          Positioned(
            left: 12,
            bottom: 20,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '@kuanyngne_official',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Welcome to kuanyngne! Professional 5-Minute HD Video Sharing Feed 🔥 #kuanyngne',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Icon(Icons.music_note, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Original Audio - kuanyngne Sound',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFE2C55), Color(0xFF25F4EE)],
                ),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF121216),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '@kuanyngne_creator',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              '5-Minute High Quality Video Creator',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
