import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ycvycgdnnmlfaebtxvfl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljdnljZ2Rubm1sZmFlYnR4dmZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyOTk2MjAsImV4cCI6MjA5Njg3NTYyMH0.Os73HGXe4EOijqpBVHk9Bcm6uzZXkgZjWRoroV1m2gE',
  );

  runApp(const Sketchware5MinApp());
}

class Sketchware5MinApp extends StatelessWidget {
  const Sketchware5MinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kuanyngne Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        primaryColor: const Color(0xFFFF9800),
      ),
      home: const MainStudioScreen(),
    );
  }
}

class MainStudioScreen extends StatefulWidget {
  const MainStudioScreen({super.key});

  @override
  State<MainStudioScreen> createState() => _MainStudioScreenState();
}

class _MainStudioScreenState extends State<MainStudioScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const VideoFeedScreen(),
      const UploadStudioScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0D0F14),
        selectedItemColor: const Color(0xFFFF9800),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.style_rounded),
            label: '5-Min Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_rounded, size: 30),
            label: 'Studio Upload',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. FULLSCREEN VIRAL VIDEO FEED SCREEN
// -------------------------------------------------------------
class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _supabase.from('videos').select().order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('An error occurred: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No videos found. Upload a new video!', style: TextStyle(color: Colors.white54)),
            );
          }

          final videos = snapshot.data!;
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return ViralVideoPlayerCard(
                title: video['title'] ?? 'Untitled Studio Content',
                username: video['username'] ?? 'kuanyngne',
                videoUrl: video['video_url'] ?? '',
                duration: video['duration'] ?? 0,
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// VIRAL VIDEO PLAYER CARD
// -------------------------------------------------------------
class ViralVideoPlayerCard extends StatefulWidget {
  final String title;
  final String username;
  final String videoUrl;
  final int duration;

  const ViralVideoPlayerCard({
    super.key,
    required this.title,
    required this.username,
    required this.videoUrl,
    required this.duration,
  });

  @override
  State<ViralVideoPlayerCard> createState() => _ViralVideoPlayerCardState();
}

class _ViralVideoPlayerCardState extends State<ViralVideoPlayerCard> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  int _currentPositionInSeconds = 0;
  int _totalDurationInSeconds = 0;
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _showHeartAnimation = false;
  bool _isMuted = false;

  final List<Map<String, String>> _comments = [];
  late AnimationController _discAnimationController;

  @override
  void initState() {
    super.initState();
    _discAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _totalDurationInSeconds = _controller.value.duration.inSeconds;
          });
          _controller.play();
          _controller.setLooping(true);
          _discAnimationController.repeat();
        }
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized && mounted) {
        final currentSec = _controller.value.position.inSeconds;
        if (currentSec != _currentPositionInSeconds) {
          setState(() {
            _currentPositionInSeconds = currentSec;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _discAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _discAnimationController.stop();
      } else {
        _controller.play();
        _discAnimationController.repeat();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _onDoubleTap() {
    setState(() {
      _isLiked = true;
      _showHeartAnimation = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showHeartAnimation = false);
      }
    });
  }

  void _showCommentSheet() {
    final TextEditingController commentInputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StateBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.60,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Comments (${_comments.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      const Divider(color: Colors.white12, height: 20),
                      Expanded(
                        child: _comments.isEmpty
                            ? const Center(
                                child: Text('No comments yet. Be the first to comment!', style: TextStyle(color: Colors.white54)),
                              )
                            : ListView.builder(
                                itemCount: _comments.length,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemBuilder: (context, index) {
                                  final item = _comments[index];
                                  return GestureDetector(
                                    onLongPress: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          backgroundColor: const Color(0xFF161B26),
                                          title: const Text('Delete Comment', style: TextStyle(color: Colors.white)),
                                          content: const Text('Do you want to delete this comment?', style: TextStyle(color: Colors.white70)),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogContext),
                                              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(dialogContext);
                                                setSheetState(() {
                                                  _comments.removeAt(index);
                                                });
                                                setState(() {});
                                              },
                                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Color(0xFFFF9800),
                                            child: Icon(Icons.person, size: 18, color: Colors.white),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['user'] ?? 'User',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item['text'] ?? '',
                                                  style: const TextStyle(fontSize: 14, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D0F14),
                          border: Border(top: BorderSide(color: Colors.white12, width: 0.8)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentInputController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  filled: true,
                                  fillColor: const Color(0xFF161B26),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                final text = commentInputController.text.trim();
                                if (text.isNotEmpty) {
                                  setSheetState(() {
                                    _comments.insert(0, {
                                      'user': widget.username,
                                      'text': text,
                                    });
                                  });
                                  setState(() {});
                                  commentInputController.clear();
                                }
                              },
                              icon: const Icon(Icons.send_rounded, color: Color(0xFFFF9800)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    final int displayTotalDuration = _totalDurationInSeconds > 0
        ? _totalDurationInSeconds
        : (widget.duration > 0 ? widget.duration : 0);

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // 1. FULLSCREEN VIDEO CONTENT (TOUCHABLE SCREEN)
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePlayPause,
              onDoubleTap: _onDoubleTap,
              child: _isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800))),
            ),
          ),

          // Double Tap Heart Overlay Animation
          if (_showHeartAnimation)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.4),
                duration: const Duration(milliseconds: 300),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: const Icon(Icons.favorite_rounded, size: 100, color: Colors.redAccent),
                  );
                },
              ),
            ),

          // Play/Pause Overlay Icon (CLICKABLE BUTTON)
          if (_isInitialized && !_controller.value.isPlaying)
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Icon(Icons.play_arrow_rounded, size: 65, color: Colors.white),
                ),
              ),
            ),

          // 2. TOP HEADER OVERLAY WITH MUTE & REAL-TIME COUNTER
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'kuanyngne Studio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                    Shadow(blurRadius: 8, color: Colors.black)
                  ]),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleMute,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: Icon(
                          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Text(
                        "${_currentPositionInSeconds}s / ${displayTotalDuration}s",
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. RIGHT SIDE ACTIONS BAR
          Positioned(
            right: 12,
            bottom: 80,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF9800), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFF5C6BC0),
                        child: Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSideActionButton(
                  icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: _isLiked ? "1.2k" : "1.1k",
                  color: _isLiked ? Colors.redAccent : Colors.white,
                  onTap: () => setState(() => _isLiked = !_isLiked),
                ),
                const SizedBox(height: 18),
                _buildSideActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: "${_comments.length}",
                  color: Colors.white,
                  onTap: _showCommentSheet,
                ),
                const SizedBox(height: 18),
                _buildSideActionButton(
                  icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  label: "Save",
                  color: _isBookmarked ? const Color(0xFFFF9800) : Colors.white,
                  onTap: () => setState(() => _isBookmarked = !_isBookmarked),
                ),
                const SizedBox(height: 18),
                _buildSideActionButton(
                  icon: Icons.reply_rounded,
                  label: "Share",
                  color: Colors.white,
                  onTap: () {},
                ),
                const SizedBox(height: 24),

                // Music Disc Animation (Controlled Play/Pause)
                RotationTransition(
                  turns: _discAnimationController,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Colors.grey, Colors.black]),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: const Icon(Icons.music_note_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // 4. BOTTOM LEFT CREATOR DETAILS
          Positioned(
            left: 16,
            right: 80,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "@${widget.username}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Icon(Icons.music_note_rounded, size: 14, color: Color(0xFFFF9800)),
                    SizedBox(width: 6),
                    Text('Original Sound - kuanyngne Studio', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  ],
                ),
                const SizedBox(height: 10),
                if (_isInitialized)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFFFF9800),
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class StateBuilder extends StatefulWidget {
  final StatefulWidgetBuilder builder;

  const StateBuilder({super.key, required this.builder});

  @override
  State<StateBuilder> createState() => _StateBuilderState();
}

