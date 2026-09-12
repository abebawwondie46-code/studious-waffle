import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const KuanyngneApp());
}

class KuanyngneApp extends StatefulWidget {
  const KuanyngneApp({super.key});

  @override
  State<KuanyngneApp> createState() => _KuanyngneAppState();
}

class _KuanyngneAppState extends State<KuanyngneApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kuanyngne',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF2A5F),
          secondary: Color(0xFF00E5FF),
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D13),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2A5F),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF161622),
        ),
      ),
      home: MainNavigationScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

class VideoModel {
  final String id;
  final String username;
  final String userAvatar;
  final String videoUrl;
  final bool isLocalFile;
  final String caption;
  final String songTitle;
  int likes;
  int commentsCount;
  int savedCount;
  int shares;
  bool isLiked;
  bool isSaved;
  bool isFollowing;
  String currentQuality;
  List<String> comments;

  VideoModel({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.videoUrl,
    this.isLocalFile = false,
    required this.caption,
    required this.songTitle,
    required this.likes,
    required this.commentsCount,
    this.savedCount = 1200,
    required this.shares,
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowing = false,
    this.currentQuality = '1080p',
    List<String>? comments,
  }) : comments = comments ?? ['Awesome content! 🔥', 'Keep it up brother!', 'Amazing video 👏'];
}

class MainNavigationScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const MainNavigationScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<VideoModel> _globalVideos = [
    VideoModel(
      id: 'v1',
      username: '@kuanyngne_official',
      userAvatar: 'https://via.placeholder.com/150',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      caption: 'Welcome to kuanyngne! Professional 5-Minute HD Video Sharing Feed 🔥 #kuanyngne #viral',
      songTitle: 'Original Audio - kuanyngne Sound',
      likes: 12500,
      commentsCount: 3,
      savedCount: 2409,
      shares: 751,
    ),
    VideoModel(
      id: 'v2',
      username: '@tech_creator',
      userAvatar: 'https://via.placeholder.com/150',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      caption: 'Testing 5-minute video playback quality on Flutter! 🚀 #tech #flutter',
      songTitle: 'Trending Beats 2026',
      likes: 8400,
      commentsCount: 3,
      savedCount: 890,
      shares: 316,
    ),
  ];

  void _addNewVideo(VideoModel newVideo) {
    setState(() {
      _globalVideos.insert(0, newVideo);
      _currentIndex = 0;
    });
  }

  void _deleteVideo(String videoId) {
    setState(() {
      _globalVideos.removeWhere((video) => video.id == videoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      VideoFeedScreen(videos: _globalVideos),
      const ExploreScreen(),
      UploadScreen(onVideoUploaded: _addNewVideo),
      const ActivityScreen(),
      ProfileScreen(
        userVideos: _globalVideos,
        onDeleteVideo: _deleteVideo,
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

class VideoFeedScreen extends StatefulWidget {
  final List<VideoModel> videos;
  const VideoFeedScreen({super.key, required this.videos});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _pageController = PageController();
  int _selectedFeedTab = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.videos.isEmpty
              ? const Center(
                  child: Text('No videos available', style: TextStyle(color: Colors.white54)),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: widget.videos.length,
                  itemBuilder: (context, index) {
                    return VideoTile(
                      key: ValueKey(widget.videos[index].id),
                      video: widget.videos[index],
                    );
                  },
                ),
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
                      GestureDetector(
                        onTap: () => setState(() => _selectedFeedTab = 1),
                        child: Text(
                          'Friends',
                          style: TextStyle(
                            color: _selectedFeedTab == 1 ? Colors.white : Colors.white54,
                            fontWeight: _selectedFeedTab == 1 ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFeedTab = 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'For You',
                              style: TextStyle(
                                color: _selectedFeedTab == 2 ? Colors.white : Colors.white54,
                                fontWeight: _selectedFeedTab == 2 ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            if (_selectedFeedTab == 2)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                height: 2,
                                width: 24,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFeedTab = 3),
                        child: Text(
                          'Following',
                          style: TextStyle(
                            color: _selectedFeedTab == 3 ? Colors.white : Colors.white54,
                            fontWeight: _selectedFeedTab == 3 ? FontWeight.bold : FontWeight.normal,
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

class VideoSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      )
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
      child: Text('Search results for "$query"'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Search videos, tags, or creators'),
    );
  }
}

class VideoTile extends StatefulWidget {
  final VideoModel video;

  const VideoTile({super.key, required this.video});

  @override
  State<VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _isPlaying = true;
  double _playbackPosition = 0.0;
  bool _showDoubleTapHeart = false;
  double _playbackSpeed = 1.0;
  late AnimationController _discController;

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    if (widget.video.isLocalFile) {
      _videoController = VideoPlayerController.file(File(widget.video.videoUrl));
    } else {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
    }

    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _videoController.play();
        _videoController.setLooping(true);
      }
    });

    _videoController.addListener(() {
      if (_videoController.value.isInitialized && mounted) {
        setState(() {
          _playbackPosition = _videoController.value.position.inMilliseconds /
              _videoController.value.duration.inMilliseconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _discController.dispose();
    super.dispose();
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 280,
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
              const Text(
                'Share video to',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildShareAppTile(Icons.send, 'Telegram', const Color(0xFF0088CC)),
                    _buildShareAppTile(Icons.chat_bubble, 'WhatsApp', const Color(0xFF25D366)),
                    _buildShareAppTile(Icons.facebook, 'Facebook', const Color(0xFF1877F2)),
                    _buildShareAppTile(Icons.camera_alt, 'Instagram', const Color(0xE1306C)),
                    _buildShareAppTile(Icons.link, 'Copy Link', const Color(0xFF4A4A6A)),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video Download Started!')),
                      );
                    },
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text('Save Video', style: TextStyle(color: Colors.white)),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.report, color: Colors.redAccent),
                    label: const Text('Report', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareAppTile(IconData icon, String name, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.video.shares++;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shared to $name!')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  void _showQualitySelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161622),
          title: const Text('Select Video Quality'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['1080p (HD)', '720p', '480p'].map((q) {
              return RadioListTile<String>(
                title: Text(q, style: const TextStyle(color: Colors.white)),
                value: q,
                groupValue: widget.video.currentQuality,
                activeColor: const Color(0xFFFF2A5F),
                onChanged: (val) {
                  setState(() {
                    widget.video.currentQuality = val!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCommentsBottomSheet(BuildContext context) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: 450,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '${widget.video.comments.length} Comments',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.video.comments.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFF2A5F),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text('User_${index + 1}'),
                            subtitle: Text(widget.video.comments[index]),
                            trailing: const Icon(Icons.favorite_border, size: 16),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.black26,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFFFF2A5F)),
                            onPressed: () {
                              final text = commentController.text.trim();
                              if (text.isNotEmpty) {
                                setModalState(() {
                                  widget.video.comments.add(text);
                                  widget.video.commentsCount = widget.video.comments.length;
                                });
                                setState(() {});
                                commentController.clear();
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
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
        GestureDetector(
          onDoubleTap: () {
            setState(() {
              _showDoubleTapHeart = true;
              if (!widget.video.isLiked) {
                widget.video.isLiked = true;
                widget.video.likes++;
              }
            });
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() {
                  _showDoubleTapHeart = false;
                });
              }
            });
          },
          onTap: () {
            setState(() {
              _isPlaying = !_isPlaying;
              if (_isPlaying) {
                _videoController.play();
                _discController.repeat();
              } else {
                _videoController.pause();
                _discController.stop();
              }
            });
          },
          child: Container(
            color: Colors.black,
            child: Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    )
                  : const CircularProgressIndicator(color: Color(0xFFFF2A5F)),
            ),
          ),
        ),

        if (!_isPlaying)
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 80,
              color: Colors.white54,
            ),
          ),

        if (_showDoubleTapHeart)
          const Center(
            child: Icon(
              Icons.favorite,
              size: 110,
              color: Color(0xFFFF2A5F),
            ),
          ),

        Positioned(
          top: 50,
          right: 16,
          child: GestureDetector(
            onTap: _showQualitySelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF00E5FF), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hd_outlined, color: Color(0xFF00E5FF), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.video.currentQuality,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top: 90,
          right: 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_playbackSpeed == 1.0) {
                  _playbackSpeed = 1.5;
                } else if (_playbackSpeed == 1.5) {
                  _playbackSpeed = 2.0;
                } else {
                  _playbackSpeed = 1.0;
                }
                _videoController.setPlaybackSpeed(_playbackSpeed);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${_playbackSpeed}x',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _playbackPosition.clamp(0.0, 1.0),
              onChanged: (val) {
                setState(() {
                  _playbackPosition = val;
                  final duration = _videoController.value.duration;
                  final newPosition = duration * val;
                  _videoController.seekTo(newPosition);
                });
              },
            ),
          ),
        ),

        Positioned(
          left: 16,
          bottom: 35,
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
          right: 12,
          bottom: 30,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const CircleAvatar(
                      radius: 23,
                      backgroundColor: Color(0xFF161622),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
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
                      widget.video.isLiked ? Icons.favorite : Icons.favorite_rounded,
                      size: 38,
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

              GestureDetector(
                onTap: () => _showCommentsBottomSheet(context),
                child: Column(
                  children: [
                    const Icon(Icons.comment_rounded, size: 36, color: Colors.white),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.video.comments.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                      widget.video.isSaved ? Icons.bookmark : Icons.bookmark_rounded,
                      size: 36,
                      color: widget.video.isSaved ? Colors.amber : Colors.white,
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

              GestureDetector(
                onTap: () => _showShareOptions(context),
                child: Column(
                  children: [
                    Transform.scale(
                      scaleX: -1,
                      child: const Icon(Icons.reply_sharp, size: 38, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.video.shares}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              RotationTransition(
                turns: _discController,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161622),
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [Colors.black, Colors.white12, Colors.black],
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black,
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

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: const Color(0xFF0D0D13),
      ),
      body: const Center(
        child: Text('Notifications & Direct Messages'),
      ),
    );
  }
}

class UploadScreen extends StatefulWidget {
  final Function(VideoModel) onVideoUploaded;

  const UploadScreen({super.key, required this.onVideoUploaded});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedVideoFile;
  VideoPlayerController? _previewController;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _selectedVideoFile = File(video.path);
      _previewController = VideoPlayerController.file(_selectedVideoFile!)
        ..initialize().then((_) {
          setState(() {});
          _previewController!.play();
          _previewController!.setLooping(true);
        });
    }
  }

  void _upload() {
    if (_selectedVideoFile == null) return;

    final newVid = VideoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: '@kuanyngne_official',
      userAvatar: 'https://via.placeholder.com/150',
      videoUrl: _selectedVideoFile!.path,
      isLocalFile: true,
      caption: _captionController.text.isEmpty ? 'New kuanyngne Video!' : _captionController.text,
      songTitle: 'Original Sound - @kuanyngne_official',
      likes: 0,
      commentsCount: 0,
      shares: 0,
    );

    widget.onVideoUploaded(newVid);
  }

  @override
  void dispose() {
    _previewController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        backgroundColor: const Color(0xFF0D0D13),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF161622),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24),
                ),
                child: _selectedVideoFile != null && _previewController != null && _previewController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _previewController!.value.aspectRatio,
                        child: VideoPlayer(_previewController!),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_call, size: 60, color: Color(0xFFFF2A5F)),
                          SizedBox(height: 10),
                          Text('Tap to select video from gallery', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                filled: true,
                fillColor: const Color(0xFF161622),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2A5F),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _upload,
              child: const Text('Post Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final List<VideoModel> userVideos;
  final Function(String) onDeleteVideo;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.userVideos,
    required this.onDeleteVideo,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '@kuanyngne_official';
  String _bio = 'Creating 5-minute HD video experiences';
  File? _profileImage;

  void _openEditProfileDialog() {
    final nameController = TextEditingController(text: _username);
    final bioController = TextEditingController(text: _bio);
    File? tempImage = _profileImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage(ImageSource source) async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: source);
              if (picked != null) {
                setModalState(() {
                  tempImage = File(picked.path);
                });
              }
            }

            void showImageSourceSelection() {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF161622),
                builder: (context) {
                  return SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library, color: Colors.white),
                          title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.pop(context);
                            pickImage(ImageSource.gallery);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt, color: Colors.white),
                          title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.pop(context);
                            pickImage(ImageSource.camera);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF161622),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white12,
                          backgroundImage: tempImage != null ? FileImage(tempImage!) : null,
                          child: tempImage == null
                              ? const Icon(Icons.person, size: 50, color: Colors.white54)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: showImageSourceSelection,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF2A5F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFFFF2A5F))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2A5F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    setState(() {
                      _username = nameController.text;
                      _bio = bioController.text;
                      _profileImage = tempImage;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openSettingsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsAndPrivacyScreen(
          isDarkMode: widget.isDarkMode,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  void _confirmDeleteVideo(String videoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161622),
        title: const Text('Delete Video', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this video?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A5F)),
            onPressed: () {
              widget.onDeleteVideo(videoId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_username),
        backgroundColor: const Color(0xFF0D0D13),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsScreen,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFFFF2A5F),
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(_username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(_bio, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF161622)),
            onPressed: _openEditProfileDialog,
            child: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          Expanded(
            child: widget.userVideos.isEmpty
                ? const Center(child: Text('No videos uploaded yet.', style: TextStyle(color: Colors.white54)))
                : GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: widget.userVideos.length,
                    itemBuilder: (context, index) {
                      final item = widget.userVideos[index];
                      return Stack(
                        fit: StackPosition.expand,
                        children: [
                          Container(
                            color: const Color(0xFF161622),
                            child: const Center(
                              child: Icon(Icons.play_arrow, color: Colors.white54, size: 30),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            left: 5,
                            child: Row(
                              children: [
                                const Icon(Icons.play_arrow_outlined, size: 14, color: Colors.white),
                                Text('${item.likes}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: IconButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                              onPressed: () => _confirmDeleteVideo(item.id),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SettingsAndPrivacyScreen extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SettingsAndPrivacyScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings and Privacy'),
        backgroundColor: const Color(0xFF0D0D13),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('ACCOUNT', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white),
            title: const Text('Account Information', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Information Opened')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.white),
            title: const Text('Privacy', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy Settings Opened')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.white),
            title: const Text('Security', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security Settings Opened')));
            },
          ),
          const Divider(color: Colors.white12),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('PREFERENCES & CACHE', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined, color: Colors.white),
            title: const Text('Free up space / Clear Cache', style: TextStyle(color: Colors.white)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared successfully!')));
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined, color: Colors.white),
            title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
            value: isDarkMode,
            activeColor: const Color(0xFFFF2A5F),
            onChanged: (val) {
              onThemeChanged(val);
            },
          ),
          const Divider(color: Colors.white12),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('DANGER ZONE', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.disabled_by_default_outlined, color: Colors.redAccent),
            title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF161622),
                  title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
                  content: const Text('Are you sure you want to delete your account? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
