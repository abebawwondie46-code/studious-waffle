import 'package:flutter/material.dart';

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
        scaffoldBackgroundColor: const Color(0xFF0D0D13),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2A5F),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF161622),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class VideoModel {
  final String id;
  final String username;
  final String userAvatar;
  final String videoUrl;
  final String caption;
  final String songTitle;
  int likes;
  int commentsCount;
  int shares;
  bool isLiked;
  bool isFollowing;

  VideoModel({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.videoUrl,
    required this.caption,
    required this.songTitle,
    required this.likes,
    required this.commentsCount,
    required this.shares,
    this.isLiked = false,
    this.isFollowing = false,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const VideoFeedScreen(),
    const ExploreScreen(),
    const UploadScreen(),
    const ActivityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
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
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box, size: 32, color: Color(0xFFFF2A5F)),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
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
  final PageController _pageController = PageController();
  int _selectedFeedTab = 1; // 0: Friends, 1: For You, 2: Following

  final List<VideoModel> _videos = [
    VideoModel(
      id: 'v1',
      username: '@kuanyngne_official',
      userAvatar: 'https://via.placeholder.com/150',
      videoUrl: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
      caption: 'Welcome to kuanyngne! Professional 5-Minute HD Video Sharing Feed 🔥 #kuanyngne #viral',
      songTitle: 'Original Audio - kuanyngne Sound',
      likes: 12500,
      commentsCount: 342,
      shares: 89,
    ),
    VideoModel(
      id: 'v2',
      username: '@tech_creator',
      userAvatar: 'https://via.placeholder.com/150',
      videoUrl: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
      caption: 'Testing 5-minute video playback quality on Flutter! 🚀 #tech #flutter',
      songTitle: 'Trending Beats 2026',
      likes: 8400,
      commentsCount: 120,
      shares: 45,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              return VideoTile(video: _videos[index]);
            },
          ),
          // Top Bar for Search, Friends, For You & Add Friend
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white, size: 28),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add Friends feature clicked!')),
                      );
                    },
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedFeedTab = 0),
                        child: Text(
                          'Friends',
                          style: TextStyle(
                            color: _selectedFeedTab == 0 ? Colors.white : Colors.white54,
                            fontWeight: _selectedFeedTab == 0 ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFeedTab = 1),
                        child: Text(
                          'For You',
                          style: TextStyle(
                            color: _selectedFeedTab == 1 ? Colors.white : Colors.white54,
                            fontWeight: _selectedFeedTab == 1 ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFeedTab = 2),
                        child: Text(
                          'Following',
                          style: TextStyle(
                            color: _selectedFeedTab == 2 ? Colors.white : Colors.white54,
                            fontWeight: _selectedFeedTab == 2 ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 28),
                    onPressed: () {
                      showSearch(context: context, delegate: VideoSearchDelegate());
                    },
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

class VideoTile extends StatefulWidget {
  final VideoModel video;

  const VideoTile({super.key, required this.video});

  @override
  State<VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> {
  bool _isPlaying = true;
  double _playbackPosition = 0.3;

  void _showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: 450,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.video.commentsCount} Comments',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFF2A5F),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text('User_${index + 1}'),
                        subtitle: const Text('Awesome 5-minute content on kuanyngne! 🔥'),
                        trailing: const Icon(Icons.favorite_border, size: 16),
                      );
                    },
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    filled: true,
                    fillColor: Colors.black26,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFFF2A5F)),
                      onPressed: () {
                        setState(() {
                          widget.video.commentsCount++;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isPlaying = !_isPlaying;
            });
          },
          child: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPlaying ? Icons.movie_creation : Icons.play_circle_fill,
                    size: 80,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isPlaying ? 'Video Playing...' : 'Paused',
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  activeTrackColor: const Color(0xFFFF2A5F),
                  inactiveTrackColor: Colors.white24,
                  thumbColor: const Color(0xFFFF2A5F),
                ),
                child: Slider(
                  value: _playbackPosition,
                  onChanged: (val) {
                    setState(() {
                      _playbackPosition = val;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        Positioned(
          left: 16,
          bottom: 40,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.video.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.video.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.music_note, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.video.songTitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Positioned(
          right: 16,
          bottom: 40,
          child: Column(
            children: [
              // User Avatar with Follow (+) Button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF161622),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  Positioned(
                    bottom: -8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            widget.video.isFollowing = !widget.video.isFollowing;
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF2A5F),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.video.isFollowing ? Icons.check : Icons.add,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                      widget.video.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 38,
                      color: widget.video.isLiked ? const Color(0xFFFF2A5F) : Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.video.likes}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _showCommentsBottomSheet(context),
                child: Column(
                  children: [
                    const Icon(Icons.comment, size: 36, color: Colors.white),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.video.commentsCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.video.shares++;
                  });
                },
                child: Column(
                  children: [
                    const Icon(Icons.share, size: 34, color: Colors.white),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.video.shares}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore kuanyngne'),
        backgroundColor: const Color(0xFF0D0D13),
      ),
      body: const Center(
        child: Text('Trending 5-Minute Videos & Creators'),
      ),
    );
  }
}

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video (Up to 5 Min)'),
        backgroundColor: const Color(0xFF0D0D13),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 50, color: Color(0xFFFF2A5F)),
                  SizedBox(height: 8),
                  Text('Select Video File (Max 5 Minutes)'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Caption & Hashtags',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2A5F),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {},
              child: const Text('Publish Video', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF0D0D13),
      ),
      body: const Center(
        child: Text('All Notifications & Likes'),
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
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF0D0D13),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
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
                  colors: [Color(0xFFFF2A5F), Color(0xFF00E5FF)],
                ),
              ),
              child: const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFF0D0D13),
                child: Icon(Icons.person, size: 45, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              '@kuanyngne_creator',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              '5-Minute High Quality Video Creator',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // User Statistics (Following, Followers, Likes)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ProfileStatColumn(count: '128', label: 'Following'),
                SizedBox(width: 30),
                _ProfileStatColumn(count: '12.4K', label: 'Followers'),
                SizedBox(width: 30),
                _ProfileStatColumn(count: '85.2K', label: 'Likes'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatColumn extends StatelessWidget {
  final String count;
  final String label;

  const _ProfileStatColumn({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

// Search Delegate UI
class VideoSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('Search Results for "$query"'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Search videos, creators, or hashtags...'),
    );
  }
}
