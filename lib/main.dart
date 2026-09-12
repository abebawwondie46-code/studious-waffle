import 'dart0:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  const MainNavigationScreen({super.key});

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
      _currentIndex = 0; // Upload ከተደረገ በኋላ በቀጥታ ወደ Home Feed ይመልሳል
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      VideoFeedScreen(videos: _globalVideos),
      const ExploreScreen(),
      UploadScreen(onVideoUploaded: _addNewVideo),
      const ActivityScreen(),
      const ProfileScreen(),
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
          PageView.builder(
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

    // ስልክ ላይ ካለ ፋይል ወይም ኢንተርኔት ላይ ላለ ቪዲዮ ማስተካከያ
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
                                setState(() {}); // Main state update
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
  bool _isUploading = false;

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      _previewController?.dispose();
      final file = File(pickedFile.path);

      _previewController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {
            _selectedVideoFile = file;
          });
          _previewController?.play();
          _previewController?.setLooping(true);
        });
    }
  }

  void _uploadVideo() {
    if (_selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎ መጀመሪያ ቪዲዮ ይምረጡ!')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      final newVideo = VideoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: '@kuanyngne_user',
        userAvatar: 'https://via.placeholder.com/150',
        videoUrl: _selectedVideoFile!.path,
        isLocalFile: true,
        caption: _captionController.text.trim().isEmpty
            ? 'My new video on kuanyngne! 🚀'
            : _captionController.text.trim(),
        songTitle: 'Original Audio - User Sound',
        likes: 0,
        commentsCount: 0,
        shares: 0,
      );

      widget.onVideoUploaded(newVideo);

      if (mounted) {
        setState(() {
          _isUploading = false;
          _selectedVideoFile = null;
          _previewController?.dispose();
          _previewController = null;
          _captionController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ቪዲዮው በተሳካ ሁኔታ ዋናው ገፅ ላይ ተለቋል!')),
        );
      }
    });
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
        title: const Text('Upload Video (Up to 5 Min)'),
        backgroundColor: const Color(0xFF0D0D13),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF161622),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: _selectedVideoFile != null &&
                        _previewController != null &&
                        _previewController!.value.isInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: _previewController!.value.aspectRatio,
                          child: VideoPlayer(_previewController!),
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, size: 50, color: Color(0xFFFF2A5F)),
                          SizedBox(height: 8),
                          Text('Select Video File (Max 5 Minutes)'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Caption & Hashtags',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF2A5F)),
                ),
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
                  : const Text('Publish Video', style: TextStyle(fontSize: 16, color: Colors.white)),
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
      body: ListView.builder(
        itemCount: 4,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFF2A5F),
              child: Icon(Icons.notifications, color: Colors.white),
            ),
            title: Text('Notification Title #${index + 1}'),
            subtitle: const Text('Someone liked your video.'),
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '@kuanyngne_official';
  String bio = 'Creating 5-minute HD video experiences 🚀';
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _editProfileDialog() {
    TextEditingController nameController = TextEditingController(text: username);
    TextEditingController bioController = TextEditingController(text: bio);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161622),
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage();
                },
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: const Color(0xFFFF2A5F),
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt, size: 30, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A5F)),
              onPressed: () {
                setState(() {
                  username = nameController.text;
                  bio = bioController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        backgroundColor: const Color(0xFF0D0D13),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickProfileImage,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFFFF2A5F),
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              username,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatColumn('12.5K', 'Following'),
                _buildStatColumn('102K', 'Followers'),
                _buildStatColumn('1.2M', 'Likes'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF161622),
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: _editProfileDialog,
              child: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                return Container(
                  color: const Color(0xFF161622),
                  child: const Center(
                    child: Icon(Icons.play_arrow, color: Colors.white38),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
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
    return Center(child: Text('Search Results for "$query"'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Search videos or creators'));
  }
}
