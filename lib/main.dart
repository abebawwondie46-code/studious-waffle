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
        scaffoldBackgroundColor: const Color(0xFF10141D),
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
        backgroundColor: const Color(0xFF161B26),
        selectedItemColor: const Color(0xFFFF9800),
        unselectedItemColor: Colors.white54,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill),
            label: '5-Min Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Upload Studio',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. FULLSCREEN VIDEO FEED SCREEN
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('kuanyngne: 5-Min Studio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _supabase.from('videos').select().order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('ስህተት ተፈጥሯል፦ ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('ምንም ቪዲዮ አልተገኘም። አዲስ ቪዲዮ ይልቀቁ!', style: TextStyle(color: Colors.white54)),
            );
          }

          final videos = snapshot.data!;
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return ModernVideoPlayerCard(
                title: video['title'] ?? 'Untitled',
                username: video['username'] ?? 'User',
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
// MODERN FULL-COVER VIDEO CARD WITH OVERLAY CONTROLS
// -------------------------------------------------------------
class ModernVideoPlayerCard extends StatefulWidget {
  final String title;
  final String username;
  final String videoUrl;
  final int duration;

  const ModernVideoPlayerCard({
    super.key,
    required this.title,
    required this.username,
    required this.videoUrl,
    required this.duration,
  });

  @override
  State<ModernVideoPlayerCard> createState() => _ModernVideoPlayerCardState();
}

class _ModernVideoPlayerCardState extends State<ModernVideoPlayerCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  int _currentPositionInSeconds = 0;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
          _controller.setLooping(true);
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
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5C6BC0), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // 1. FULL COVER VIDEO AREA
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
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

            // Play/Pause Overlay Icon
            if (_isInitialized && !_controller.value.isPlaying)
              Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.play_arrow_rounded, size: 60, color: Colors.white),
                ),
              ),

            // 2. TOP OVERLAY HEADER
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFF5C6BC0),
                          child: Icon(Icons.person, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "@${widget.username}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Text(
                        "${_currentPositionInSeconds}s / ${widget.duration > 0 ? widget.duration : 300}s",
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. BOTTOM OVERLAY INFO & ACTIONS
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(height: 10),

                    // Bottom Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGlassActionButton(
                          icon: _isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                          label: "Like",
                          color: _isLiked ? const Color(0xFF009688) : Colors.white,
                          onTap: () => setState(() => _isLiked = !_isLiked),
                        ),
                        _buildGlassActionButton(
                          icon: Icons.comment_outlined,
                          label: "Comment",
                          color: const Color(0xFFFF9800),
                          onTap: () {},
                        ),
                        _buildGlassActionButton(
                          icon: Icons.share_outlined,
                          label: "Share",
                          color: const Color(0xFFE91E63),
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Video Seek Bar
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
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
            const SnackBar(content: Text('የቪዲዮው ርዝመት ከ 5 ደቂቃ (300 ሰከንድ) መብለጥ የለበትም!')),
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
        const SnackBar(content: Text('እባክዎን መጀመሪያ ቪዲዮ ይምረጡ!')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎን የቪዲዮውን ርዕስ ይጻፉ!')),
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
          const SnackBar(content: Text('ቪዲዮው በስኬት ተጭኗል!')),
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
          SnackBar(content: Text('ስህተት ተፈጥሯል፦ $e'), backgroundColor: Colors.red),
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
        title: const Text('Add Logic Block (Upload)'),
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
                          Text('ቪዲዮ ለመምረጥ እዚህ ይጫኑ (ከ0 - 5 ደቂቃ)', style: TextStyle(color: Colors.white70)),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 50, color: Color(0xFF009688)),
                          const SizedBox(height: 8),
                          Text('የተመረጠው ቪዲዮ ርዝመት፦ $_videoDuration ሰከንድ', style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 4),
                          const Text('ቪዲዮውን ለመቀየር መልሰው ይጫኑ', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'የቪዲዮው ርዕስ (Title Block)',
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
                  : const Text('Post 5-Min Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
