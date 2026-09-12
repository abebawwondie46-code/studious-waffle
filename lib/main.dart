import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const HomeScreenApp());
}

class HomeScreenApp extends StatelessWidget {
  const HomeScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kuanyngne Feed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D13),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2A5F),
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class VideoModel {
  final String id;
  final String username;
  final String videoUrl;
  final String caption;
  final String songTitle;
  int likes;
  int commentsCount;
  int savedCount;
  int shares;
  bool isLiked;
  bool isSaved;
  bool isFollowing;
  List<String> comments;

  VideoModel({
    required this.id,
    required this.username,
    required this.videoUrl,
    required this.caption,
    required this.songTitle,
    required this.likes,
    required this.commentsCount,
    required this.savedCount,
    required this.shares,
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowing = false,
    List<String>? comments,
  }) : comments = comments ?? ['Awesome content! 🔥', 'Keep it up brother!', 'Amazing video 👏'];
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _bottomIndex = 0;

  final List<VideoModel> _videos = [
    VideoModel(
      id: 'v1',
      username: '@kuanyngne_official',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4',
      caption: 'Welcome to kuanyngne! Professional 5-Minute HD Video Sharing Feed 🔥 #kuanyngne...',
      songTitle: 'Original Audio - kuanyngne Sound',
      likes: 12500,
      commentsCount: 3,
      savedCount: 2409,
      shares: 751,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VideoFeedView(videos: _videos),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (index) {
          setState(() {
            _bottomIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0D0D13),
        selectedItemColor: const Color(0xFFFF2A5F),
        unselectedItemColor: Colors.white54,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box, size: 32, color: Color(0xFFFF2A5F)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class VideoFeedView extends StatefulWidget {
  final List<VideoModel> videos;
  const VideoFeedView({super.key, required this.videos});

  @override
  State<VideoFeedView> createState() => _VideoFeedViewState();
}

class _VideoFeedViewState extends State<VideoFeedView> {
  final PageController _pageController = PageController();
  int _selectedTab = 3; // 'Following' በዲፎልት የተመረጠ

  Widget _buildTabItem(String label, int index) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 24,
            color: isSelected ? Colors.white : Colors.transparent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            itemBuilder: (context, index) {
              return VideoPlayerTile(
                key: ValueKey(widget.videos[index].id),
                video: widget.videos[index],
              );
            },
          ),
          // Top Header Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.live_tv_rounded, color: Colors.white, size: 26),
                    onPressed: () {},
                  ),
                  Row(
                    children: [
                      _buildTabItem('Friends', 1),
                      const SizedBox(width: 14),
                      _buildTabItem('For You', 2),
                      const SizedBox(width: 14),
                      _buildTabItem('Following', 3),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.cyanAccent, width: 1.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'HD ',
                              style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '1080p',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white, size: 26),
                        onPressed: () {},
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
  }
}

class VideoPlayerTile extends StatefulWidget {
  final VideoModel video;
  const VideoPlayerTile({super.key, required this.video});

  @override
  State<VideoPlayerTile> createState() => _VideoPlayerTileState();
}

class _VideoPlayerTileState extends State<VideoPlayerTile> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  double _speed = 1.0;
  late AnimationController _discAnimationController;

  @override
  void initState() {
    super.initState();
    _discAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _discAnimationController.dispose();
    super.dispose();
  }

  void _togglePlaybackSpeed() {
    setState(() {
      if (_speed == 1.0) {
        _speed = 1.5;
      } else if (_speed == 1.5) {
        _speed = 2.0;
      } else if (_speed == 2.0) {
        _speed = 0.5;
      } else {
        _speed = 1.0;
      }
      _controller.setPlaybackSpeed(_speed);
    });
  }

  void _openCommentsModal(BuildContext context) {
    final TextEditingController inputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: 420,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${widget.video.comments.length} Comments',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: widget.video.comments.isEmpty
                          ? const Center(child: Text('No comments yet.', style: TextStyle(color: Colors.white54)))
                          : ListView.builder(
                              itemCount: widget.video.comments.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  onLongPress: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: const Color(0xFF161622),
                                        title: const Text('Delete Comment', style: TextStyle(color: Colors.redAccent)),
                                        content: const Text('Are you sure you want to delete this comment?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                            onPressed: () {
                                              setModalState(() {
                                                widget.video.comments.removeAt(index);
                                                widget.video.commentsCount = widget.video.comments.length;
                                              });
                                              setState(() {});
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                  title: Text('User_${index + 1}',
                                      style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                  subtitle: Text(widget.video.comments[index],
                                      style: const TextStyle(color: Colors.white)),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: inputController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Add comment...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFFFF2A5F)),
                            onPressed: () {
                              final text = inputController.text.trim();
                              if (text.isNotEmpty) {
                                setModalState(() {
                                  widget.video.comments.add(text);
                                  widget.video.commentsCount = widget.video.comments.length;
                                });
                                setState(() {});
                                inputController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video Layer
        GestureDetector(
          onTap: () {
            setState(() {
              _isPlaying = !_isPlaying;
              if (_isPlaying) {
                _controller.play();
                _discAnimationController.repeat();
              } else {
                _controller.pause();
                _discAnimationController.stop();
              }
            });
          },
          child: Container(
            color: Colors.black,
            child: Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, size: 45, color: Colors.white70),
                    ),
            ),
          ),
        ),

        // Play icon indicator when paused
        if (!_isPlaying && _isInitialized)
          const Center(
            child: Icon(Icons.play_arrow, size: 80, color: Colors.white54),
          ),

        // Speed Control (1.0x)
        Positioned(
          top: 85,
          right: 16,
          child: GestureDetector(
            onTap: _togglePlaybackSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_speed}x',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),

        // Bottom Left Details
        Positioned(
          bottom: 20,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.video.username,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                widget.video.caption,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.music_note, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.video.songTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Right Action Sidebar
        Positioned(
          bottom: 20,
          right: 12,
          child: Column(
            children: [
              // User Avatar
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: const Color(0xFFFF2A5F),
                      child: Icon(
                        widget.video.isFollowing ? Icons.check : Icons.add,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Like Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.video.isLiked = !widget.video.isLiked;
                    if (widget.video.isLiked) {
                      widget.video.likes++;
                    } else {
                      widget.video.likes--;
                    }
                  });
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 36,
                      color: widget.video.isLiked ? const Color(0xFFFF2A5F) : Colors.white,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.video.likes}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Comment Button
              GestureDetector(
                onTap: () => _openCommentsModal(context),
                child: Column(
                  children: [
                    const Icon(Icons.chat_bubble_rounded, size: 34, color: Colors.white),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.video.commentsCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bookmark / Save Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.video.isSaved = !widget.video.isSaved;
                    if (widget.video.isSaved) {
                      widget.video.savedCount++;
                    } else {
                      widget.video.savedCount--;
                    }
                  });
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.bookmark,
                      size: 34,
                      color: widget.video.isSaved ? Colors.yellowAccent : Colors.white,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.video.savedCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Share Button
              Column(
                children: [
                  Transform.scale(
                    scaleX: -1,
                    child: const Icon(Icons.reply_sharp, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.video.shares}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Music Disc
              RotationTransition(
                turns: _discAnimationController,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.music_note, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
