import 'dart0:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Initialization
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
        scaffoldBackgroundColor: const Color(0xFF1B1F2A), // Sketchware Slate Grey
        primaryColor: const Color(0xFF5C6BC0), // Sketchware Indigo Header
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
        backgroundColor: const Color(0xFF1B1F2A),
        selectedItemColor: const Color(0xFFFF9800), // Sketchware Orange
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: '5-Min Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Upload Studio',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. VIDEO FEED SCREEN
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
        backgroundColor: const Color(0xFF263238),
        title: const Text('kuanyngne: 5-Min Studio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              return SketchwareBlockCard(
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
// SKETCHWARE BLOCK CARD WIDGET
// -------------------------------------------------------------
class SketchwareBlockCard extends StatefulWidget {
  final String title;
  final String username;
  final String videoUrl;
  final int duration;

  const SketchwareBlockCard({
    super.key,
    required this.title,
    required this.username,
    required this.videoUrl,
    required this.duration,
  });

  @override
  State<SketchwareBlockCard> createState() => _SketchwareBlockCardState();
}

class _SketchwareBlockCardState extends State<SketchwareBlockCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5C6BC0), width: 2), // Sketchware Block Border
      ),
      child: Column(
        children: [
          // Block Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF5C6BC0),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Logic: @${widget.username}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("${widget.duration}s / 300s", style: const TextStyle(fontSize: 11, color: Colors.white)),
                )
              ],
            ),
          ),

          // Video Canvas Area
          Expanded(
            child: Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Color(0xFFFF9800)),
            ),
          ),

          // Block Description & Action Buttons
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1B1F2A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBlockButton(Icons.thumb_up_alt_outlined, "Like", const Color(0xFF009688)),
                    _buildBlockButton(Icons.comment_outlined, "Comment", const Color(0xFFFF9800)),
                    _buildBlockButton(Icons.share_outlined, "Share", const Color(0xFFE91E63)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockButton(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
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

      // የ 5 ደቂቃ (300 ሰከንድ) ማረጋገጫ
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

      // 1. Read Bytes for Reliable Mobile Upload
      final bytes = await _videoFile!.readAsBytes();

      // 2. Upload Video to Supabase Storage Bucket 'avatars'
      await supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'video/mp4'),
          );

      // 3. Get Public URL from 'avatars' Bucket
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // 4. Insert Record to Database Table 'videos'
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
        backgroundColor: const Color(0xFF263238),
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
                  color: const Color(0xFF263238),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF9800), width: 2),
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
                fillColor: const Color(0xFF263238),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
