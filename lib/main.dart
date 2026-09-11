import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const KuanyngneApp());
}

final supabase = Supabase.instance.client;

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
  int savedCount;
  int shares;
  bool isLiked;
  bool isSaved;
  bool isFollowing;
  String currentQuality;

  VideoModel({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.videoUrl,
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
  });

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id']?.toString() ?? '',
      username: map['username'] ?? '@user',
      userAvatar: map['user_avatar'] ?? 'https://via.placeholder.com/150',
      videoUrl: map['video_url'] ?? '',
      caption: map['caption'] ?? '',
      songTitle: map['song_title'] ?? 'Original Sound',
      likes: map['likes'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      savedCount: map['saved_count'] ?? 0,
      shares: map['shares'] ?? 0,
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
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _pageController = PageController();
  int _selectedFeedTab = 2;
  int _currentPage = 0;

  final Stream<List<Map<String, dynamic>>> _videosStream =
      supabase.from('videos').stream(primaryKey: ['id']);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _videosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF2A5F)),
                );
              }

              final videos = (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty)
                  ? [
                      VideoModel(
                        id: 'v1',
                        username: '@kuanyngne_official',
                        userAvatar: 'https://via.placeholder.com/150',
                        videoUrl:
                            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                        caption:
                            'Welcome to kuanyngne! Professional Video Sharing Feed 🔥 #kuanyngne',
                        songTitle: 'Original Audio - kuanyngne Sound',
                        likes: 12500,
                        commentsCount: 342,
                        savedCount: 2409,
                        shares: 751,
                      )
                    ]
                  : snapshot.data!.map((data) => VideoModel.fromMap(data)).toList();

              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: videos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return VideoTile(
                    video: videos[index],
                    isVisible: index == _currentPage,
                  );
                },
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
                    onPressed: () {},
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
  final bool isVisible;

  const VideoTile({super.key, required this.video, required this.isVisible});

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

    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          if (widget.isVisible) {
            _videoController.play();
            _videoController.setLooping(true);
          }
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
  void didUpdateWidget(VideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible && _isInitialized) {
      if (widget.isVisible) {
        _videoController.play();
        _discController.repeat();
      } else {
        _videoController.pause();
        _discController.stop();
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _discController.dispose();
    super.dispose();
  }

  Future<void> _toggleLikeInSupabase() async {
    setState(() {
      widget.video.isLiked = !widget.video.isLiked;
      if (widget.video.isLiked) {
        widget.video.likes++;
      } else {
        widget.video.likes--;
      }
    });

    try {
      await supabase
          .from('videos')
          .update({'likes': widget.video.likes})
          .eq('id', widget.video.id);
    } catch (_) {}
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
                    _buildShareAppTile(Icons.camera_alt, 'Instagram', const Color(0xE1306C00)),
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
      onTap: () async {
        setState(() {
          widget.video.shares++;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shared to $name!')),
        );
        try {
          await supabase
              .from('videos')
              .update({'shares': widget.video.shares})
              .eq('id', widget.video.id);
        } catch (_) {}
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
                    '${widget.video.commentsCount} Comments',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
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
                        subtitle: const Text('Awesome content! 🔥'),
                        trailing: const Icon(Icons.favorite_border, size: 16),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
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
          onDoubleTap: () {
            _toggleLikeInSupabase();
            setState(() {
              _showDoubleTapHeart = true;
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
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                onTap: _toggleLikeInSupabase,
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
                      '${widget.video.commentsCount}',
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
        child: Text('Trending Videos & Creators'),
      ),
    );
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  bool _isUploading = false;

  Future<void> _uploadVideo() async {
    if (_videoUrlController.text.isEmpty || _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await supabase.from('videos').insert({
        'username': '@kuanyngne_creator',
        'user_avatar': 'https://via.placeholder.com/150',
        'video_url': _videoUrlController.text.trim(),
        'caption': _captionController.text.trim(),
        'song_title': 'Original Sound',
        'likes': 0,
        'comments_count': 0,
        'saved_count': 0,
        'shares': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video Published Successfully!')),
        );
        _captionController.clear();
        _videoUrlController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        backgroundColor: const Color(0xFF0D0D13),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 160,
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
                  Text('Upload Stream Target', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _videoUrlController,
              decoration: InputDecoration(
                labelText: 'Direct Video URL',
                filled: true,
                fillColor: const Color(0xFF161622),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                labelText: 'Caption & Hashtags',
                filled: true,
                fillColor: const Color(0xFF161622),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2A5F),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isUploading ? null : _uploadVideo,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Post Video', style: TextStyle(fontSize: 16, color: Colors.white)),
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
        child: Text('No new activity'),
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
        title: const Text('User Profile'),
        backgroundColor: const Color(0xFF0D0D13),
      ),
      body: const Center(
        child: Text('Profile details & posted videos'),
      ),
    );
  }
}
