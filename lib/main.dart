import 'dart:io';
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
      // በፍጥነትና አስተማማኝ በሆነ መልኩ የሚጫን የቪዲዮ ሊንክ
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4',
      caption: 'Welcome to kuanyngne! Professional 5-Minute HD Video Sharing Feed 🔥 #kuanyngne #viral',
      songTitle: 'Original Audio - kuanyngne Sound',
      likes: 12500,
      commentsCount: 3,
      savedCount: 2409,
      shares: 751,
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
      ProfileScreen(userVideos: _globalVideos, onDeleteVideo: _deleteVideo),
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

// VIDEO FEED SCREEN
class VideoFeedScreen extends StatefulWidget {
  final List<VideoModel> videos;
  const VideoFeedScreen({super.key, required this.videos});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _pageController = PageController();
  int _selectedFeedTab = 3;

  Widget _buildTopTab(String title, int tabIndex) {
    final bool isSelected = _selectedFeedTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedFeedTab = tabIndex),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
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
                      _buildTopTab('Friends', 1),
                      const SizedBox(width: 14),
                      _buildTopTab('For You', 2),
                      const SizedBox(width: 14),
                      _buildTopTab('Following', 3),
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

// VIDEO TILE WIDGET
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
  bool _showDoubleTapHeart = false;
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
        _videoController.setLooping(true);
        _videoController.play();
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
          padding: const EdgeInsets.all(20),
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share to', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildShareItem(Icons.send, 'Direct', Colors.blue),
                    _buildShareItem(Icons.link, 'Copy Link', Colors.grey),
                    _buildShareItem(Icons.download, 'Save Video', Colors.green),
                    _buildShareItem(Icons.qr_code, 'QR Code', Colors.purple),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareItem(IconData icon, String name, Color color) {
    return Container(
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
    );
  }

  // ኮሜንቱን ተጭነው ሲይዙ (Long Press) Delete የሚያደርግበት ክፍል
  void _showCommentsModal(BuildContext context) {
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
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: 450,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('${widget.video.comments.length} Comments',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                              controller: commentController,
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
        if (_showDoubleTapHeart)
          const Center(
            child: Icon(Icons.favorite, size: 100, color: Color(0xFFFF2A5F)),
          ),
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
        Positioned(
          bottom: 20,
          right: 12,
          child: Column(
            children: [
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
                onTap: () => _showCommentsModal(context),
                child: Column(
                  children: [
                    const Icon(Icons.chat_bubble_rounded, size: 36, color: Colors.white),
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
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.music_note, size: 14, color: Colors.white),
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

// UPLOAD SCREEN (በላከኸው ዲዛይን መሠረት የተሰራ)
class UploadScreen extends StatefulWidget {
  final Function(VideoModel) onVideoUploaded;
  const UploadScreen({super.key, required this.onVideoUploaded});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  XFile? _selectedVideo;

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = video;
      });
    }
  }

  void _upload() {
    if (_selectedVideo != null) {
      final newVid = VideoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: '@kuanyngne_official',
        userAvatar: 'https://via.placeholder.com/150',
        videoUrl: _selectedVideo!.path,
        isLocalFile: true,
        caption: _captionController.text.isEmpty ? 'Uploaded Video' : _captionController.text,
        songTitle: 'Original Audio - Uploaded',
        likes: 0,
        commentsCount: 0,
        shares: 0,
      );
      widget.onVideoUploaded(newVid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video Uploaded Successfully!')),
      );
      setState(() {
        _selectedVideo = null;
        _captionController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video file first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D13),
        elevation: 0,
        title: const Text(
          'Upload Video (Up to 5 Min)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Upload Box Area
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF161622),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF2A5F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_upload, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedVideo == null
                          ? 'Select Video File (Max 5 Minutes)'
                          : 'Selected: ${_selectedVideo!.name}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Caption Box Area
            TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Caption & Hashtags',
                labelStyle: const TextStyle(color: Color(0xFFFF2A5F)),
                filled: true,
                fillColor: const Color(0xFF161622),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF2A5F)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF2A5F), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Publish Video Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2A5F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _upload,
                child: const Text(
                  'Publish Video',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PROFILE SCREEN
class ProfileScreen extends StatefulWidget {
  final List<VideoModel> userVideos;
  final Function(String) onDeleteVideo;

  const ProfileScreen({super.key, required this.userVideos, required this.onDeleteVideo});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImagePath;
  String _username = '@kuanyngne_official';
  String _bio = 'Creating 5-minute HD video experience';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfileImage(StateSetter setModalState) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
      setModalState(() {
        _profileImagePath = image.path;
      });
    }
  }

  void _showEditProfileModal(BuildContext context) {
    final TextEditingController usernameController = TextEditingController(text: _username);
    final TextEditingController bioController = TextEditingController(text: _bio);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161622),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: _profileImagePath != null
                              ? FileImage(File(_profileImagePath!))
                              : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _pickProfileImage(setModalState),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF2A5F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2A5F))),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: bioController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2A5F))),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A5F)),
                  onPressed: () {
                    setState(() {
                      _username = usernameController.text;
                      _bio = bioController.text;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D13),
      appBar: AppBar(
        title: Text(_username, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D0D13),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _showEditProfileModal(context),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFFF2A5F),
              backgroundImage: _profileImagePath != null
                  ? FileImage(File(_profileImagePath!))
                  : null,
              child: _profileImagePath == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(_username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(_bio, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2A5F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showEditProfileModal(context),
            child: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: widget.userVideos.length,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.white10,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: () {
                        widget.onDeleteVideo(widget.userVideos[index].id);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// SETTINGS AND PRIVACY SCREEN
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings and Privacy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader('ACCOUNT'),
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Account Information',
            onTap: () {
              _showInfoDialog(context, 'Account Information', 'Username: @kuanyngne_official\nEmail: user@example.com');
            },
          ),
          _buildListTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            onTap: () {
              _showInfoDialog(context, 'Privacy Settings', 'Private Account: Off\nDirect Messages: Everyone');
            },
          ),
          _buildListTile(
            icon: Icons.shield_outlined,
            title: 'Security',
            onTap: () {
              _showInfoDialog(context, 'Security', '2-Factor Authentication: Disabled\nPassword: *********');
            },
          ),
          const Divider(color: Colors.white12, height: 32),
          _buildSectionHeader('PREFERENCES & CACHE'),
          _buildListTile(
            icon: Icons.cleaning_services_outlined,
            title: 'Free up space / Clear Cache',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully! (124 MB freed)'),
                  backgroundColor: Color(0xFFFF2A5F),
                ),
              );
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.brightness_4_outlined, color: Colors.white),
            title: const Text('Dark Mode', style: TextStyle(color: Colors.white, fontSize: 16)),
            value: _isDarkMode,
            activeColor: const Color(0xFFFF2A5F),
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
              });
            },
          ),
          const Divider(color: Colors.white12, height: 32),
          _buildSectionHeader('DANGER ZONE', color: Colors.redAccent),
          _buildListTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            titleColor: Colors.redAccent,
            iconColor: Colors.redAccent,
            onTap: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color titleColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: titleColor, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161622),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF2A5F))),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161622),
        title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion process initiated.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// OTHER EXTRA SCREENS
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore / Friends'),
        backgroundColor: const Color(0xFF0D0D13),
      ),
      body: const Center(
        child: Text('Explore & Trending Content Screen', style: TextStyle(color: Colors.white54)),
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
        itemCount: 10,
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

class VideoSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text('Search Results for "$query"'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
