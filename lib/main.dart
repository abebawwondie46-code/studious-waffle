import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yszkonhhprwtavxywchz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlzemtvbmhocHJ3dGF2eHl3Y2h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3NjQxNDksImV4cCI6MjEwNjM0MDE0OX0.TXL0yzOlI3Kx5CyW6CvOsWMMc_wRafTVt7CcTxYev7E',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KuanYngne Ads',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const FeedScreen(),
    const AdEditorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Create Ad',
          ),
        ],
      ),
    );
  }
}

// ==================== 1. FEED SCREEN ====================
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAds();
  }

  Future<void> _fetchAds() async {
    try {
      final response = await supabase.from('videos').select().order('created_at', ascending: false);
      setState(() {
        _ads = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );
    }

    if (_ads.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('KuanYngne Ads', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          centerTitle: true,
        ),
        body: const Center(
          child: Text('ምንም ማስታወቂያዎች የሉም።', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return AdVideoItem(
            title: ad['title'] ?? '',
            videoUrl: ad['video_url'] ?? '',
            templateJson: ad['template_json'] ?? {},
          );
        },
      ),
    );
  }
}

class AdVideoItem extends StatefulWidget {
  final String title;
  final String videoUrl;
  final Map<String, dynamic> templateJson;

  const AdVideoItem({
    super.key,
    required this.title,
    required this.videoUrl,
    required this.templateJson,
  });

  @override
  State<AdVideoItem> createState() => _AdVideoItemState();
}

class _AdVideoItemState extends State<AdVideoItem> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool isVideoInitialized = false;
  late AnimationController _discAnimController;

  // Like & Count variables
  bool _isLiked = false;
  int _likeCount = 44000;
  final int commentCount = 745;
  final int shareCount = 1809;

  @override
  void initState() {
    super.initState();
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    if (widget.videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          setState(() {
            isVideoInitialized = true;
          });
          _videoController?.play();
          _videoController?.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _discAnimController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });
  }

  void _openCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('አስተያየቶች (Comments)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.redAccent, child: Text('አ')),
                      title: Text('በቀለ'),
                      subtitle: Text('በጣም አሪፍ ማስታወቂያ ነው! ቀጥበት።'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareAd(String title, String text) {
    Share.share('ይህን አስደናቂ ማስታወቂያ ይመልከቱ፦ $title - $text');
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.templateJson['text'] ?? '';
    final phone = widget.templateJson['phone'] ?? '';
    final sticker = widget.templateJson['sticker'] ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Video or Template Color
        if (_videoController != null && isVideoInitialized)
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(widget.templateJson['colorStart'] ?? Colors.indigo.value),
                  Color(widget.templateJson['colorEnd'] ?? Colors.blueAccent.value),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),

        // Play/Pause Icon overlay if paused
        if (_videoController != null && isVideoInitialized && !_videoController!.value.isPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, size: 50, color: Colors.white),
            ),
          ),

        // Bottom Info (Title, Text, Phone & Telebirr Badge)
        Positioned(
          bottom: 60,
          left: 16,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sticker.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sticker,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final Uri launchUri = Uri(scheme: 'tel', path: phone);
                    await launchUrl(launchUri);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(phone, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Right side Action Buttons (Like, Comment, Share, Vinyl)
        Positioned(
          right: 12,
          bottom: 70,
          child: Column(
            children: [
              // Profile avatar icon
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              // Like Button (Updated with State)
              GestureDetector(
                onTap: _toggleLike,
                child: Column(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.redAccent : Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCount(_likeCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Comment Button
              GestureDetector(
                onTap: _openCommentsBottomSheet,
                child: Column(
                  children: [
                    const Icon(
                      Icons.comment,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCount(commentCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Share Button
              GestureDetector(
                onTap: () => _shareAd(widget.title, text),
                child: Column(
                  children: [
                    const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCount(shareCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Spinning Vinyl Disc Animation
              RotationTransition(
                turns: _discAnimController,
                child: Container(
                  width: 45,
                  height: 45,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.music_note, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Video Progress Bar at the bottom (Raised slightly to avoid overlapping with phone's bottom bar)
        if (_videoController != null && isVideoInitialized)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_videoController!.value.position),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDuration(_videoController!.value.duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.redAccent,
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ==================== 2. AD EDITOR SCREEN ====================
class AdEditorScreen extends StatefulWidget {
  const AdEditorScreen({super.key});

  @override
  State<AdEditorScreen> createState() => _AdEditorScreenState();
}

class _AdEditorScreenState extends State<AdEditorScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stickerController = TextEditingController(text: '🔥🔥 ልዩ ቅናሽ!');

  Color _startColor = Colors.indigo;
  Color _endColor = Colors.blueAccent;
  File? _selectedVideo;
  bool _isUploading = false;

  final List<Color> _colorPalette = [
    Colors.indigo,
    Colors.blueAccent,
    Colors.purple,
    Colors.deepOrange,
    Colors.teal,
    Colors.pink,
    Colors.black,
    Colors.amber,
  ];

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
      });
    }
  }

  Future<void> _saveAd() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎን የማስታወቂያ ርዕስ ያስገቡ!')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      String videoUrl = '';

      if (_selectedVideo != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
        await supabase.storage
            .from('videos')
            .upload(fileName, _selectedVideo!);

        videoUrl = supabase.storage.from('videos').getPublicUrl(fileName);
      }

      final templateJson = {
        'colorStart': _startColor.value,
        'colorEnd': _endColor.value,
        'phone': _phoneController.text.trim(),
        'text': _textController.text.trim(),
        'sticker': _stickerController.text.trim(),
      };

      await supabase.from('videos').insert({
        'title': _titleController.text.trim(),
        'video_url': videoUrl,
        'template_json': templateJson,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ማስታወቂያው በትክክል ተለጥፏል!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _textController.clear();
        _phoneController.clear();
        setState(() {
          _selectedVideo = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ስህተት ተከሰቷል፡ $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('አዲስ ማስታወቂያ ፍጠር'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C24),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24),
                ),
                child: _selectedVideo != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'ቪዲዮ ተመርጧል፡ ${_selectedVideo!.path.split('/').last}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: _pickVideo,
                            child: const Text('ቅየሩ'),
                          )
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_call, color: Colors.redAccent, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'ቪዲዮ ለመምረጥ እዚህ ይጫኑ (ባዶ መተው ይቻላል)',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'የማስታወቂያው ርዕስ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1C1C24),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'ዝርዝር ማብራሪያ / መልዕክት',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1C1C24),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'የስልክ ቁጥር',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1C1C24),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stickerController,
              decoration: InputDecoration(
                labelText: 'ስቲከር / ባጅ (ምሳሌ፡ 🔥 ልዩ ቅናሽ!)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1C1C24),
              ),
            ),
            const SizedBox(height: 20),
            const Text('የጀርባ ቀለም ይምረጡ (ቪዲዮ ካልተመረጠ)፡', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorPalette.length,
                itemBuilder: (context, index) {
                  final color = _colorPalette[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _startColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _startColor == color ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUploading ? null : _saveAd,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ማስታወቂያውን ለጥፍ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