class _StateBuilderState extends State<StateBuilder> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, setState);
  }
}

// -------------------------------------------------------------
// 2. UPLOAD STUDIO SCREEN
// -------------------------------------------------------------
class UploadStudioScreen extends StatefulWidget {
  const UploadStudioScreen({super.key});

  @override
  State<UploadStudioScreen> createState() => _UploadStudioScreenState();
}

class _UploadStudioScreenState extends State<UploadStudioScreen> {
  File? _videoFile;
  int _videoDuration = 0;
  bool _isUploading = false;
  final _titleController = TextEditingController();
  final _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final tempController = VideoPlayerController.file(File(picked.path));
      await tempController.initialize();
      final durationInSeconds = tempController.value.duration.inSeconds;
      tempController.dispose();

      if (durationInSeconds > 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video length must not exceed 5 minutes (300 seconds)!')),
          );
        }
        return;
      }

      setState(() {
        _videoFile = File(picked.path);
        _videoDuration = durationInSeconds;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video first!')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a video title!')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final bytes = await _videoFile!.readAsBytes();

      await supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'video/mp4'),
          );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase.from('videos').insert({
        'title': _titleController.text.trim(),
        'video_url': publicUrl,
        'username': 'kuanyngne',
        'duration': _videoDuration,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );
        setState(() {
          _videoFile = null;
          _titleController.clear();
          _videoDuration = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Studio Content'),
        backgroundColor: const Color(0xFF161B26),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
                ),
                child: _videoFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_call_rounded, size: 50, color: Color(0xFFFF9800)),
                          SizedBox(height: 8),
                          Text('Tap here to select video (0 - 5 minutes)', style: TextStyle(color: Colors.white70)),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 50, color: Color(0xFF009688)),
                          const SizedBox(height: 8),
                          Text('Selected video duration: $_videoDuration seconds', style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 4),
                          const Text('Tap again to change video', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Video Title Block',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF161B26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Post Studio Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
